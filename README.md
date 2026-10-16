# HunterTools

FeedomaticToo has morphed into HunterTools due to the many great suggestions we've received!

HunterTools brings pet feeding, ammunition reminders, dungeon checks, and target range information together for World of Warcraft Forever.

## New in this update

- Optional movable pet-status window with health and focus bars, happiness, loyalty, training points, diet, food supply, feeding status, and last successful feeding.
- Mouseover tips for your own pet, with separate checkboxes to choose what appears in the window and tooltip.
- Pet-status window position locking, saved placement, and a reset-position control.
- Private feeding messages: “Fed <petname> a delicious <petfood>.”

### Bug fixes

- Saved food lists now follow pet name and family, avoiding duplicate lists across summons while keeping identically named pets of different families separate. Summoning creates or reuses a default list, with all edible foods allowed unless restricted by food rules or protections.
- Saved-list management groups legacy duplicates for cleanup, shows deletion results, and offers confirmed deletion of inactive lists in an opaque window.

- Fix missing learned-ability updates when hunter training spell IDs differ from pet casting spell IDs. Reference mappings now cover 32 pet abilities and their ranks.
- Recognize Screech and Demoralizing Screech as the same ability when displaying learned status.
- Delay low-food warnings until inventory settles after login, preventing temporary empty-bag readings from triggering an alert.

## Tools

- Food: feed with one click or your Feed Pet keybinding. Separate pet food lists, ranking options, named hunger reminders, sounds, supply warnings and optional food protection. Quest protection defaults on; buff food and cooking ingredient protection default off.
- Instance: on dungeon or raid entry, offer to disable Growl autocast, your own Aspect of the Pack, or both. Changes require your click. Intentionally enabling Growl afterward does not prompt again.
- Ammo: select ammunition types and separate minimums, choose reminder channels and repeat intervals. Counts carried ammo and defers checks during combat and zoning.
- Pet status: optional movable window and own-pet mouseover tips. Choose each displayed detail independently; lock or reset the window position. Right-click the window for the tool menu.
- Range: draggable target name and portrait, range labels and estimated distance bands. Non-enemies appear gray. Optional target pet abilities, ranks, level and diet, with green Learned and red Not Learned markers based on the cached Beast Training list. This is a range estimate, not a guarantee of line of sight or attack readiness.

## Controls and updating

Use `/ht` or `/huntertools` for the tool menu. Each tool has an enable checkbox and Settings button. Right-click the feeder or target window for settings. `/fom` and `/feedomatictoo` remain aliases. Drag windows outside combat. Feeding always requires a click or keypress.

Extract both folders in the ZIP into Interface/AddOns. HunterTools contains the addon; FeedomaticToo is a settings-only compatibility loader. It replaces the old addon manifest so old buttons do not run. Enable both entries for the first migration, then restart WoW. Existing per-character food lists, reminders, ammunition settings and window positions are copied once into HunterToolsDB. Keep the compatibility folder until your characters have migrated. Back up settings before manual installation.

Open Beast Training once to seed the learned-ability cache. New ability notifications update confirmed ranks. Missing labels reflect the cached training list; filters, other pet families, and incomplete scans can affect the result.

## Beta data and testing

Pet ability and diet information currently uses a Classic baseline while Forever is in beta and may differ from Forever. Live Beast Lore information takes priority. We plan to verify and refine the database after Forever leaves beta. The bundled lookup contains 297 ability-teaching creatures and 17 family diets; unknown entries remain unknown.

Growl disable, learned-status colors, cooking-ingredient protection, tool toggles, the pet-status window display, independent display checkboxes, own-pet-only mouseover tips, the feeding confirmation message, and the login food-warning fix, and default food lists without duplicate entries were confirmed in game. Aspect of the Pack, combined disable, automatic new-ability tracking and live Beast Lore parsing still need broader testing. Ammo zoning fixes and other edge cases have automated regression coverage.

My hunter isn't level 40 yet, so I haven't been able to test disabling Aspect of the Pack. If someone can test it, please let me know how it goes in the comments.

If a feature doesn't work, please leave a comment describing what happened, which feature you were using, and any error message so we can investigate.

## Credits and sources

Original feeding engine: FeedPetForever by Gideon, MIT licensed. Adaptation and enhancements: OpenAI Codex, directed and tested by the user. Original Feed-O-Matic concept: Gazmik Fizzwidget. Original license notices are retained. No affiliation or endorsement is implied. Blizzard portraits, textures and sounds are referenced from the client, not bundled.

Food catalog: Wowhead Forever. Pet ability and diet baseline: [Petopia Classic](https://www.wow-petopia.com/classic/abilities.php), retrieved October 14, 2026. See PET-DATA-SOURCES.md for data scope. Buff-food detection currently recognizes English Well Fed tooltip text; manually block any special foods it misses.

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!
