# HunterTools 3.0.0

- Rename FeedomaticToo to HunterTools, with a settings-only legacy loader and one-time per-character migration.
- Four-tool configuration menu with enable checkboxes and Settings buttons; /ht and /huntertools commands, old aliases retained.
- Add Growl / Aspect of the Pack entry prompts, with explicit disable buttons and no repeat prompt for intentionally re-enabled effects.
- Add draggable target portrait/name, colored range labels, gray non-enemy targets, and estimated distance bands.
- Bundle 297 Classic ability-teaching creature records and 17 family diets; live Beast Lore overrides baseline details.
- Add optional pet details and learned-ability status colors; adapt Beast Training lookup to Forever's trainer interface.
- Add optional buff-food and cooking-ingredient protection, OFF by default, plus clearer feeding status.
- Fix false low-ammo warnings on entering or leaving instances while inventory/equipment data is loading. Wait for weapon data, confirm fresh carried totals, and allow inventory to settle.
- Fix missing instance-settings initialization and unsupported CRAFT_SHOW registration. Add raptor diet entry.

Known limitations: Classic pet data may differ from Forever. Aspect of the Pack and Disable Both remain untested in game. Automatic ability learning and live Beast Lore parsing need further validation.

My hunter isn't level 40 yet, so I haven't been able to test disabling Aspect of the Pack. If someone can test it, please let me know how it goes in the comments.
If a feature doesn't work, please leave a comment describing what happened and any error message.

Original engine: Gideon (MIT); adaptation and enhancements: OpenAI Codex.
Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!
