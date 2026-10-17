CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
local F={db={},RangeSettings=function() return {showPetAbilities=true,showPetDiet=true} end}
assert(loadfile('HunterTools/PetDatabase.lua'))('test',F)
assert(loadfile('HunterTools/TargetPetInfo.lua'))('test',F)
local n=0; for id,row in pairs(F.petCreatureDB) do n=n+1; assert(type(id)=='number' and row.abilities and row.family) end
assert(F.petFamilyDiets.Raptor=="Meat")
assert(n==297 and F.petFamilyDiets.Boar:find('Meat',1,true))
UnitExists=function() return true end; InCombatLockdown=function() return false end
UnitCreatureFamily=function() return 'Boar' end; UnitLevel=function() return 8 end
UnitGUID=function() return 'Creature-0-123-1-2-3100-0000ABCD' end
C_TooltipInfo={GetUnit=function() return nil end}
local text=F.TargetPetDetails()
assert(text:find('Charge 1 (pet level 1)',1,true) and text:find('Classic baseline',1,true))
assert(text:find('Eats: Bread, Cheese, Fish, Fruit, Fungus, Meat',1,true))
C_TooltipInfo.GetUnit=function() return {lines={{leftText='Abilities: Charge Rank 2'},{leftText='Diet: Meat'}}} end
F.AnimalSettings().target.role=false
text=F.TargetPetDetails(); assert(text:find('Charge Rank 2',1,true) and not text:find('Classic baseline',1,true))
UnitGUID=function() return 'Creature-0-123-1-2-999999-0000ABCD' end
C_TooltipInfo.GetUnit=function() return nil end
assert(F.TargetPetDetails():find('no database record',1,true))
F.RangeSettings=function() return {showPetAbilities=false,showPetDiet=false} end
local fields=F.AnimalSettings().target
for _,field in ipairs(F.animalFields) do fields[field[1]]=false end
assert(F.TargetPetDetails()==nil)
print('PASS: bundled creature coverage, NPC lookup, family diet, live overrides, unknown IDs and toggles')
