local F={db={},VERSION='test'}
local frames={}
CreateFrame=function()
    local f={};function f:RegisterEvent() end;function f:SetScript(_,fn) self.event=fn end
    frames[#frames+1]=f;return f
end
local now=100;GetTime=function() return now end;GetServerTime=function() return 10000+now end
UnitClass=function() return 'Hunter','HUNTER' end
local combat=false;InCombatLockdown=function() return combat end
local pet=false;UnitExists=function(unit) return unit=='pet' and pet or unit~='pet' end
local controlled=false;UnitPlayerControlled=function() return controlled end;UnitIsPlayer=function() return false end
local npc=250868
UnitGUID=function(unit) return unit=='pet' and (pet and 'Pet-0-1-2-3-0000ABCD' or nil) or 'Creature-0-1-2-3-'..npc..'-0000ABCD' end
UnitCreatureType=function() return 'Beast' end
UnitName=function() return 'Vuldren' end;UnitCreatureFamily=function() return 'Fox' end;UnitLevel=function() return 6 end
GetRealZoneText=function() return 'Zephras Isle' end;GetSubZoneText=function() return 'Test area' end
GetBuildInfo=function() return '1.60.1' end
C_Map={GetBestMapForUnit=function() return 123 end,GetPlayerMapPosition=function() return {GetXY=function() return 0.5,0.6 end} end}
local lore
C_TooltipInfo={GetUnit=function() return lore end}
Enum={SpellBookSpellBank={Pet=1}}
local loaded=true
C_SpellBook={HasPetSpells=function() return 1 end,GetSpellBookItemInfo=function() if loaded then return {spellID=17253} end end}
C_PetInfo={GetPetFoodTypes=function() return {'Meat'} end}
assert(loadfile('HunterTools/PetDatabase.lua'))('test',F)
assert(loadfile('HunterTools/ForeverPetData.lua'))('test',F)
assert(loadfile('HunterTools/PetopiaForeverData.lua'))('test',F)
assert(loadfile('HunterTools/PetBrowserData.lua'))('test',F)
assert(loadfile('HunterTools/BeastKnowledge.lua'))('test',F)
local count=0;for _ in pairs(F.petopiaForeverCreatures) do count=count+1 end;assert(count==622)
count=0;for _ in pairs(F.petopiaCommunityCreatures) do count=count+1 end;assert(count==32)
assert(F.petopiaCommunityCreatures[250868].abilities=='Bite 1' and F.petopiaCommunityCreatures[250873].name=='Juvenile Vuldren')
assert(F.BeastRecord(250868).sources.abilities=='Petopia community report (unverified)')
local sonic;for _,a in ipairs(F.petBrowserAbilities) do if a.key=='sonic blast' then sonic=a end end
assert(sonic and #sonic.ranks==2 and not sonic.ranks[1].spellID and not sonic.ranks[1].petLevel)
assert(F.BeastDiet('Fox')=='Meat')
local id,row=F.ObserveBeast('target');assert(id==npc and row.family=='Fox' and not row.tameable and not row.tameSpells)
assert(row.locations[1].mapID==123 and row.locations[1].x==0.5)
F.ObserveBeast('target');assert(#row.locations==1)
lore={lines={{leftText='Diet: Meat'},{leftText='Abilities: Bite Rank 1'}}}
F.ObserveBeast('target');assert(row.diet=='Meat' and row.loreAbilities=='Bite Rank 1' and not row.tameSpells)
local record=F.BeastRecord(npc);assert(record.family=='Fox' and record.sources.family=='Observed in Forever')
-- Missing Petopia fields fall through independently, false values are retained.
F.petopiaForeverCreatures[999]={name='Petopia beast',tameable=false}
F.foreverPetCreatureDB[999]={family='Bear',zone='Forever location',tameable=true}
F.petCreatureDB[999]={abilities='Claw 2'}
record=F.BeastRecord(999);assert(record.name=='Petopia beast' and record.family=='Bear' and record.tameable==false and record.abilities=='Claw 2')
assert(record.sources.abilities:find('Classic',1,true))
-- Failed tame / stable summons do not create teacher records.
local event=frames[1].event
event(nil,'UNIT_SPELLCAST_CHANNEL_START','player','cast-a',1515)
event(nil,'UNIT_SPELLCAST_INTERRUPTED','player','cast-a',1515)
pet=true;event(nil,'UNIT_PET','player');assert(not row.tamedAt)
pet=false;event(nil,'UNIT_SPELLCAST_CHANNEL_START','player','cast-b',1515)
-- Pet event may arrive before cast-success, with a temporarily incomplete spellbook.
pet=true;loaded=false;event(nil,'UNIT_PET','player');assert(not row.tamedAt)
loaded=true;event(nil,'PET_BAR_UPDATE');assert(row.tamedAt and row.tameable and row.tameSpells[1].key=='bite')
local teachers=F.BeastTeachers('bite',1,{});assert(teachers[1].id==npc and teachers[1].reference=='Observed fresh tame')
-- Later training/stable updates cannot overwrite the initial tame snapshot.
C_SpellBook.GetSpellBookItemInfo=function() return {spellID=17255} end
event(nil,'PET_BAR_UPDATE');assert(row.tameSpells[1].rank==1)
local exported=F.ExportBeastJournal();assert(exported:find('"schema":1',1,true) and exported:find('Vuldren',1,true))
-- Taming commonly enters combat: arm before combat, preserve the cast identity,
-- and collect only when public pet data can be read again.
pet=false;npc=888886;now=200
event(nil,'UNIT_SPELLCAST_SENT','player','Vuldren','cast-c',1515)
combat=true;event(nil,'UNIT_SPELLCAST_CHANNEL_START','player','cast-c',1515)
pet=true;event(nil,'UNIT_PET','player');assert(not F.db.beastJournal.records[npc].tamedAt)
combat=false;now=212;event(nil,'PLAYER_REGEN_ENABLED')
assert(F.db.beastJournal.records[npc].tamedAt and F.db.beastJournal.records[npc].petSpellbook[1].spellID==17255)
F.db.beastJournal.enabled=false;npc=999998;assert(not F.ObserveBeast('target'))
F.db.beastJournal.enabled=true;combat=true;assert(not F.ObserveBeast('target'));combat=false
controlled=true;assert(not F.ObserveBeast('target'));controlled=false
issecretvalue=function(v) return v=='secret' end;UnitGUID=function() return 'secret' end;assert(not F.ObserveBeast('target'))
print('PASS: Petopia coverage, field precedence, false values, sightings, Lore, tame identity/events, loading retry, stable/training exclusion, export, toggles, combat/secret guards')
