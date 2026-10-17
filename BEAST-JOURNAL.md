# HunterTools 3.1.1-dev — local testing

- Petopia Forever: 622 beast records, 19 family references, and source-labeled teaching information.
- Petopia-linked community reports: 32 new beast IDs and 21 reported teaching links, including the Skyborn area. Unverified reports and Classic-linked sources remain clearly labeled.
- Per-field source fallback retains Wowhead Forever, then the previous Classic reference. Copy dialogs offer Petopia / Wowhead Forever / Wowhead Classic addresses.
- `/ht beasts`: local sightings, Beast Lore, fresh-tame spellbook collection, collection checkbox and copyable JSON export. No automatic uploads. Enabled by default; future tames after restart can be recorded.
- Selected Feeding & alerts and ammunition tabs stay clickable and show an active marker, rather than appearing disabled.
- Hungry text alerts no longer wait for inventory loading; uncertain food stock is described as loading. Low-food stock warnings still wait for confirmed counts.
- New pets get their own initial hunger sound rather than inheriting the previous pet's alert latch.
- Feeding & alerts shows a live reason when alerts are paused; `/ht hungerdebug` prints the state and inventory/sound flags.

Automated Lua 5.1 checks pass. Actual tame-event ordering, journal layout and hunger alerts still require in-game confirmation. This development build has not been published to CurseForge or GitHub.


## Petopia Forever and local observations — October 17, 2026 (3.1.1-dev)

The static lookup now resolves missing fields in this order: observations saved on this character; Petopia Forever; Petopia-linked community taming reports; the retained Wowhead Forever overlay; the legacy Classic reference. The legacy Classic facts were originally extracted from Petopia Classic and link to Wowhead Classic; they are not newly verified Forever facts. Copy dialogs offer Petopia first, then Wowhead Forever, then Wowhead Classic. The addon never queries websites in-game.

Petopia Forever import: 622 creature IDs, 19 families, and 342 ability-teaching links covering 294 creatures. Family diets, roles, locations, levels and explicit tameability flags are factual fields only. Family trainable abilities are displayed separately from innate animal abilities. Many teaching rows on Petopia Forever still link Classic NPC pages: these retain the label `Petopia Forever (Classic-linked)` rather than claiming in-game confirmation.

The public spreadsheet linked by xWillawisp in https://forums.wow-petopia.com/viewtopic.php?t=27358 provides 32 additional ID-keyed creature reports and 21 reported teaching links, including Vuldren and Ursera. Source: https://docs.google.com/spreadsheets/d/e/2PACX-1vQ9XgOGgdQ_Jpo6GaGOuSQRC7w8WNlNAs5Yb5XhglYCSyaksJ_Qw6QmUZq05ObeOJhBsPyeK1abupXl/pubhtml . These are labeled `Petopia community report (unverified)`. Appearance links are not NPC identities. The 26 rows without explicit IDs were skipped; no name/appearance guesses were made. Existing Wowhead ID-keyed identities normalize spelling where available. Reported new Sonic Blast ranks can be browsed, with unknown spell IDs and pet-level requirements left unknown. Reports of no ability do not become a confirmed absence.

Regenerate from retained public HTML with `python build-petopia-forever-data.py`; refresh linked main-site pages with `python download-petopia-forever.py`. The community sheet is separately cached as community-tames-sheet.html. Retained inputs, hashes, factual JSON and coverage report are under reference-data/petopia-forever/. No artwork, descriptions or addon code were imported.

Local collection is enabled by default as requested. `/ht beasts` opens the journal, collection checkbox and copyable JSON export. Target/hover events save wild beast identity, live family, level range, zone, optional nearby player sighting coordinates (five per creature), timestamps, locale and client build. Explicit English Beast Lore diet/ability lines are retained separately. Up to 2,000 creature records are saved per character in HunterToolsDB; oldest entries are replaced when full. Nothing is uploaded automatically.

Fresh tame capture correlates Tame Beast cast-sent / channel start on an identified wild target with a new pet appearing within 30 seconds. The first complete, public pet spellbook is captured, with a five-second loading window after the pet appears. Failed/interrupted casts, pre-existing pets, stable summons without a tame, changed pet GUIDs, late training and secret/combat data are excluded. All spell IDs are retained for research, including unknown spells. Recognized non-trainer ranks become local teaching references. An empty or incomplete spellbook is not proof of no abilities. Current pets tamed before installation cannot be retroactively assigned a wild NPC ID.

Regression checks cover precedence per field (including false values), incomplete records, source labels, sightings, tame identity/events/loading, training and stable exclusions, export, UI controls, copy fallbacks, and combat/secret guards. New modules require a client restart for in-game verification.
