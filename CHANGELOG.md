# 2.6.0

- Hunger reminders use the current pet's name, with a safe fallback.
- Optional food count on the button; + indicates an incomplete count.
- Configurable low-food warning in private chat, default 10 items. Warns once per pet until restocked above the threshold.
- Separate allowed and blocked food lists for each pet, identified by GUID so renames and duplicate names are safe.
- Catalog switches between editing blocked and allowed foods. Empty allowed lists permit all otherwise eligible foods; blocks win.
- Saved pet list manager with confirmed deletion for inactive pets.
- Existing food restrictions provide the initial settings for each pet.

Original engine: Gideon (FeedPetForever, MIT). Adaptation and enhancements: OpenAI Codex.
User tested in game; Lua and behavior tests pass. Intended for WoW Forever 1.60.1 only.
