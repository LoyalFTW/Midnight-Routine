# Midnight Routine

## [v12.0.3] (2026-02-27)

### Added
- **Prey System module** (`Modules/Prey.lua`) — tracks the weekly Prey hunting targets and associated quests
  - Weekly Prey Bounty quest detection (via `C_QuestLog.IsQuestFlaggedCompleted`)
  - Four individual Prey target rows (The Hollow King, Vel'thara the Scarlet, Gorefang, The Shrouded Watcher)
  - "Full Hunt (4/4)" row auto-completes when all four targets are done, even before the umbrella quest is turned in
  - Prey Marks currency exchange weekly row with `currencyTracked = true` so it rescans on `CURRENCY_DISPLAY_UPDATE`
- Quest IDs are placeholder `0` — update `PREY_QUESTS` and `PREY_MARKS_CURRENCY_ID` in `Modules/Prey.lua` once live IDs are confirmed

## [v12.0.2](https://github.com/LoyalFTW/Midnight-Routine/tree/v12.0.2) (2026-02-26)
[Full Changelog](https://github.com/LoyalFTW/Midnight-Routine/compare/v12.0.1...v12.0.2) [Previous Releases](https://github.com/LoyalFTW/Midnight-Routine/releases)

- Update StoryCampaign.lua  
- Merge branch 'main' of https://github.com/LoyalFTW/Midnight-Routine  
- Update StoryCampaign.lua  
- Update .pkgmeta  
- Update  
    * Fixed how we called events  
    * Using AceLibs now for faster calls  
