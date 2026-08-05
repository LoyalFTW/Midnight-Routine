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

local function CallbackLabel(callback)
    if type(callback) == "string" then
        return callback
    end
    return "anonymous"
end

function MR:RegisterEvent(event, callback)
    local fn, bindSelf = ResolveCallback(self, callback or event)
    if not fn then
        error(("MidnightRoutine:RegisterEvent(%s) missing callback"):format(tostring(event)), 2)
    end

    if self._eventController:IsRegistered(event) then
        self._eventController:Unregister(event)
    end

    self._eventController:Register(event, function(firedEvent, ...)
        if self._trackIdleWork and self.NoteIdleWork then
            self:NoteIdleWork("event:" .. tostring(firedEvent))
        end
        if bindSelf then
            fn(self, firedEvent, ...)
        else
            fn(firedEvent, ...)
        end
    end)
end

function MR:UnregisterEvent(event)
    self._eventController:Unregister(event)
end

function MR:UnregisterAllEvents()
    self._eventController:UnregisterAll()
end

function MR:RegisterBucketEvent(events, interval, callback)
    local fn, bindSelf = ResolveCallback(self, callback)
    if not fn then
        error("MidnightRoutine:RegisterBucketEvent missing callback", 2)
    end

    local bucket = self._eventController:RegisterBucket({
        events = events,
        interval = interval,
        handler = function()
            if self._trackIdleWork and self.NoteIdleWork then
                self:NoteIdleWork("bucket:" .. CallbackLabel(callback))
            end
            if bindSelf then
                fn(self)
            else
                fn()
            end
        end,
    })

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

    local timer
    timer = C_Timer.NewTimer(delay, function()
        self._timers[timer] = nil
        if self._trackIdleWork and self.NoteIdleWork then
            self:NoteIdleWork("timer:" .. CallbackLabel(callback))
        end
        invoke()
    end)
    self._timers[timer] = true
    return timer
end

function MR:ScheduleRepeatingTimer(callback, delay, ...)
    local invoke = PrepareTimerCallback(self, callback, ...)
    if not invoke then
        error("MidnightRoutine:ScheduleRepeatingTimer missing callback", 2)
    end

    local timer = C_Timer.NewTicker(delay, function()
        if self._trackIdleWork and self.NoteIdleWork then
            self:NoteIdleWork("ticker:" .. CallbackLabel(callback))
        end
        invoke()
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
