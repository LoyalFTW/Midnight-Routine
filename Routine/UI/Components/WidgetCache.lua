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

function ns.StartWidgetPool(root)
    local pool = root._mrPool
    if not pool then
        pool = { buckets = {} }
        root._mrPool = pool
    end
    pool.pass = (pool.pass or 0) + 1
    return pool
end

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

function ns.AcquireWidget(parent, siteKey, create)
    local bucket, pool = Reserve(parent, siteKey)
    if not bucket then return create(), true end
    local widget = bucket[bucket.used]
    if widget then return Recycle(widget), false end
    return Store(bucket, pool, create()), true
end

function ns.SetOneAnchor(region, point, relativeTo, relativePoint, x, y)
    if region._mrPoint1 == point
        and region._mrRelative1 == relativeTo
        and region._mrRelativePoint1 == relativePoint
        and region._mrX1 == x
        and region._mrY1 == y
        and region._mrPoint2 == nil then
        return
    end

    region:ClearAllPoints()
    region:SetPoint(point, relativeTo, relativePoint, x, y)
    region._mrPoint1 = point
    region._mrRelative1 = relativeTo
    region._mrRelativePoint1 = relativePoint
    region._mrX1 = x
    region._mrY1 = y
    region._mrPoint2 = nil
    region._mrRelative2 = nil
end

function ns.SetTwoAnchors(region, point1, relative1, relativePoint1, x1, y1, point2, relative2, relativePoint2, x2, y2)
    if region._mrPoint1 == point1
        and region._mrRelative1 == relative1
        and region._mrRelativePoint1 == relativePoint1
        and region._mrX1 == x1
        and region._mrY1 == y1
        and region._mrPoint2 == point2
        and region._mrRelative2 == relative2
        and region._mrRelativePoint2 == relativePoint2
        and region._mrX2 == x2
        and region._mrY2 == y2 then
        return
    end

    region:ClearAllPoints()
    region:SetPoint(point1, relative1, relativePoint1, x1, y1)
    region:SetPoint(point2, relative2, relativePoint2, x2, y2)
    region._mrPoint1 = point1
    region._mrRelative1 = relative1
    region._mrRelativePoint1 = relativePoint1
    region._mrX1 = x1
    region._mrY1 = y1
    region._mrPoint2 = point2
    region._mrRelative2 = relative2
    region._mrRelativePoint2 = relativePoint2
    region._mrX2 = x2
    region._mrY2 = y2
end
