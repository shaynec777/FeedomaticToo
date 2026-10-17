# HunterTools

![HunterTools jackknife logo](https://raw.githubusercontent.com/shaynec777/HunterTools/main/artwork/HunterToolsLogo.png)

FeedomaticToo has morphed into HunterTools due to the many great suggestions we've received!

HunterTools brings pet feeding, ammunition reminders and upgrades, dungeon checks, pet information, target range, and an ability browser together for World of Warcraft Forever. All tools can be individually enabled or disabled.

## New in this update

- Refreshed menus with illustrated tool cards, readable opaque panels, clearer navigation, and separate food-catalog/feeding-alert and ammo-tracking/alert-settings tabs.
- New original hunter jackknife logo in the main menu and project artwork.
- Independently configurable animal mouseover tips and range-target details, including pet role, ability ranks, diet, and matching food quantities in your bags. Own-pet role has its own controls.
- Pet ability browser (`/ht abilities`): cached learned ranks, next needed or unconfirmed rank, teaching animals, level ranges and zones. Each animal has a copyable Wowhead Forever link. Creature pictures have a saved Show pet pictures switch and a small paging cache.
- Partial Wowhead Forever creature/family data supplements the Classic teaching reference; unknown abilities remain unknown.
- Ammo upgrade advice within Ammo Reminder: level/weapon/faction filters, sources, future upgrades, Include engineered ammo, and red [Obsolete] labels. Separate upgrade notifications offer a repeat interval and banner, chat, or both.
- Depleted equipped-ammo warnings and recommendations based on usable ammunition actually remaining in your bags.
- **Experimental: ranged weapon comparisons and scope previews** (`/ht weapons`). Compare estimated Auto Shot damage/DPS with your equipped weapon and preview an attached, absent, matching equipped, or known damage scope. This feature is still being validated against the Forever beta.

### Bug fixes

- An empty ammo-slot selection no longer masks an upgrade by retaining the damage of ammunition you have exhausted. Native carried counts override stale bag snapshots after readiness checks.
- New beasts with incomplete reference data retain available details rather than losing all animal information.
- Wowhead buttons use the tested copy dialog; the unsuccessful direct-browser launch attempt has been removed.
- Saved pet lists now have clearer return navigation and close with Esc. Disabling animal pictures clears their cached models and stops model requests.

## Tools and controls

- **Food:** one-click feeding or your Feed Pet keybinding, per-pet allowed/blocked lists, food protection, hunger sounds/text reminders and supply warnings. Food catalog and Feeding & alerts have separate tabs.
- **Ammunition:** track selected ammo types with individual minimums. Configure stock alerts separately from upgrade advice and its notification interval/channel. Engineered ammo is optional. Counts exclude banks and wait through inventory loading.
- **Range and animals:** movable target window with distance estimates, plus independent mouseover and range-target animal fields. Show roles, abilities/learned ranks, diet and matching bag-food quantities. A family does not guarantee tameability.
- **Pet status:** movable own-pet window and own-pet mouseover tips, independently selected details, position locking and reset.
- **Pet abilities:** `/ht abilities` shows learned/next ranks and teaching animals with levels/zones. Wowhead opens a selected URL: press Ctrl+C, then paste it into a browser. Show pet pictures can be turned off; first-time creature models can load slowly.
- **Dungeon checks:** offer to disable Growl autocast, your own Aspect of the Pack, or both on entry. Changes require your click and wait until combat ends.
- **Experimental weapon comparisons and scope previews:** `/ht weapons` enables/disables tooltip estimates and selects the candidate scope preview. Settings are saved per character.

Use `/ht` or `/huntertools` for the tool menu; `/ht foods`, `/ht ammo`, `/ht abilities`, `/ht weapons`, and `/ht petsettings` open their respective controls. `/fom` and `/feedomatictoo` remain aliases. Right-click the feeder or pet-status window for the tool menu. Feeding always requires a click or keypress.

## Experimental ranged comparison formula

**Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.**

For example, `(17.9 + 24.9) / 2 / 2.03` is approximately **10.5 character Auto Shot DPS**. The weapon's own listed DPS uses base weapon damage and base speed. Our estimate includes your character's ranged attack power, ammo, scope and retained live damage/attack-speed bonuses, so it can be higher than the weapon's listed DPS.

Candidate weapons start from your live equipped damage range and add the weapon-stat, attack-power, speed, ammo and scope differences. Current buffs are already in the baseline and are not added again. Scope previews replace the candidate scope; your equipped reference keeps its actual scope. See WEAPON-COMPARISONS.md in the source repository for the exact calculation.

**Ranged weapon comparisons and scope previews are Experimental.** They estimate Auto Shot throughput before armor, misses and critical hits, rather than total hunter DPS. Special-shot rotations, pet damage, procs, conditional effects, stat-percent multipliers and weapon-specific talent changes are not simulated. Unsupported stat changes are flagged. Scope eligibility uses known character levels plus a Classic minimum weapon-item-level rule; actual application still needs verification in Forever. Unknown scope enchants can make an estimate unavailable. English weapon tooltips are currently required.

## Installation and updating

Extract both folders in the release ZIP into Interface/AddOns, replacing the existing addon files, then restart WoW to load the new modules and logo. HunterTools is the addon; FeedomaticToo is a settings-only compatibility loader. Enable both entries for the first migration and keep the compatibility folder until your characters have migrated. Existing per-character settings, food lists and positions are retained. Back up settings before manual installation.

Open Beast Training to seed or refresh learned ranks. Learned and missing labels reflect cached information; incomplete scans or filters can affect confidence. Reference coverage includes 32 abilities / 152 ranks and 297 Classic teaching creatures. Partial Wowhead Forever data supplements creature identities and family diets but does not verify all teaching ranks or locations.

## Beta data and testing

Pet roles, diets and teaching sources include a Classic reference and may differ in Forever. Live Beast Lore takes priority. Unknown details remain unknown; we plan to verify and refine the database after Forever leaves beta.

The menus, animal tooltip changes, ability browser/copy links, ammo recommendations/notifications and depleted-stock behavior have in-game feedback plus automated regression coverage. One equipped-weapon estimate matched the character sheet; candidate weapon and scope effects still need broader testing and remain Experimental. Aspect of the Pack, combined disable, automatic new-ability tracking and some live Beast Lore paths also need broader checks. My hunter isn't level 40 yet, so I haven't been able to test disabling Aspect of the Pack; please let me know how it goes in the comments.

If a feature doesn't work, please leave a comment describing what happened, which feature you were using, and any error message so we can investigate.

## Credits and sources

Original feeding engine: FeedPetForever by Gideon (MIT licensed). Adaptation and enhancements: OpenAI Codex, directed and tested by the user. Original Feed-O-Matic concept: Gazmik Fizzwidget. Original notices are retained; no affiliation or endorsement is implied. Blizzard client portraits, textures and sounds are referenced rather than bundled. The jackknife logo is original AI-generated project artwork, directed and approved by the user.

Food and partial Forever reference: Wowhead Forever. Pet ability/diet baseline: [Petopia Classic](https://www.wow-petopia.com/classic/abilities.php). See PET-DATA-SOURCES.md and WEAPON-COMPARISONS.md for scope, formula sources and limitations. Buff-food detection recognizes English Well Fed tooltip text; manually block any special foods it misses.

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!
