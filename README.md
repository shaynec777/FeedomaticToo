# FeedomaticToo

Hunter pet feeding for World of Warcraft Forever 1.60.1.

[Download on CurseForge](https://www.curseforge.com/wow/addons/feedomatictoo)

## Installation and use

Extract the release ZIP's FeedomaticToo folder into Interface/AddOns. Enable it, then restart or reload the client.

- Left-click or bind **Feed Pet** under Add-Ons to feed. Feeding requires a click or keypress.
- Right-click for food lists and settings. Shift-drag to move the button.
- `/fom foods` opens settings; `/fom on` and `/fom off` show or hide the button.

## Food selection

Selects suitable unlocked bag food by item level (high or low first), then smaller stacks. Blocked foods are excluded; a nonempty allowed list limits choices. Lists follow the summoned pet, including after renaming. New pets inherit existing default restrictions. The catalog can edit either list. Use **Saved pet lists** to delete an inactive pet's lists.

## Reminders and supplies

Private hunger reminders use the pet's name. Choose Off, Chat, On-screen, or Both, with a configurable repeat interval. Low-food warnings are separate private chat alerts, defaulting to 10 items or fewer, once until restocked. The optional button count shows eligible food items; + means incomplete information. Alerts pause in combat.

## Attribution

Original engine: FeedPetForever 1.0.2 by Gideon, MIT licensed. Adaptation and enhancements: OpenAI Codex, directed and tested by the user. Original Feed-O-Matic concept: Gazmik Fizzwidget. Original license notices are retained. No affiliation or endorsement is implied. No Blizzard media files are bundled.

See FeedomaticToo/README.txt for full controls, limitations, and data sources.

## Development

Source is in FeedomaticToo/. Run test-feedomatic-too.py from the repository root. The Windows harness uses the local DFHack Lua 5.3 DLL; adjust its path for other machines.
