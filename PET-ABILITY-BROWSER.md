# Pet ability browser - local preview

Restart WoW after installation so the new modules load. Open with `/ht abilities`, or `/ht` > Pet abilities > Settings. The Pet abilities checkbox independently enables/disables the browser. Close with Escape; drag outside combat. The browser closes on entering combat.

- Search for an ability, click it, then click a rank. Opening/selecting an ability defaults to the next rank above your cached highest learned rank.
- Green ranks are learned according to the cache; red are missing according to the cache; yellow are unknown until training is scanned. Lower learned ranks are inferred from the highest cached rank, matching existing addon tracking.
- Open Beast Training to populate the cache. Refresh or reopen the browser afterward; displayed progress also refreshes once per second. A filtered or incomplete training scan is not proof that every red rank is truly missing.
- The right column lists teaching creatures, their wild level ranges and zones. Both ability and animal lists have Previous/Next pages. The selected rank's required pet level appears above the animal list.
- Coverage: 32 abilities, 152 ranks from cached Forever client spell data. Teaching references: 351 links / 297 creatures from the retained Petopia Classic source, labeled as a baseline. Forever-only ranks without confirmed teachers say so. Trainer-only references are labeled Classic. Family-learnable spells and wild combat abilities were not imported as confirmed teachable ranks.
- The browser does not claim Wowhead's new Zephras identity records confirm pet skills. Live Forever teacher verification remains needed. Each teaching animal now has a Wowhead button linking to its Forever NPC page.

Testing: try Bite, select rank 1 and rank 2, page animal results, and check levels/zones. Try Arcane Resistance for the trainer reference and Swipe for an unknown teaching source. Search for a nonexistent name and clear the search. Reopen after learning/scanning a rank, and confirm the next rank changes. Test the enable checkbox and combat closure.

Automated Lua 5.1 checks cover rank confidence/next-rank selection, all learned, search, pagination, source integrity, trainer/unknown source handling, refresh, toggles, navigation and combat. In-game visual testing remains necessary.

## Wowhead buttons

Click Wowhead beside an animal to display its selected Forever NPC URL. Press Ctrl+C, open your browser, paste into its address bar and press Enter. Select address restores selection. Escape or Close dismisses the dialog. Direct browser opening was tested in-game and did not work; the addon no longer attempts it. The copy dialog was confirmed working in-game.

Teaching animals now include client-rendered creature model thumbnails beside their names, levels and locations. Unavailable models show a question-mark placeholder. Appearance comes from the current Forever client; the teaching-source reference remains Classic.

Portrait loading: retain up to four creature models per row (24 frames maximum), reusing recent pages without another SetCreature request. Loading models show `...`; unavailable models show `?`. First-time client model loading can still take time. The cache lasts until reload/logout.

The ability browser has a per-character **Show pet pictures** checkbox beside the search area. Uncheck it to hide portraits, clear cached models and stop creature-model requests; animal text uses the freed space. The choice remains saved when reopening the browser or reloading.
