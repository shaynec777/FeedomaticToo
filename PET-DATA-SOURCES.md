# Pet lookup data

Factual NPC IDs, ability ranks and minimum pet levels: https://www.wow-petopia.com/classic/abilities.php

Family diets: Petopia Classic family pages. Retrieved 2026-10-14. These are Classic baseline facts, not confirmed Forever records. No descriptions, artwork or addon code copied. Creature coverage includes beasts listed as teaching abilities; unknown creatures remain unknown.


## Hunter ability learning IDs (October 16, 2026)

Source: ForeverDB public client-data shards at https://foreverdb.net/data/spells/{id % 64}.json, as requested by the site's frontend data module (cached as reference-data/forever-spells/frontend-api.js). These are extracted client records, not a claim of observed ability obtainability. Public browsing entry point: https://foreverdb.net/spells?cls=3.

Select only Hunter class 3 records with Learn Spell effect 36 targeting Pet 5. Follow each effect's tr field to the pet casting spell. Training and target records must have explicit, identical ranks and names. Generated coverage: 152 training records / 152 pet casting records / 32 names, including all 106 ranks from our existing baseline. Baseline Screech and current Demoralizing Screech are the same spell IDs and are normalized. The generator fails on missing targets, missing/disagreeing ranks, conflicting mappings or missing baseline coverage.

Regenerate with download-forever-spells.py --refresh and build-pet-learning-map.py; verify with test-pet-learning-map.py. Full coverage and SHA-256 input hashes are in PET-LEARNING-COVERAGE.md and reference-data/forever-spells/learning-map.json. The installed addon reads only its bundled Lua table; it makes no web requests.

## Animal tooltip preview (October 16, 2026)

Traditional roles use the existing FamilyInfoData.lua classification, exposed as a Classic baseline with Unknown for unlisted families. No role tiers are displayed.

PetFoodTypes.lua extracts only the six diet groups from the locally retained GFW_FeedOMatic/FeedOMatic_Foods.lua in the prior project. The bonus-food group is excluded to avoid overwriting diet classifications. Counts use item IDs, not name guesses. Unknown catalog foods make counts explicitly partial. No addon logic was copied from that reference.

Live Beast Lore ability/diet text takes priority. Food suitability for wild animals uses the traditional food item level >= animal level - 30 rule, labeled as a Classic estimate. It does not apply your own pet's CanPetEatItem result to a different animal. Bag totals include protected/locked food, do not include bank inventory, and do not change feeding selection. These reference facts and level rules still need in-game Forever verification.

## Wowhead Forever overlay (October 16, 2026)

17 partial records are in reference-data/wowhead-forever-pets.json. Regenerate the separate ForeverPetData.lua with build-forever-pet-data.py. Each record retains its Wowhead Forever NPC URL. NPCs are keyed by ID, including separate Galestrider records for Zephras Isle and Mulgore.

Direct Wowhead pages presented a JavaScript anti-bot check. The available indexed Wowhead pages provided NPC identities, selected families/tameability flags, levels and zones. This is NOT a complete Forever import. Missing diet, innate ability ranks and tameability are unknown, not absent or inferred from appearance, wild NPC combat spells, family spell lists, quests, or comments.

Family/level corroboration: https://www.wowhead.com/forever/npcs/beasts/bear and https://www.wowhead.com/forever/npcs/beasts/dragonhawk . Highlands Ursera's NPC link was also present in a Blizzard forum post linking npc=250928. The Mystmane NPC URL was indexed in Russian with its ID; the English bear list supplied its name, family and level. No comments were imported as confirmed taming facts.

The separate Classic table remains a labeled fallback. Live client family and Beast Lore text take priority over static records. New beasts without a family now show available data; unrelated non-beast units are excluded. No Fox role/diet or tameable ability ranks were invented. No new food-type mapping was inferred from drop categories.

### Connected-browser follow-up, October 16

