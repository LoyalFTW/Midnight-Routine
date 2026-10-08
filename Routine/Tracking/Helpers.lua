local _, ns = ...
local Helpers = {}
ns.Tracking.Helpers = Helpers

function Helpers.HasAnyProfessionRecord(source)
    if type(source) ~= "table" then
        return false
    end

    for _, learned in pairs(source) do
        if learned then
            return true
        end
    end

    return false
end

function Helpers.ColorsEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    return (a[1] or 0) == (b[1] or 0)
        and (a[2] or 0) == (b[2] or 0)
        and (a[3] or 0) == (b[3] or 0)
        and (a[4] or 0) == (b[4] or 0)
end
