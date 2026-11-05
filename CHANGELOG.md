# Changelog

## 0.2.0 (unreleased)

- **Its own errors, kept** (Pergamino 5): a Lua error in a handler no longer reaches the player as a popup; it is kept in `ListosParaLaRaidDB.errors` (last 10), said once in the chat, and `/listos errores` opens a card to copy it into a GitHub issue.
- **Minimap button** of our own (Pergamino 2): a click opens the page, drag it around the minimap; `/listos minimapa on|off`. Pergamino 2 also brings scroll bars only when the list overflows.
- **Your own row** is always in the list, with or without a guild (before, a player without a guild saw an empty list).
- Singular texts ("1 level to go", "tomorrow"); clicking the page brings it over any other open book.
- Fixed: "Copy list" raised `wrong number of arguments to 'insert'` (`UnitName` returns the realm too); `Bindings.xml` is no longer listed in the TOC (it logged XML warnings).
- **The window is a parchment page** (the shared Pergamino skin, vendored in `Libs/Pergamino`): countdown in big type, your status in ink, the guild as a scrolling list with a gold seal on whoever is ready for Onyxia, "Copy list" on a parchment card, a wax seal to close. No Blizzard templates left.
- **Language setting**: `/listos idioma es|en|auto` (saved per account) so Spanish speakers on an English client get Spanish.
- Below level 50 the window says how many levels are left and that the attunement starts at 50, instead of "step 0 of 16" and "not ready".
- Own icon in the addon compartment and a key binding to open the window.
- The fire-resistance hint no longer uses an emoji the game's font can't draw.

## 0.1.0 (unreleased)

First version, for WoW Forever 1.60.1.

- Countdown to the raids of December 9 (The Barrow Deeps, Hyjal Summit, Onyxia's Lair).
- Your readiness: level, Drakefire Amulet (bags or bank), Onyxia attunement step for both factions, fire resistance; which raids you can enter.
- The guild's readiness over addon messages that carry only numbers, ready players first, with a copyable CSV list.
