# HunterTools 3.1.0

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

## Experimental comparison formula and limits

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

This includes character ranged AP, ammo, scope, and retained live damage/attack-speed bonuses; base weapon DPS uses only weapon damage and base speed. For example, (17.9 + 24.9) / 2 / 2.03 is approximately 10.5 character Auto Shot DPS. Candidate estimates adjust the live equipped baseline for weapon stats, speed and scope changes, without adding existing buffs twice.

Estimates are before armor, misses and crit, and exclude special-shot rotations, pets, procs and unsupported effects. Weapon-specific talent changes, stat-percent multipliers and scope application rules are not fully modeled. Scope character-level filters use known values; minimum weapon-item-level rules retain a Classic reference and require Forever validation. English item tooltips only. See WEAPON-COMPARISONS.md for the exact swap formula.

## Updating and validation

Install both HunterTools and FeedomaticToo folders from the ZIP, replacing existing files. Restart WoW once for the new modules and logo. Existing per-character settings are retained. `/ht` opens the tool menu. All tools can be enabled or disabled independently.

Lua 5.1 syntax and regression checks cover menus, feeding, pet data/learning, ability browsing, ammo stock/upgrades/notifications, tooltip guards and weapon/scope calculations. Menus, the copy dialog, ammo stock/depletion behavior and selected tooltip features were checked in game. One equipped-weapon damage range matched the character sheet; broader candidate/scope validation remains outstanding, so both comparisons and scope previews are explicitly Experimental.

Pet teaching sources and roles include a Classic baseline and may differ in Forever; live Beast Lore takes priority. Aspect of the Pack and combined disable still need broader in-game testing. If a feature fails, please report what happened, which feature you were using, and any error message.
