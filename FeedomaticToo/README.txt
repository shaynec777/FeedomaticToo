Version 2.5.0: configurable private hunger text reminders. Modes: Off, Chat, On-screen, Both. Default on-screen with repeats every 3 minutes. Set repeat minutes to 0 for once per hunger episode; 0-120 minutes accepted, including fractions. Reminders pause during combat and feeding and include a no-suitable-food explanation. Sound controls remain separate. 

Version 2.4.2 changes: red whole-icon warning when no suitable food is available; current-pet diet in tooltip; prominent CHECK TO BLOCK catalog instruction.

FeedomaticToo 2.5.0
Hunter pet feeding for World of Warcraft Forever beta.

COMPATIBILITY
Tested by the user on Forever beta 1.60.1.70338 (Interface 16001).
Other WoW editions are not supported by this release. Requires Feed Pet.

INSTALLATION
Extract the FeedomaticToo folder into Interface/AddOns in your Forever client.
Enable FeedomaticToo in the character AddOns list, then restart the client.
Disable other feeding-button addons if you do not want duplicate controls.
No legacy Feed-O-Matic addon or settings migration is required.

CONTROLS
Left-click: feed the selected suitable food when feeding is available.
Right-click: open the food catalog and settings.
Shift-left-drag outside combat: move the button.
Key Bindings > Add-Ons > Feed Pet: assign the same action to a key.
/fom foods: open configuration. /fom on and /fom off: show or hide the button.
/feedomatictoo is an alias for /fom. Settings are saved per character.
Feeding always requires your click or keypress. It is unavailable in combat.
The button hides on non-Hunters; idle tooltips explain unavailable feeding.

FOOD SELECTION
Scans carried bags for unlocked food the client says your current pet can eat.
Blocked foods are excluded. A nonempty whitelist restricts eligible choices;
the blacklist wins. Highest item level is preferred by default; switch to
lowest-first in configuration. Equal levels prefer the smaller stack, then
bag order. Item level is not vendor price or measured happiness gain.
The tooltip previews the next food and explains why it was selected.
There is no automatic protection for buff food or cooking/quest ingredients;
block any food you want to preserve.

CATALOG
Search by name or item ID. Checked food rows are blocked.
Pictures and Can eat / Cannot eat labels come from the game client.
Combine In bags, Edible by current pet, and Blocked filters with search.
Blocked means explicitly blacklisted. An edible filter needs a summoned pet.
Uncached item details load asynchronously; newly discovered foods are saved.
The initial 322-entry Wowhead category includes drinks and database entries,
and is not an exhaustive list of pet food. Eligible carried foods are added.

LIST COMMANDS
/fom blacklist add <item link or numeric ID>
/fom blacklist remove <item link or numeric ID>
/fom blacklist list
/fom blacklist clear
Use whitelist instead of blacklist for an allow-only list.
An empty whitelist permits all otherwise suitable, unblocked foods.

HAPPINESS AND SOUND
Border: green = happy, yellow = content, red = unhappy; gray when unavailable.
Hunger alerts play once per episode, with at least 60 seconds between alerts.
Pet-family sounds fall back to wolf for unknown families/locales or playback
failure. Use default wolf sound overrides family selection. Mute overrides
both. Test sound reports playback status. Audio uses WoW Master volume.
No Blizzard sound or texture files are distributed with this addon.

CREDITS
Original feeding engine: FeedPetForever 1.0.2 by Gideon, MIT licensed.
Adaptation and enhancements: OpenAI Codex, directed and tested by the user.
Original Feed-O-Matic concept: Gazmik Fizzwidget.
See LICENSE-FeedPetForever.txt for the retained original license notice.
No affiliation with or endorsement by the original authors is implied.

DATA SOURCES
Food IDs/names: Wowhead Forever Food & Drinks, retrieved 2026-10-11:
https://www.wowhead.com/forever/items/consumables/food-and-drinks
Client sound ID reference:
https://github.com/wowdev/wow-listfile

VALIDATION
Lua syntax and mocked selection, filters, sounds, and combat guards pass.
User confirmed general operation, keybinding, and repaired sound playback.
This is a beta-client release; every family sound and client state has not
been individually tested. English family names currently select custom sounds;
unrecognized localized names fall back to wolf.
