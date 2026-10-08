# Routine Data

## Unreleased

- Routine's tracking engine now ships in this addon. Routine requires Routine Data and loads it first.
- New public API for other addons: characters, progress, professions, rare kills, resets, gold and bank data, plus callbacks for resets and data changes. See the README.
- Bag, bank, warband bank and guild bank capture now builds one detailed snapshot per scan. The item tooltips and Routine's Banks tab both read from it, so bags and banks are only scanned once.
- Routine's existing bank, bag and guild bank snapshots are imported on first login. Nothing is removed from Routine's saved data.
- The minimap tooltip lists the top five characters by gold; hold Shift to see everyone.
- The minimap button stays hidden while Routine is loaded, since Routine has its own. Your hide setting is kept, and the button returns if you disable Routine. The Data Broker feed is unaffected.
- New `API.GetGoldRanking()`.
- Rare kill status on the tooltip of a rare you hover in the world. It follows the quest each rare completes, so it works without Routine. Other characters show what was seen when they last logged in. Toggle with `/rdata toggle rares`. Routine shows its own, more detailed version, so this one is skipped while Routine is loaded.
- Localization setup with English text as the base. Translations Routine already has (such as "Needs login" and "Not killed") are reused; anything else shows in English until translated.
- Routine Data also loads on the Forever client: the tracking engine, minimap button, gold broker, settings panel, slash commands, item owner tooltips, bag, bank and guild bank capture, and rare kill status on tooltips using the Forever rare list that now ships with Routine Data. Currency balances on tooltips work wherever the game exposes a currency list.

## v0.1.0

- Item tooltips showing which characters own an item (bags, bank, warband bank, guild bank).
- Currency tooltips with each character's balance and weekly progress.
- Gold tracking, a Data Broker display and a minimap button.
- `/rdata` commands and a settings panel.
- One-time import of Routine's existing bag, bank and gold data.
