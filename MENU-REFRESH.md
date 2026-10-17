# HunterTools menu refresh - local preview

Restart WoW once after installation so the new MenuStyle.lua module is loaded. Open `/ht`.

- Main menu: six tool cards with built-in hunter/ability icons, short descriptions, an enable checkbox, a visible Enabled/Disabled state, and a labeled action. The header now uses the approved HunterTools jackknife logo. No models or external images are loaded by the menu.
- Food: separate **Food catalog** and **Feeding & alerts** tabs. Search, allowed/blocked editing, filters, protection and food rows stay in the catalog. Food selection order, sounds, reminder interval and food-supply preferences are on the second tab. The current tab is retained while the client session stays open.
- Ammo: **Tracked ammo**, **Alert settings**, and **Upgrade advice >** navigation. Tracked ammo contains selection, search, counts and per-item minimums. Alert settings contains the master switch, sound, default minimum, interval, destination and reminder test. Upgrade advice keeps its own notification controls.
- Consistent opaque charcoal/forest-green backgrounds, subdued green buttons, gold headings, clearer back buttons, and automatic scaling to fit smaller screens. Food and ammo list windows are now 590 units tall, down from 780 and 700.
- Pet/animal field matrices, ability browser, upgrade advice, food protection, saved lists and link-copy dialog receive the shared visual style. Saved-list management now has a Back to food button and closes with Esc.
- Existing settings are retained. The Show pet pictures choice is unchanged. Tool enabling, feeding rules, stock alerts, upgrade calculations and Wowhead copy-only behavior remain as configured.

Validation: all addon modules compile under Lua 5.1. Behavioral regressions cover tool navigation, tabs and control ownership, search and list edits, notification gates, depletion-aware comparisons, picture settings, animal fields, food protection, and list management. The user confirmed the redesigned menus look good in game on October 16, 2026. The new logo header and weapon settings still need in-game review.
