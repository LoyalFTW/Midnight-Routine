local _, ns = ...
local MR = ns.MR

local function ResolveCallback(owner, callback)
    if type(callback) == "function" then
        return callback, false
    end
    if type(callback) == "string" and type(owner[callback]) == "function" then
        return owner[callback], true
    end
    return nil
end

local function CallbackLabel(callback, stackDepth)
    if type(callback) == "string" then
        return callback
    end
    if debugstack then
        local ok, stack = pcall(debugstack, stackDepth or 2, 1, 0)
        if ok and type(stack) == "string" then
            local line = stack:match("[^\n]+")
            if line and line ~= "" then
                return line:gsub("^%s+", "")
            end
        end
    end
    return "anonymous"
end

local function StartAuditTiming(owner)
    return owner._memoryAuditTrace and debugprofilestop and debugprofilestop() or nil
end

local function FinishAuditTiming(owner, label, started)
    if started and owner.NoteIdleWorkTime then
        owner:NoteIdleWorkTime(label, math.max(0, debugprofilestop() - started))
    end
end

function MR:RegisterEvent(event, callback)
    local fn, bindSelf = ResolveCallback(self, callback or event)
    if not fn then
        error(("MidnightRoutine:RegisterEvent(%s) missing callback"):format(tostring(event)), 2)
    end

    self._eventHandlers = self._eventHandlers or {}

    local handlers = self._eventHandlers[event]
    if handlers then
        handlers[#handlers + 1] = { fn = fn, bindSelf = bindSelf }
        return
    end

    handlers = { { fn = fn, bindSelf = bindSelf } }
    self._eventHandlers[event] = handlers

    self._eventController:Register(event, function(firedEvent, ...)
        local label = "event:" .. tostring(firedEvent)
        if self._trackIdleWork and self.NoteIdleWork then
            self:NoteIdleWork(label)
        end
        local started = StartAuditTiming(self)
        for i = 1, #handlers do
            local entry = handlers[i]
            if entry.bindSelf then
                xpcall(entry.fn, CallErrorHandler, self, firedEvent, ...)
            else
                xpcall(entry.fn, CallErrorHandler, firedEvent, ...)
            end
        end
        FinishAuditTiming(self, label, started)
    end)
end

function MR:UnregisterEvent(event)
    if self._eventHandlers then
        self._eventHandlers[event] = nil
    end
    self._eventController:Unregister(event)
end

function MR:UnregisterAllEvents()
    self._eventHandlers = nil
    self._eventController:UnregisterAll()
end

function MR:RegisterBucketEvent(events, interval, callback)
    local fn, bindSelf = ResolveCallback(self, callback)
    if not fn then
        error("MidnightRoutine:RegisterBucketEvent missing callback", 2)
    end

    local callbackLabel = CallbackLabel(callback, 4)
    local bucket = self._eventController:RegisterBucket({
        events = events,
        interval = interval,
        handler = function()
            local label = "bucket:" .. callbackLabel
            if self._trackIdleWork and self.NoteIdleWork then
                self:NoteIdleWork(label)
            end
            local started = StartAuditTiming(self)
            if bindSelf then
                fn(self)
            else
                fn()
            end
            FinishAuditTiming(self, label, started)
        end,
    })

    if not bucket then
        return nil
    end
    self._buckets[bucket] = true
    return bucket
end

function MR:UnregisterBucket(bucket)
    if bucket and bucket.Cancel then
        bucket:Cancel()
        self._buckets[bucket] = nil
    end
end

local function InvokeTimerCallback(owner, fn, bindSelf, args, argc)
    if bindSelf and args then
        fn(owner, unpack(args, 1, argc))
    elseif bindSelf then
        fn(owner)
    elseif args then
        fn(unpack(args, 1, argc))
    else
        fn()
    end
end

local function PrepareTimerCallback(owner, callback, ...)
    local fn, bindSelf = ResolveCallback(owner, callback)
    if not fn then
        return nil
    end

    local argc = select("#", ...)
    local args = argc > 0 and { ... } or nil
    return function()
        InvokeTimerCallback(owner, fn, bindSelf, args, argc)
    end
end

function MR:ScheduleTimer(callback, delay, ...)
    local invoke = PrepareTimerCallback(self, callback, ...)
    if not invoke then
        error("MidnightRoutine:ScheduleTimer missing callback", 2)
    end

    local callbackLabel = CallbackLabel(callback, 4)
    local timer
    timer = C_Timer.NewTimer(delay, function()
        self._timers[timer] = nil
        local label = "timer:" .. callbackLabel
        if self._trackIdleWork and self.NoteIdleWork then
            self:NoteIdleWork(label)
        end
        local started = StartAuditTiming(self)
        invoke()
        FinishAuditTiming(self, label, started)
    end)
    self._timers[timer] = true
    return timer
end

function MR:ScheduleRepeatingTimer(callback, delay, ...)
    local invoke = PrepareTimerCallback(self, callback, ...)
    if not invoke then
        error("MidnightRoutine:ScheduleRepeatingTimer missing callback", 2)
    end

    local label = "ticker:" .. CallbackLabel(callback, 4)
    local timer = C_Timer.NewTicker(delay, function()
        if self._trackIdleWork and self.NoteIdleWork then
            self:NoteIdleWork(label)
        end
        local started = StartAuditTiming(self)
        invoke()
        FinishAuditTiming(self, label, started)
    end)
    self._timers[timer] = true
    return timer
end

function MR:CancelTimer(timer)
    if timer and timer.Cancel then
        timer:Cancel()
        self._timers[timer] = nil
    end
end

function MR:CancelAllTimers()
    for timer in pairs(self._timers) do
        if timer.Cancel then
            timer:Cancel()
        end
        self._timers[timer] = nil
    end
end
