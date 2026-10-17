local context=assert(loadfile('test-menu-redesign.lua'))()
local F=context.F
InCombatLockdown=function() return false end
assert(loadfile('HunterTools/BeastKnowledge.lua'))('test',F)
assert(loadfile('HunterTools/BeastJournalUI.lua'))('test',F)
F.OpenBeastJournal()
local p=F.beastJournalPanel
assert(p.shown and p.enabled.checked and p.summary.text:find('0 beasts recorded',1,true))
assert(p.export.text:find('"schema":1',1,true))
p.enabled:SetChecked(false);p.enabled.scripts.OnClick();assert(not F.db.beastJournal.enabled)
F.OpenConfig();assert(not p.shown)
F.OpenBeastJournal();assert(not p.enabled.checked)
F.db.beastJournal.records[123]={name='Test beast',family='Wolf',tamedAt=123}
F.OpenBeastJournal();assert(p.summary.text:find('1 beasts recorded | 1 fresh tames',1,true) and p.export.text:find('Test beast',1,true))
-- The link dialog offers the requested source order without trying to open a browser.
assert(loadfile('HunterTools/PetAbilityBrowser.lua'))('test',F)
F.petopiaForeverCreatures={[123]={source='https://www.wow-petopia.com/forever/look.php?id=test'}}
F.OpenPetAnimalWowhead({id=123,name='Test beast'})
local d=F.wowheadLinkPanel
assert(d.url.text=='https://www.wow-petopia.com/forever/look.php?id=test' and d.petopiaButton.enabled)
d.foreverButton.scripts.OnClick();assert(d.url.text=='https://www.wowhead.com/forever/npc=123')
d.classicButton.scripts.OnClick();assert(d.url.text=='https://www.wowhead.com/classic/npc=123')
F.OpenPetAnimalWowhead({id=124,name='Unlisted beast'});assert(not d.petopiaButton.enabled and d.url.text=='https://www.wowhead.com/forever/npc=124')
print('PASS: beast journal navigation, persistent collection toggle, export, counts, Petopia/Forever/Classic copy links')
