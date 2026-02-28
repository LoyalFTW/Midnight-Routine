MR:RegisterModule({
    key         = "coffer_key_shards",
    label       = "Coffer Key Shards",
    labelColor  = "#e8c96e",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key        = "shards",
            label      = "|cffe8c96eCoffer Key Shards:|r",
            currencyId = 3310,
            max        = 600,
            note       = "Earned from Delves & Zekvir encounters\nCap: 600 — used to craft Restored Coffer Keys",
        },
    },
})
