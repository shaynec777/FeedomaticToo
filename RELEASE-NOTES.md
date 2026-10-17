# HunterTools 3.1.1

## New in this update

- Beast data now includes 622 Petopia Forever creature records, 19 family references, and 32 additional ID-keyed reports from Petopia's community taming sheet, including Vuldren and Ursera. Community reports are labeled unverified; Classic-linked ability teachers remain labeled as such.
- Beast fields use available local observations first, then Petopia Forever and its community reports, Wowhead Forever, and the retained Classic reference. Missing fields can fall through independently. Family training options are separate from innate abilities.
- New local beast field journal (`/ht beasts`): save sightings, explicit Beast Lore details, and the first readable spellbook from a newly tamed pet. Collection is enabled by default and can be turned off. Records stay on your character; a copyable export lets you share them manually. Nothing is uploaded automatically.
- Animal link dialogs offer Petopia, Wowhead Forever and Wowhead Classic copyable addresses, in that order where available.
- Feeding & alerts now displays a live explanation when reminders are paused. `/ht hungerdebug` prints the current alert status.

## Bug fixes

- Hungry text reminders no longer wait indefinitely for inventory loading. Low-food stock warnings still wait for confirmed counts.
- Check whether an item is edible before requesting its food metadata, so uncached non-food items cannot block the food scan.
- Show a normal hungry reminder when usable food is already available, rather than a misleading loading message. Locked food has its own explanation.
- A newly summoned/tamed pet gets its own initial hunger sound rather than inheriting the previous pet's already-alerted state.
- Selected food and ammo tabs remain clickable and have a clear active marker instead of appearing disabled.

## Experimental features and data limits

Ranged weapon comparisons and scope previews remain **Experimental**.

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

This includes character ranged AP, ammo, scope and retained live damage/attack-speed bonuses. The weapon's listed DPS uses only base weapon damage and speed. Estimates exclude armor, misses, crit, special-shot rotations, pets, procs, unsupported effects, stat-percent multipliers and weapon-specific talent changes. See WEAPON-COMPARISONS.md in the source repository for calculation details.

Petopia's Forever site is still incomplete. Some teaching lists retain Classic links, and community reports can change during beta. Unknown ranks, spell IDs and pet-level requirements remain unknown. Family trainable skills are not proof that a particular wild beast has them. The journal's fresh-tame correlation has automated coverage but still needs broader in-game testing; pets tamed before installation cannot be retroactively assigned an NPC identity.

## Updating and testing

Install both addon folders from the ZIP into Interface/AddOns and fully restart WoW. Existing settings are retained. The journal stores up to 2,000 beasts and five nearby player sighting locations per beast; sighting coordinates are not exact spawn points. Collection can be disabled in `/ht beasts`.

Hungry banner delivery was confirmed in-game after the latest fix. Automated Lua 5.1 checks cover the feeding fixes, source precedence, collection events, export, menu navigation and existing features. Broader tame-event ordering and journal visual testing remain outstanding. Please report the feature, what happened, and any error message if something fails.
