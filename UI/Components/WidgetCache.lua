local _, ns = ...

function ns.GetWidgetCache(owner, key)
    local cache = owner and owner[key]
    if cache then
        return cache
    end

    cache = {}
    owner[key] = cache
    return cache
end

function ns.HideUnusedWidgets(cache, usedCount, resetWidget)
    for index = (usedCount or 0) + 1, #(cache or {}) do
        local widget = cache[index]
        if resetWidget then
            resetWidget(widget)
        end
        widget:Hide()
    end
end

function ns.ResetCachedWidget(widget)
    widget._entry = nil
end

function ns.ResetSelectableWidget(widget)
    widget._entry = nil
    widget._selected = nil
end

-- Call-site widget pool, for trees that are rebuilt wholesale. Every acquire
-- site keeps its own bucket on its parent, so the Nth widget a site asks for is
-- the same object on every pass and that site's own setup code reconfigures it.
-- Anything acquired under a pooled root inherits the pool; parents outside one
-- are created normally.
function ns.StartWidgetPool(root)
    local pool = root._mrPool
    if not pool then
        pool = { buckets = {} }
        root._mrPool = pool
    end
    pool.pass = (pool.pass or 0) + 1
    return pool
end

-- Hide everything the pass just finished did not ask for, including whole
-- buckets belonging to a page that is no longer on screen.
function ns.FinishWidgetPool(pool)
    for _, bucket in ipairs(pool.buckets) do
        local first = (bucket.pass == pool.pass) and bucket.used + 1 or 1
        for index = first, #bucket do
            bucket[index]:Hide()
        end
    end
end

local function Reserve(parent, siteKey)
    local pool = parent and parent._mrPool
    if not pool then
        return nil
    end

    local buckets = parent._mrBuckets
    if not buckets then
        buckets = {}
        parent._mrBuckets = buckets
    end

    local bucket = buckets[siteKey]
    if not bucket then
        bucket = { pass = pool.pass, used = 0 }
        buckets[siteKey] = bucket
        pool.buckets[#pool.buckets + 1] = bucket
    elseif bucket.pass ~= pool.pass then
        bucket.pass = pool.pass
        bucket.used = 0
    end

    bucket.used = bucket.used + 1
    return bucket, pool
end

local function Recycle(widget)
    widget:ClearAllPoints()
    widget:SetAlpha(1)
    widget:Show()
    return widget
end

local function Store(bucket, pool, widget)
    widget._mrPool = pool
    bucket[bucket.used] = widget
    return widget
end

function ns.AcquireFrame(parent, siteKey, frameType, template)
    local bucket, pool = Reserve(parent, siteKey)
    if not bucket then return CreateFrame(frameType, nil, parent, template) end
    local frame = bucket[bucket.used]
    if frame then return Recycle(frame) end
    return Store(bucket, pool, CreateFrame(frameType, nil, parent, template))
end

function ns.AcquireFontString(parent, siteKey, layer)
    local bucket, pool = Reserve(parent, siteKey)
    if not bucket then return parent:CreateFontString(nil, layer) end
    local fontString = bucket[bucket.used]
    if fontString then return Recycle(fontString) end
    return Store(bucket, pool, parent:CreateFontString(nil, layer))
end

function ns.AcquireTexture(parent, siteKey, layer)
    local bucket, pool = Reserve(parent, siteKey)
    if not bucket then return parent:CreateTexture(nil, layer) end
    local texture = bucket[bucket.used]
    if texture then return Recycle(texture) end
    return Store(bucket, pool, parent:CreateTexture(nil, layer))
end

-- For compound widgets that cannot be rebuilt from parts: returns the pooled
-- widget plus whether this call created it, so the caller can reconfigure one
-- it did not just build.
function ns.AcquireWidget(parent, siteKey, create)
    local bucket, pool = Reserve(parent, siteKey)
    if not bucket then return create(), true end
    local widget = bucket[bucket.used]
    if widget then return Recycle(widget), false end
    return Store(bucket, pool, create()), true
end
