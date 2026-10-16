# Pet lookup data

Factual NPC IDs, ability ranks and minimum pet levels: https://www.wow-petopia.com/classic/abilities.php

Family diets: Petopia Classic family pages. Retrieved 2026-10-14. These are Classic baseline facts, not confirmed Forever records. No descriptions, artwork or addon code copied. Creature coverage includes beasts listed as teaching abilities; unknown creatures remain unknown.


## Hunter ability learning IDs (October 16, 2026)

Source: ForeverDB public client-data shards at https://foreverdb.net/data/spells/{id % 64}.json, as requested by the site's frontend data module (cached as reference-data/forever-spells/frontend-api.js). These are extracted client records, not a claim of observed ability obtainability. Public browsing entry point: https://foreverdb.net/spells?cls=3.

Select only Hunter class 3 records with Learn Spell effect 36 targeting Pet 5. Follow each effect's tr field to the pet casting spell. Training and target records must have explicit, identical ranks and names. Generated coverage: 152 training records / 152 pet casting records / 32 names, including all 106 ranks from our existing baseline. Baseline Screech and current Demoralizing Screech are the same spell IDs and are normalized. The generator fails on missing targets, missing/disagreeing ranks, conflicting mappings or missing baseline coverage.

Regenerate with download-forever-spells.py --refresh and build-pet-learning-map.py; verify with test-pet-learning-map.py. Full coverage and SHA-256 input hashes are in PET-LEARNING-COVERAGE.md and reference-data/forever-spells/learning-map.json. The installed addon reads only its bundled Lua table; it makes no web requests.
