-- Runs in the same mocked client as test-feedomatic-too.py.
local F = ...
InCombatLockdown=function() return false end
UnitExists=function() return true end
F.db.blacklist={[2]=true}
C_PetInfo.CanPetEatItem=function(id) return id==1 end
assert(F.CatalogMatches(1,4,{inBags=true,edible=true},true))
assert(not F.CatalogMatches(1,0,{inBags=true},true))
assert(not F.CatalogMatches(2,4,{edible=true},true))
assert(F.CatalogMatches(2,4,{blocked=true,inBags=true},true))
assert(not F.CatalogMatches(1,4,{blocked=true},true))
assert(not F.CatalogMatches(2,4,{blocked=true,edible=true},true))
assert(not F.CatalogMatches(1,4,{edible=true},false))
UnitExists=function() return false end
assert(not F.CatalogMatches(1,4,{edible=true},true))
local calls={}
PlaySoundFile=function(path,channel) assert(channel=="Master"); table.insert(calls,path); return true end
F.db.mute=false; F.db.wolfSound=false
UnitCreatureFamily=function() return 'Cat' end
F.PlayHungerSound(); assert(calls[1]==562388)
F.db.wolfSound=true; F.PlayHungerSound(); assert(calls[2]==564228)
F.db.mute=true; F.PlayHungerSound(); assert(#calls==2)
F.db.mute=false; F.db.wolfSound=false
UnitCreatureFamily=function() return 'Unknown family' end
assert(F.HungerSoundPath()==564228)
UnitCreatureFamily=function() return 'Bear' end
calls={}; PlaySoundFile=function(path) table.insert(calls,path); return false end
F.PlayHungerSound(); assert(#calls==2 and calls[2]==564228)
InCombatLockdown=function() return true end
UnitCreatureFamily=function() error('Must not query pet during combat') end
assert(F.HungerSoundPath()==nil)
assert(not F.CatalogMatches(1,4,{edible=true},true))
assert(F.WhyThisFood()==nil)
InCombatLockdown=function() return false end
F.mode='food'; F.food={name='Test fish',level=15,count=3}
F.db.foodOrder='high'; assert(F.WhyThisFood():find('highest',1,true))
F.db.foodOrder='low'; assert(F.WhyThisFood():find('lowest',1,true))
F.pendingItems=true; assert(F.WhyThisFood():find('still loading',1,true))
F.food=nil; assert(F.WhyThisFood()==nil)
print('PASS: combined catalog filters, pet sounds, wolf fallback, mute, combat and selection explanations')

UnitExists=function() return true end
C_PetInfo.GetPetFoodTypes=function() return {"Meat", "Fish"} end
assert(F.PetDietText()=="Pet eats: Meat, Fish")
C_PetInfo.GetPetFoodTypes=function() return "Fruit", "Fungus" end
assert(F.PetDietText()=="Pet eats: Fruit, Fungus")
InCombatLockdown=function() return true end
C_PetInfo.GetPetFoodTypes=function() error("restricted pet API") end
assert(F.PetDietText():find("combat"))
InCombatLockdown=function() return false end
UnitExists=function() return false end
assert(F.PetDietText():find("summon"))
F.reason="Pet is happy"; F.bagsDirty=false; F.food=nil; F.pendingItems=false; F.lockedFood=false
assert(F.NoFoodTint("hidden"))
F.pendingItems=true; assert(not F.NoFoodTint("hidden"))
F.pendingItems=false; F.food={}; assert(not F.NoFoodTint("food"))
assert(F.NoFoodTint("nofood"))
print("PASS: pet diet formats, unavailable states, red no-food tint and reset")