The public Wowhead pages became readable in the in-app browser (which still displayed not logged in; the user's separate Battle.net session was not accessed). Read the rendered Zephras Isle beast list at https://www.wowhead.com/forever/npcs/beasts?filter=6;16593;0 and 24 priority creature detail pages. Total overlay: 27 records including the three prior extra identities. Confirmed family/tameable fields come only from NPC Quick Facts, not from models or comments. New entries include Ursera Scavenger, Vulgara, Urs'anah, Ur'endra, Urs'endris, Den'dralass, Juvenile Vuldren, Shadowgale Shriekling, Shriekling Fledgling and Snapbeak. Missing flags remain unknown.

Read diet statements on the linked Bear, Tallstrider, Cat, Wolf, Raptor, Bird of Prey and Crab family pages; URLs are retained in the JSON families array. Import only diet facts. These pages also use ferocity/tenacity/cunning terminology that has not been validated as Forever's in-game role system; it is not used to overwrite traditional role labels. No family-learnable spell list or NPC combat ability is treated as an innate, teachable pet rank.

## Ability browser reference

Generate with build-pet-browser-data.py. Ranks and required levels come from the cached Forever hunter pet-training spell records selected by build-pet-learning-map.py. Names normalize using the same spell-ID-derived aliases as learned tracking. Teaching animals, wild level ranges and zones are parsed across wrapped HTML lines from retained petopia-abilities.html (Petopia Classic, October 14). Coverage report: reference-data/pet-browser-coverage.json (32 abilities / 152 ranks / 351 teaching links / 297 creatures). Classic trainer/source codes are read from PetAbilitiesData.lua. These are baseline obtainability references, not verified Forever teachers. Missing sources remain unknown. Regeneration is deterministic; the addon makes no network requests.

Wowhead button API reference: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/URLDocumentation.lua . LaunchURL is marked HasRestrictions=true and has no documented return value. Direct browser opening was removed after in-game testing. Buttons only show a selected, copyable link; no launch attempt is made.


## Petopia Forever and local observations — October 17, 2026 (3.1.1-dev)

The static lookup now resolves missing fields in this order: observations saved on this character; Petopia Forever; Petopia-linked community taming reports; the retained Wowhead Forever overlay; the legacy Classic reference. The legacy Classic facts were originally extracted from Petopia Classic and link to Wowhead Classic; they are not newly verified Forever facts. Copy dialogs offer Petopia first, then Wowhead Forever, then Wowhead Classic. The addon never queries websites in-game.

Petopia Forever import: 622 creature IDs, 19 families, and 342 ability-teaching links covering 294 creatures. Family diets, roles, locations, levels and explicit tameability flags are factual fields only. Family trainable abilities are displayed separately from innate animal abilities. Many teaching rows on Petopia Forever still link Classic NPC pages: these retain the label `Petopia Forever (Classic-linked)` rather than claiming in-game confirmation.

The public spreadsheet linked by xWillawisp in https://forums.wow-petopia.com/viewtopic.php?t=27358 provides 32 additional ID-keyed creature reports and 21 reported teaching links, including Vuldren and Ursera. Source: https://docs.google.com/spreadsheets/d/e/2PACX-1vQ9XgOGgdQ_Jpo6GaGOuSQRC7w8WNlNAs5Yb5XhglYCSyaksJ_Qw6QmUZq05ObeOJhBsPyeK1abupXl/pubhtml . These are labeled `Petopia community report (unverified)`. Appearance links are not NPC identities. The 26 rows without explicit IDs were skipped; no name/appearance guesses were made. Existing Wowhead ID-keyed identities normalize spelling where available. Reported new Sonic Blast ranks can be browsed, with unknown spell IDs and pet-level requirements left unknown. Reports of no ability do not become a confirmed absence.

Regenerate from retained public HTML with `python build-petopia-forever-data.py`; refresh linked main-site pages with `python download-petopia-forever.py`. The community sheet is separately cached as community-tames-sheet.html. Retained inputs, hashes, factual JSON and coverage report are under reference-data/petopia-forever/. No artwork, descriptions or addon code were imported.

Local collection is enabled by default as requested. `/ht beasts` opens the journal, collection checkbox and copyable JSON export. Target/hover events save wild beast identity, live family, level range, zone, optional nearby player sighting coordinates (five per creature), timestamps, locale and client build. Explicit English Beast Lore diet/ability lines are retained separately. Up to 2,000 creature records are saved per character in HunterToolsDB; oldest entries are replaced when full. Nothing is uploaded automatically.

Fresh tame capture correlates Tame Beast cast-sent / channel start on an identified wild target with a new pet appearing within 30 seconds. The first complete, public pet spellbook is captured, with a five-second loading window after the pet appears. Failed/interrupted casts, pre-existing pets, stable summons without a tame, changed pet GUIDs, late training and secret/combat data are excluded. All spell IDs are retained for research, including unknown spells. Recognized non-trainer ranks become local teaching references. An empty or incomplete spellbook is not proof of no abilities. Current pets tamed before installation cannot be retroactively assigned a wild NPC ID.

Regression checks cover precedence per field (including false values), incomplete records, source labels, sightings, tame identity/events/loading, training and stable exclusions, export, UI controls, copy fallbacks, and combat/secret guards. New modules require a client restart for in-game verification.
