# Experimental ranged weapon comparisons and scope previews - local preview

**Experimental:** estimates and scope rules are still being validated against the Forever beta.

Restart WoW once after installation to load the new modules and logo texture. Open `/ht` and click **Weapon comparisons >**, or use `/ht weapons`. Comparisons default enabled and can be disabled independently. Hover a bow, gun or crossbow in bags, a shop, a reward, a linked item tooltip or equipment. Re-hover after changing a scope setting. Item data may need to load first.

## What appears

- Estimated noncritical physical damage range per Auto Shot, average-shot and Auto Shot DPS changes in green/red, current equipped damage/DPS, ammo assumption and effective attack interval.
- Uses the current character-sheet damage and speed as the anchor. Current AP, damage modifiers, quiver/haste and buffs remain in the baseline. It subtracts the old weapon's stats and adds the candidate's stats. Primary-stat AP conversion uses the client's `GetRangedAttackPowerForStat`; when unavailable it explicitly flags a fallback of 2 ranged AP per agility and omission of other primary-stat scaling.
- Scope modes: as actually attached on the hovered item; no scope; match the equipped scope; Crude (+1), Standard (+2), Accurate (+3), Deadly (+5), Sniper (+7). The equipped reference always keeps its actual scope. A preview replaces the candidate scope rather than stacking another scope on it. Nothing is automatically equipped, enchanted or purchased.
- Known scope character levels are 5, 10, 20, 30, 40. The selector filters by your character level, and each hover also checks weapon item level. The weapon-item-level minimum uses a Classic reference rule and is explicitly not a guarantee of Forever application eligibility. Engineering to craft a scope is not treated as a requirement to preview/use one. Unverified hit/proc scopes are not offered as damage scopes.
- The menu header uses the approved original jackknife logo. Its 256px TGA is a format/size conversion of artwork/huntertools-multitool-concept-v1.png; the original is retained.

## Calculation and limits

**Displayed character Auto Shot DPS = ((estimated minimum + estimated maximum shot damage) / 2) / effective shot interval.** The gun/bow's own listed DPS instead uses base weapon damage and base weapon speed. Example from the user's equipped gun: `(17.9 + 24.9) / 2 / 2.03 = approximately 10.5 character Auto Shot DPS`, while the weapon alone lists 4.1 DPS. The character sheet's displayed 17-25 damage agrees with that estimated range, subject to display rounding. This confirms that equipped example, not all candidate-swap mechanics.

The exact swap calculation used for each end of the damage range is:

```text
M = (live equipped maximum - live equipped minimum)
    / (equipped base maximum - equipped base minimum)

AP_delta = candidate stat-derived ranged AP - equipped stat-derived ranged AP
           + candidate direct AP bonuses - equipped direct AP bonuses
AP_delta = max(0, live ranged AP + AP_delta) - live ranged AP

B = (live ranged AP / 14 + ammo DPS) * (candidate base speed - equipped base speed)
    + (AP_delta / 14) * candidate base speed
    + candidate preview scope damage - equipped attached scope damage

candidate estimated minimum = live equipped minimum + M * (candidate base minimum - equipped base minimum + B)
candidate estimated maximum = live equipped maximum + M * (candidate base maximum - equipped base maximum + B)
candidate interval = candidate base speed * (live equipped interval / equipped base speed)
```

If weapon haste rating changes and the client conversion is available, multiply the candidate interval by `(1 + current ranged haste-rating bonus / 100) / (1 + candidate ranged haste-rating bonus / 100)`. These are rating-derived bonuses; the other live speed effects are already retained in the interval ratio. Average-shot gain is candidate average minus live equipped average; DPS gain is candidate average/candidate interval minus live equipped average/live equipped interval. AP conversions use the client helper and the documented fallback below.

The basic Auto Shot reference is `(weapon damage + scope + base weapon speed * (ranged AP / 14 + ammo DPS)) * damage modifiers`. We calibrate the damage modifier from the equipped live damage spread divided by its unenchanted weapon damage spread, and keep the live damage anchor instead of adding already-included buffs again. For a swap, the delta is candidate weapon damage minus equipped weapon damage, plus AP/ammo changes due to base speed, plus the scope replacement. Effective shot speed preserves the live attack-speed ratio. A changed haste rating is adjusted with the native ranged-rating converter when available; otherwise the omission is flagged.

Exact item links retain random suffixes and bonus fields when only the enchant field is neutralized for base stats/damage. Reads are cached up to 80 exact links and cleared on item-data/equipment/world changes. Login and equipment changes briefly defer calculations. No background polling is added.

This is **Auto Shot throughput before armor, misses and crit**, not total hunter/rotation DPS or a guaranteed upgrade verdict. Crit/hit rating changes are shown as omitted contributions; agility's crit benefit is not included. Stat-percent multipliers, procs, conditional/set/use effects, spell damage, special-shot normalization, cast clipping, movement and target effects are not simulated. Changing weapon type also warns about proficiency, weapon-specific talents/racials and quiver differences. Across arrow/bullet weapon types the same ammo DPS is held constant as an explicit comparison assumption; matching ammo must be acquired before use. Unknown scope enchants on the equipped weapon suppress the estimate rather than guessing their contribution. Unknown candidate enchants require an explicit supported scope preview.

Selected equipped ammo must have verified stats and positive carried stock. Depletion asks you to equip stocked ammunition first. Item parsing currently supports English tooltips. Missing, secret or inaccessible data produces an unavailable/loading message or no addition; combat suppresses added weapon comparisons. The main GameTooltip and ItemRefTooltip are supported, with duplicate-line guards. Changing stats/buffs is read on the next hover.

## Sources checked October 16, 2026

- Forever character sheet: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrame.lua (returned ranged min/max already include percentage effects; do not multiply again).
- Forever stat helpers: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua (ranged AP per stat, AP/14 character-sheet conversion).
- API signatures: generated UnitDocumentation.lua, ItemDocumentation.lua and PlayerScriptDocumentation.lua in the same client's Blizzard_APIDocumentationGenerated directory.
- Theorycraft implementation cross-check: https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/hunter.go and https://github.com/gunba/wow-forever-sim/blob/forever/sim/core/attack.go. This is a community model, not a guarantee of every beta mechanic. Its Auto Shot timing audit also distinguishes weapon throughput from rotation/clipping behavior.
- Scope values/required levels: Wowhead Forever items 4405, 4406, 4407, 10546, 10548; Standard Scope spell 3975 confirms enchant ID 32. Remaining scope enchant mappings/minimum weapon-item-level rules retain the Classic reference and require in-game validation.

Validation: all addon modules compile in Lua 5.1. Regression tests verify identical-weapon zero delta, no double-counted scope, AP/agility/intellect swaps, haste conversion, slower-hit/DPS tradeoff, scope gates, exact suffix links/cache invalidation, depletion, missing/secret data, combat, duplicate guards and saved UI choices. Related menu, ammo, pet-browser and animal-tooltip regressions pass. Actual Forever item tooltip parsing, calculations and scope effects still need in-game confirmation.
