# RoutineData for addon authors

RoutineData collects character gold, items, currencies, and bank snapshots when installed on its own. Integrate through `_G.RoutineData.API`. Treat character keys as opaque strings from the API. Keep them for lookups and use `GetCharacterInfo` for display names.

## Load RoutineData

Use `## OptionalDeps: RoutineData` in your addon's TOC if your addon can run without it. Use `## Dependencies: RoutineData` if your addon requires it. A TOC dependency gives RoutineData load order priority when it is installed and enabled.

Call API functions with a dot. `IsDataReady()` becomes true after login initialization, including any import. Capture can continue after this point. A missing capture means that RoutineData has no saved observation for that character or location yet. For compatibility with earlier releases, check whether a newly added function exists before calling it.

```lua
local addonName, ns = ...
local api = _G.RoutineData and _G.RoutineData.API
if not api then return end

local function Refresh()
    ns.itemCounts = api.GetItemCounts(6948)
end

api.RegisterCallback(addonName, "ItemsUpdated", function()
    Refresh()
end)
api.RegisterCallback(addonName, "CharacterRemoved", function()
    Refresh()
end)

if not api.IsDataReady or not api.IsDataReady() then
    api.RegisterCallback(addonName, "DataReady", function()
        api.UnregisterCallback(addonName, "DataReady")
        Refresh()
    end)
end
if not api.IsDataReady or api.IsDataReady() then
    Refresh()
end
```

The initial read also supports older RoutineData releases if your addon loads after login. On current releases, `IsDataReady()` and `DataReady` let you handle both load orders directly.

## Standalone queries

| Function | Result |
| --- | --- |
| `GetCharacters()` | Sorted list of saved character keys. |
| `GetCurrentCharacterKey()` | Current character key or nil while the identity is unavailable. |
| `GetCharacterInfo(key)` | A snapshot with key, name, realm, classFile, gold, lastSyncAt, and updatedAt, or nil for an unknown key. The realm can be empty. The updatedAt table contains server timestamps by captured source, such as bags, bank, mail, equipped, gold, or currencies. Missing fields represent unavailable timestamps. |
| `GetGold(key)`, `GetGoldRanking()`, `GetTotalGold()` | Copper values. The ranking returns rows with key, classFile, and gold in descending gold order. The total sums gold saved in RoutineData's character store. |
| `GetItemCounts(itemID)` | A table with characters, warband, and guilds. Character rows contain key, classFile, bags, bank, mail, and equipped. Warband is a count. Guild rows contain key, name, realm, and count. |
| `GetTotalItemCount(itemID)` | Combined item count across saved character, Warband, and guild storage. |
| `GetCurrencyCounts(currencyID)` | Rows with key, classFile, quantity, weekly, and maxWeekly. Weekly earned amounts from before the current weekly reset are returned as zero. |
| `GetBankSnapshots()` | A copy of the saved detail. Fields include characters (personal banks), bags, mail, warband, characterGuilds, and characterGuildBanks. Each captured storage snapshot can include tabs and updatedAt. The function returns nil before the saved store is available. |
| `SearchInventory(query)` | Searches saved bags, character banks, Warband bank, and guild bank tabs by case-insensitive item name substring, exact item ID, or item link. Returns one row per item and storage tab with `itemID`, `name`, `link`, `icon`, `quantity`, `source` (`bags`, `character`, `warband`, or `guild`), `characterKey`, `guildKey`, `guildName`, `tabIndex`, `tabName`, `slot` (first matching slot), and `updatedAt` where available. Shared guild tabs use the most recently captured tab. Empty or unavailable searches return an empty list. |

Saved quantities reflect the last time a source was captured. Visiting a character's bank or mailbox can fill in missing data for that source.

## Rares

`GetRareCatalog()` returns a list of bundled rare entries for the client. It is available as soon as RoutineData loads. Each entry has a `name` and a `locations` list. Each location contains a `mapID` and may include `x` and `y` on a 0–100 scale. An empty list means the location is unknown. `npcID` is included where known. Multiple entries can share an NPC ID.

On Retail, entries also have a `catalog` label and may include `questID`, `questIDs`, `questAny`, `achievementID`, `criteriaID`, `faction`, `patch`, `eventName`, and `spawnNote`. The bundled list includes faction-specific entries and entries gated by a patch. On Forever, an entry can have several locations across maps.

`GetRareKillSnapshot(key)` returns a copy of the standalone capture, with `kills` mapping NPC IDs to server timestamps and `updatedAt` giving the latest rare capture timestamp when available. It returns nil when no rare data has been saved for the character. A missing NPC ID means the snapshot has no saved kill observation for that NPC. Retail observations come from completion flags and their timestamps indicate when RoutineData observed them. Forever observations come from deaths seen by RoutineData. Use `RaresUpdated` to refresh after a capture.

## Callbacks

Register with `api.RegisterCallback(owner, event, handler)`. A function handler receives the event name followed by the arguments below. You can also pass a method name with a table owner. That method receives the owner first. Each owner has one handler per event. Use `api.UnregisterCallback(owner, event)` to remove one or `api.UnregisterAllCallbacks(owner)` to remove all registrations for that owner.

| Event | Arguments after event name |
| --- | --- |
| `DataReady` | None. Login initialization has finished. |
| `ItemsUpdated` | characterKey, source. Sources are bags, bank, mail, equipped, warband, and guild. The character key is nil for warband. |
| `GoldUpdated` | characterKey. |
| `CurrenciesUpdated` | characterKey, currencyID. A nil currencyID signals a full capture. |
| `RaresUpdated` | characterKey, npcID. A nil npcID signals a full capture. |
| `CharacterRemoved` | characterKey. |

## Routine tracking

`IsReady()` reports whether the Routine tracking engine is attached and has a database. Use that check for `GetProgress`, `GetManualOverride`, `GetProfessions`, `GetConcentration`, `GetRareKills`, `GetWarbandGold`, `GetLastReset`, and `GetCurrentWeekKey`. Progress and overrides use Routine's module and row keys. Engine-backed getters can return nil or zero when data is unavailable. The engine can also contribute characters and character metadata to the standalone queries above.

The engine forwards `DataChanged` as a refresh signal, `DailyReset` and `WeeklyReset` when it applies resets, and `TrackingFailure` with source and error arguments. Use the standalone callbacks for changes to standalone captures.

