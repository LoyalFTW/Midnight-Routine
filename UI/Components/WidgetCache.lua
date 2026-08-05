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
