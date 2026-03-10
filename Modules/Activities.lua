local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

MR:RegisterModule({
    key         = "midnight_activities",
    label       = L["Activities_Title"],
    labelColor  = "#ff9040",
    resetType   = "weekly",
    defaultOpen = true,

    rows = {
        {
            key           = "stormarion_assault",
            label         = L["Act_Stormarion_Label"],
            max           = 1,
            note          = L["Act_Stormarion_Note"],
            questIds      = { 90962 }, 
            timerEpoch    = 1772370083,
            timerInterval = 1800,
            timerDuration = 900,
        },
    },
})
