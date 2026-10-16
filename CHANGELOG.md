# HunterTools 3.0.2

## New in this update

- Optional movable pet-status window with health and focus bars, happiness, loyalty, training points, diet, food supply, feeding status and last successful feeding.
- Mouseover tips for your own pet, with independent Window and Mouseover checkboxes for displayed details.
- Saved pet-window placement, position locking and reset controls. Right-click opens the main tool menu.
- Private feeding confirmation: Fed <petname> a delicious <petfood>.
- Improved saved-food-list manager with family labels, legacy grouping, deletion feedback, confirmed inactive-list cleanup and an opaque background.

### Bug fixes

- Reuse food lists by pet name and family across summons and reloads. Same-name pets in different families remain separate.
- Create a default list when a pet is summoned, allowing edible foods subject to existing food restrictions and protections. Deleted legacy lists stay removed; summoning creates a fresh default when needed.
- Fix learned-status updates when hunter training IDs differ from pet casting IDs; reference mappings cover 32 abilities and their ranks.
- Treat Screech and Demoralizing Screech as the same ability.
- Prevent premature low-food alerts while inventory settles after login.

Validation: Lua 5.1 regression checks pass. Pet-status display, independent checkboxes, own-pet tips, feeding text, login food warnings, list cleanup/default creation and duplicate prevention were tested in game. Bite 2 was reported as Learned. Broader automatic-learning and live Beast Lore testing is still welcome.

Aspect of the Pack and Disable Both still need in-game testing; my hunter isn't level 40 yet. If a feature fails, please comment with the feature, what happened and any error message. Pet data uses a Classic baseline during Forever beta; live Beast Lore takes priority.

Install both folders from the ZIP into Interface/AddOns, replacing existing files. Keep the FeedomaticToo settings migration loader enabled for the first import and restart the client.

Original engine: Gideon (MIT); adaptation and enhancements: OpenAI Codex, directed and tested by the user.
Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!

# Saved pet food list cleanup and pet-window navigation (unpublished)

- Key new saved food lists by pet name + family, not transient world GUID. Same-name Raptor and Tallstrider stay separate; same name/family reuses rules across summons. Summoning saves a default profile once name and family are available; subsequent summons and reloads reuse it. All edible foods are allowed by default, subject to existing restrictions and protections. Deleting then summoning creates a fresh default profile.
- Preserve unknown-family legacy records without applying them by name. Show these duplicates as one cleanup group per name; exact current GUID matches can safely gain family metadata. Known-family duplicates consolidate by name/family, combining saved allowed and blocked entries with blocks taking precedence. Legacy records sharing the current pet name remain protected until dismissal/switch.
- Saved-list manager shows group/count/family, Previous/Next navigation, confirmed group deletion and visible remaining counts. Add a separate two-click Delete all inactive lists action; validate the selection again before deleting. Existing user profiles are not deleted by this code installation.
- Saved-list deletion window uses a solid opaque background to prevent the window behind it showing through.
- Right-click on the pet status window now opens the main HunterTools tool menu.
- Lua 5.1 identity, legacy safety, deletion/reopen/reload, confirmations, current-pet protection, combat and navigation tests pass along with the existing addon suite. In-game cleanup validation pending.

# In-game validation — October 16, 2026

- User confirmed pet-status window appearance, independent Window/Mouseover display checkboxes, and own-pet-only tooltip details. User also confirmed the feeding chat message in-game.
- User confirmed the login food-warning fix: no premature warning immediately after logging back in, and none after waiting for inventory to settle with suitable food available.
- User reported Bite rank 2 showing Learned during the new-ability test. The conversation did not explicitly confirm whether Beast Training remained unopened.

# Pet status window and configurable mouseover tips (unpublished)

