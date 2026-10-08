# Routine

## Unreleased

- **Routine now requires the Routine Data addon.** Install it from the same page as Routine (CurseForge and Wago install it automatically). If you install by hand from a zip, install Routine Data too, or Routine will not load.  
- Routine now shows a popup when RoutineData is installed but disabled, with a Reload button that enables it and reloads, or tells you to install it if it is missing.  
- Moved the tracking engine into Routine Data. Your saved progress, settings and alts are unchanged.  
- The Alt Weekly Board's Banks tab now reads the bag, bank and guild bank snapshots captured by Routine Data. Existing snapshots are imported on first login.  
- The minimap icon tooltip now lists each character's gold with a total. It shows the top five by gold, and holding Shift shows everyone. Turn it off with "Show Character Gold in Minimap Tooltip" in the options.  
- Hovering a tracked rare in the world now shows whether you killed it today or this week, plus the same per-character list the Rares panel shows (hold Shift for the full list). Turn it off in the Rares options with "Show Kill Status on Rare Tooltips".  
- Tooltip Position has a new Default choice, which is now the default. The minimap tooltip keeps its normal placement unless you pick another position.  
- Rare kill status on tooltips now works for Forever rares too.  
- Character names in the Alt Weekly Board's character list now use class colors.  
- "Reset everything" now separates settings from tracked data internally. It still resets both.  

## [v12.0.351](https://github.com/LoyalFTW/Midnight-Routine/tree/v12.0.351) (2026-09-29)
[Full Changelog](https://github.com/LoyalFTW/Midnight-Routine/compare/v12.0.350...v12.0.351) [Previous Releases](https://github.com/LoyalFTW/Midnight-Routine/releases)

- Update / Fixes / Removed Old Code  
    * Fixed custom tasks losing progress when moved between character-only and shared storage.  
    * Preserved manual progress adjustments and recorded encounter completions when changing a task’s sharing or account-wide completion setting.  
    * Fixed an issue where unchecking every encounter difficulty saved the task as tracking all difficulties.  
    * Fixed category settings sometimes applying to the wrong task after moving it between character-only and shared storage.  
    * Reduced repeated checks during PvP weekly-task updates.  
    * Cleaned up duplicated tracking and interface code, including panel updates, font handling, and drag-and-drop ordering.  
    * Changed Namespace to be more relevant for later on  
