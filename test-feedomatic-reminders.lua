local F=...
InCombatLockdown=function() return false end
F.db.enabled=true; F.db.textReminder='both'; F.db.reminderMinutes=3
local now=1000
GetTime=function() return now end
local chats,announcements={},{}
F.Print=function(message) table.insert(chats,message) end
RaidWarningFrame={}
RaidNotice_AddMessage=function(frame,message) assert(frame==RaidWarningFrame); table.insert(announcements,message) end
F.food={}; F.lastTextReminder=nil; F.reminderPet=nil
UnitGUID=function() return 'pet-A' end
F.CheckTextReminder('hungry','Content')
assert(#chats==1 and #announcements==1)
now=1179; F.CheckTextReminder('hungry','Content'); assert(#chats==1)
now=1180; F.food=nil; F.pendingItems=false; F.lockedFood=false
F.CheckTextReminder('hungry','Content')
assert(#chats==2 and chats[2]:find('no suitable',1,true))
InCombatLockdown=function() return true end
now=1360; F.CheckTextReminder('hungry','Content'); assert(#chats==2)
InCombatLockdown=function() return false end
F.CheckTextReminder('hidden','Pet is already being fed'); assert(#chats==2)
F.CheckTextReminder('hungry','Content'); assert(#chats==3)
F.db.reminderMinutes=0; now=2000; F.CheckTextReminder('hungry','Content'); assert(#chats==3)
F.CheckTextReminder('hidden','Pet is happy')
F.CheckTextReminder('hungry','Unhappy'); assert(#chats==4)
UnitGUID=function() return 'pet-B' end
F.CheckTextReminder('hungry','Content'); assert(#chats==5)
F.db.textReminder='off'; now=3000; F.CheckTextReminder('hungry','Content'); assert(#chats==5)
F.db.textReminder='chat'; F.db.reminderMinutes=0.5
F.CheckTextReminder('hungry','Content'); assert(#chats==6 and #announcements==5)
now=3029; F.CheckTextReminder('hungry','Content'); assert(#chats==6)
now=3030; F.CheckTextReminder('hungry','Content'); assert(#chats==7)
F.db.enabled=false; now=3060; F.CheckTextReminder('hungry','Content'); assert(#chats==7)
F.db.textReminder='screen'; RaidNotice_AddMessage=nil
F.ShowTextReminder(true); assert(#chats==8,'screen fallback to private chat')
F.db.reminderMinutes='garbage'; F.LoadSettings(); assert(F.db.reminderMinutes==3)
F.db.reminderMinutes=0.5; F.LoadSettings(); assert(F.db.reminderMinutes==0.5)
print('PASS: reminder modes, intervals, combat and feeding suppression, no-food text, pet changes, fallback and saved settings')

UnitName=function(unit) assert(unit=='pet'); return 'Fang' end
F.food={}; assert(F.HungerMessage()=='Fang is hungry.')
F.food=nil; assert(F.HungerMessage():find('Fang is hungry - no suitable',1,true))
UnitName=function() return 'Snowclaw' end
assert(F.HungerMessage():find('Snowclaw is hungry',1,true),'current name is read each time')
F.db.textReminder='chat'; F.ShowTextReminder(true)
assert(chats[#chats]=='Snowclaw is hungry. (Test reminder)')
for _,name in ipairs({'','   '}) do
    UnitName=function() return name end
    assert(F.HungerMessage():find('Your pet is hungry',1,true))
end
UnitName=function() return nil end
assert(F.HungerMessage():find('Your pet is hungry',1,true))
InCombatLockdown=function() return true end
UnitName=function() error('pet name must not be queried in combat') end
assert(F.ReminderPetName()=='Your pet')
InCombatLockdown=function() return false end
UnitName=nil
print('PASS: named reminders, pet switches, test message, missing-name fallback and combat guard')

F.db.enabled=true; F.db.lowFoodWarning=true; F.db.lowFoodThreshold=10
F.pendingItems=false; F.lockedFood=false; F.foodCount=11
UnitName=function() return 'Fang' end; UnitGUID=function() return 'supply-A' end
local before=#chats
F.CheckLowFood('hidden','Pet is happy'); assert(#chats==before)
F.foodCount=10; F.CheckLowFood('hidden','Pet is happy')
assert(#chats==before+1 and chats[#chats]:find('Fang has 10 food items left',1,true))
F.foodCount=2; F.CheckLowFood('hungry','Content'); assert(#chats==before+1)
F.foodCount=20; F.CheckLowFood('hungry','Content')
F.foodCount=1; F.CheckLowFood('hungry','Content')
assert(#chats==before+2 and chats[#chats]:find('1 food item left',1,true))
UnitGUID=function() return 'supply-B' end; F.foodCount=0
F.pendingItems=true; F.CheckLowFood('hungry','Content'); assert(#chats==before+2)
F.pendingItems=false; F.lockedFood=true; F.CheckLowFood('hungry','Content'); assert(#chats==before+2)
F.lockedFood=false; F.CheckLowFood('hidden','Pet is already being fed'); assert(#chats==before+2)
InCombatLockdown=function() return true end
F.CheckLowFood('hungry','Content'); assert(#chats==before+2)
InCombatLockdown=function() return false end
F.CheckLowFood('hungry','Content'); assert(#chats==before+3)
F.db.lowFoodWarning=false; UnitGUID=function() return 'supply-C' end
F.CheckLowFood('hungry','Content'); assert(#chats==before+3)
F.db.showFoodCount=true; F.reason='Pet is happy'; F.foodCount=8
assert(F.SupplyCountText()=='8'); F.pendingItems=true; assert(F.SupplyCountText()=='8+')
F.db.showFoodCount=false; assert(F.SupplyCountText()=='')
F.db.showFoodCount=true; F.reason='No pet'; F.mode='hidden'; assert(F.SupplyCountText()=='')
F.db.lowFoodThreshold=-1; F.LoadSettings(); assert(F.db.lowFoodThreshold==10)
print('PASS: supply thresholds, restock reset, pet changes, suppression, toggles and count display')

F.db.whitelist={}; F.db.blacklist={[99]=true}; F.db.petFoodLists={}
UnitGUID=function() return 'pet-one' end; UnitName=function() return 'Fang' end
UnitCreatureFamily=function() return 'Wolf' end
local one=F.FoodLists(true); local oneKey=F.CurrentPetKey();assert(one.name=='Fang' and one.blacklist[99])
one.blacklist[1]=true; one.whitelist[2]=true
assert(not F.FoodAllowed(1) and F.FoodAllowed(2) and not F.FoodAllowed(3))
UnitGUID=function() return 'pet-two' end; UnitName=function() return 'Fang' end
UnitCreatureFamily=function() return 'Cat' end
local two=F.FoodLists(true);local twoKey=F.CurrentPetKey();assert(two~=one and not two.blacklist[1] and not two.whitelist[2])
two.whitelist[3]=true; assert(F.FoodAllowed(3) and not F.FoodAllowed(2))
UnitGUID=function() return 'pet-one' end; UnitName=function() return 'Renamed Fang' end
UnitCreatureFamily=function() return 'Wolf' end
assert(F.FoodLists().name=='Renamed Fang' and F.FoodAllowed(2))
assert(not F.DeletePetLists(F.CurrentPetKey()))
assert(F.DeletePetLists(twoKey) and F.db.petFoodLists[twoKey]==nil)
UnitGUID=function() return nil end; assert(F.FoodLists()==F.db)
assert(F.DeletePetLists(oneKey))
InCombatLockdown=function() return true end
UnitGUID=function() error('restricted pet query') end; assert(F.FoodLists()==F.db)
InCombatLockdown=function() return false end; UnitGUID=nil; UnitName=nil
print('PASS: name/family isolation, duplicate names across families, rename-rule preservation, defaults, deletion and combat guard')
