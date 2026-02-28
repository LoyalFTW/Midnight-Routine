local PREY_COLOR = "|cffcc2244"

MR:RegisterModule({
    key         = "prey",
    label       = "Prey System",
    labelColor  = "#cc2244",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key      = "prey_weekly_bounty",
            label    = PREY_COLOR .. "Weekly Prey:|r",
            max      = 4,
            note     = "Complete 4 Prey targets for the weekly cache",
            questIds = {
                91095, 91096, 91097, 91098, 91099, 91100, 91101, 91102, 91103, 91104,
                91105, 91106, 91107, 91108, 91109, 91110, 91111, 91112, 91113, 91114,
                91115, 91116, 91117, 91118, 91119, 91120, 91121, 91122, 91123, 91124,
            },
        },
        {
            key        = "prey_remnants",
            label      = PREY_COLOR .. "Remnants of Anguish:|r",
            currencyId = 3392,
            max        = 99999,
            noMax      = true,
            note       = "Current Remnants of Anguish",
        },
    },
})
