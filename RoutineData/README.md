# Routine Data

Routine Data keeps track of your characters and shows who owns what. Install it on its own to get:

- **Item tooltips** listing which of your characters hold an item, in their bags, bank, the warband bank or a guild bank.
- **Currency tooltips** with each character's balance and weekly progress.
- **Rare tooltips** showing whether your characters have killed a rare, read from the quest each rare completes. Routine shows this itself when it is loaded.
- **Gold tracking** with a minimap button and a Data Broker display.

It is also the data layer for Routine, which requires it. Other addon authors can read the same data through a small public API (see below).

Routine Data hides its own item tooltip lines when Syndicator, Baganator or a similar addon is loaded, so nothing is shown twice.

## Installing

Install Routine Data from the same place you installed Routine. If you install addons by hand (a zip file), you must install **both** Routine and Routine Data. Routine will not load without Routine Data, and the game will say so on the character select screen.

## Slash commands

| Command | What it does |
| --- | --- |
| `/rdata options` | Open the settings panel |
| `/rdata chars` | List tracked characters |
| `/rdata item <link or id>` | Show who owns an item |
| `/rdata forget <Name - Realm>` | Remove one character's stored data |
| `/rdata toggle <tooltip, bags, bank, warband, guild, currency, rares, yield, minimap>` | Turn a feature on or off |

## For addon authors

Everything lives under `RoutineData.API`. Add `## OptionalDeps: RoutineData` (or `## Dependencies: RoutineData`) to your `.toc`.

Character keys use the form `"Name - Realm"` (for example `"Jay - Tichondrius"`).

### Availability

Item, currency and gold data are captured by Routine Data itself and are available as soon as you are logged in. Progress, professions, rare kills, resets and bank layout data are produced by Routine's tracking, so those calls return empty values (`0`, `nil` or `{}`) until Routine has loaded. Check `RoutineData.API.IsReady()` if you need to know. Routine Data does not scan or update progress without Routine.

Treat every table returned by the API as read-only.

### Items, currencies and gold

```lua
local API = RoutineData.API

API.GetVersion()                    -- API version number
API.GetCurrentCharacterKey()        -- "Name - Realm"
API.GetCharacters()                 -- sorted list of character keys
API.GetCharacterClass(charKey)      -- class file name, e.g. "DRUID"

API.GetItemCounts(itemID)
-- { characters = { { key, classFile, bags, bank }, ... },
--   warband = <number>,
--   guilds = { { key, name, realm, count }, ... } }
API.GetTotalItemCount(itemID)       -- everything above, summed

API.GetCurrencyCounts(currencyID)   -- { { key, classFile, quantity, weekly, maxWeekly }, ... }
API.GetGold(charKey)                -- copper
API.GetTotalGold()                  -- copper, all characters
```

### Tracking data (requires Routine)

```lua
API.IsReady()                                   -- true once Routine has registered itself
API.GetCharacterInfo(charKey)                   -- { key, name, realm, classFile, gold, mythicPlusScore, lastSyncAt } or nil
API.GetProgress(charKey, moduleKey, rowKey)     -- number, 0 for unknown characters or rows
API.GetManualOverride(charKey, moduleKey, rowKey)
API.GetProfessions(charKey)                     -- table or nil
API.GetConcentration(charKey)                   -- table or nil
API.GetRareKills(charKey)                       -- table or nil
API.GetWarbandGold()                            -- copper
API.GetLastReset("daily" or "weekly")           -- timestamp of the current reset window
API.GetCurrentWeekKey()                         -- changes every weekly reset
API.GetBankSnapshots()                          -- detailed bag, bank and guild bank tabs (item links, icons)
```

Module and row keys are the ones Routine uses, for example `"great_vault"` and `"vault_dungeon"`.

### Callbacks

```lua
local listener = {}

RoutineData.API.RegisterCallback(listener, "WeeklyReset", function(event)
    -- weekly progress was reset
end)

RoutineData.API.RegisterCallback(listener, "ItemsUpdated", function(event, charKey, source)
    -- source is "bags", "bank", "warband" or "guild"
end)

RoutineData.API.UnregisterCallback(listener, "WeeklyReset")
```

`owner` must be your own table, and each owner can register an event once.

| Event | Arguments | When |
| --- | --- | --- |
| `DataReady` | | Login finished and the database is ready |
| `ItemsUpdated` | `charKey, source` | A character's bags, bank or guild bank snapshot changed; `charKey` is `nil` for the warband bank |
| `GoldUpdated` | `charKey` | A character's gold changed |
| `CurrenciesUpdated` | `charKey[, currencyID]` | Currency balances changed |
| `CharacterRemoved` | `charKey` | A character's data was removed |
| `DailyReset` | | Daily reset was applied (requires Routine) |
| `WeeklyReset` | | Weekly reset was applied (requires Routine) |
| `DataChanged` | | Tracked progress changed (requires Routine) |
| `TrackingFailure` | `source, err` | A tracking step failed and was skipped (requires Routine) |

### Versioning

`API.GetVersion()` is bumped for any breaking change to the calls above. Additions do not change it.

## Where the data is stored

Item and gold data is saved in `RoutineDataDB`. Tracking progress is still saved in Routine's `MidnightRoutineDB`. Removing a character with `/rdata forget` clears its item, gold and bank data from Routine Data.