- Add independent Pet status tool checkbox, /ht pet toggle, and /ht petsettings. Window defaults off; own-pet mouseover tips default on.
- Movable, clamped window with saved per-character position, position lock/reset, portrait/name, health/focus bars and ten configurable fields. Separate Window and Mouseover checkboxes control level/family, health, focus, happiness/damage modifier, loyalty/trend, training points, diet, food/next item, feeding status and last feeding.
- Tooltip augmentation applies only to the player's own pet; hovering the status window shows the same selected tooltip fields. Disabled/missing/restricted APIs have safe fallbacks. Pet data reads pause in combat.
- Record food and timestamp per pet only on confirmed HunterTools feeding. Food inventory remains visibly settling until the login scan completes.
- Lua 5.1 UI/data/settings/tooltip, movement/lock/reset, secret/combat/missing API tests, TOC validation, all 304 learning-ID cases and the existing addon suite pass. Live visual/API verification pending.

# Local feeding chat message (unpublished)

- Print privately: Fed <petname> a delicious <petfood>, after HunterTools receives Feed Pet success for a prepared feeding click/keybinding. Capture the pet and food before bag events change selection.
- Failed/interrupted casts, blocked clicks, expired attempts, changed pets and duplicate success events do not announce.
- Lua 5.1 feeding-message checks and existing addon regressions pass; user confirmed the feeding chat message in-game on October 16, 2026.

# Complete pet learning reference mapping (unpublished)

- Generate hunter training IDs and corresponding pet casting IDs from ForeverDB client spell records: Hunter class 3, Learn Spell effect 36, target Pet 5. Validate both records agree on rank; no guessed spell ID ranges.
- 152 hunter training spells and 152 pet casting spells across 32 abilities; all 106 existing baseline ranks covered. Includes additional Forever spell records. Reference presence does not guarantee current beta obtainability.
- Normalize baseline Screech to the client name Demoralizing Screech, preserving previously cached knowledge.
- Full 304-ID message/label tests, exact effect-relationship checks, higher-rank exclusions, unrelated-message guards, actual saved Cower replay and the existing addon regression suite pass. In-game verification remains pending.
- See PET-LEARNING-COVERAGE.md and reference-data/forever-spells/learning-map.json for the audit table and source hashes.

# Local Cower training-spell fix (unpublished)

- Live capture identified hunter learning spell 1748 for Cower rank 2, distinct from pet cast spell 1753. Add the verified training-spell mapping.
- Reprocess the last captured learning message after loading settings, recovering the already-earned ability without editing saved variables or requiring Beast Training.
- Exact captured-message, immediate target-label, higher-rank exclusion, replay and full addon regression checks pass. Live reload verification pending.

# Local food-login hotfix (unpublished)

- Delay food notifications on login/reload and world entry until a 10-second grace period and two seconds of agreeing fresh inventory scans. Restart confirmation on bag, item-data, lock and pet events; reject an unavailable backpack slot count. Keep rescanning on the regular ticker while waiting.
- Suppress low-food and hunger-text notifications during inventory confirmation; normal feeding selection remains usable. Genuine low/empty food warnings resume after confirmation.
- Lua 5.1 login regressions and the existing addon suite pass; live Tallstrider login retest remains pending.


# Local learning hotfix (unpublished)

- User observed Cower learned status updating only after opening Beast Training.
- Handle hunter-learning spell hyperlinks without a visible rank, preferring client rank subtext and using the existing Classic-baseline spell rank data as fallback. Do not infer hunter knowledge from a pet learning a spell or guess ranks from bare names.
- Always register system learning messages even when the optional event validator is absent. Capture the last matched learning message for /ht trainingdebug.
- Lua 5.1 regressions pass for the reproduced Cower link case, rank changes, trainer scans, unsupported events and guarded messages. Exact live failure and the reported error sound remain unconfirmed; in-game retest required.
# HunterTools 3.0.1

- Fix duplicate Feed Pet keybinding warnings when the legacy FeedomaticToo settings loader and HunterTools are both enabled.
- The compatibility folder now includes an empty Bindings.xml, replacing the old binding declaration. Existing Feed Pet key assignments and automatic settings migration are preserved.

Install both folders from the ZIP, overwriting existing files. Enable HunterTools and the FeedomaticToo settings migration loader for the first import; restart the client.

Original engine: Gideon (MIT). Adaptation and enhancements: OpenAI Codex.

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
