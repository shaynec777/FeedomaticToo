local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F)
F.LoadSettings()
local now=0
GetTime=function() return now end
InCombatLockdown=function() return false end
UnitGUID=function() return 'tallstrider' end
UnitName=function() return 'Tallstrider' end
local count,slots,uncached=0,0,false
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() return slots end,GetContainerItemInfo=function() if count>0 then return {itemID=1,stackCount=count} end end}
C_Item={GetItemInfo=function() if not uncached then return 'Food','link',1,10 end end}
C_PetInfo={CanPetEatItem=function() return true end}
F.FoodAllowed=function() return true end
local warnings={}
F.Print=function(s) warnings[#warnings+1]=s end
F.db.enabled=true; F.db.lowFoodWarning=true; F.db.lowFoodThreshold=10
F.QueueFoodEntryScan()
local function scan() F.FindFood(); F.CheckLowFood('hidden','Pet is happy') end
scan();assert(#warnings==0)
now=11;scan();now=20;scan();assert(F.foodEntryPending and #warnings==0,'zero backpack slots are still loading')
slots=1;count=0;scan();now=21;count=20;scan();now=23;scan()
assert(not F.foodEntryPending and #warnings==0,'recovered food must prevent false login alert')
now=100;F.QueueFoodEntryScan();count=0;now=110;scan();now=111;scan();assert(#warnings==0)
now=112;scan();assert(not F.foodEntryPending and #warnings==1,'real empty inventory still warns after confirmation')
now=200;F.QueueFoodEntryScan();count=2;now=210;uncached=true;scan();now=215;scan();assert(F.foodEntryPending and #warnings==1)
uncached=false;now=216;scan();now=217;F.foodEntrySnapshot=nil;scan();now=218;scan();assert(F.foodEntryPending)
now=219;scan();assert(not F.foodEntryPending)
-- Force fresh scans on the ticker even without another bag event.
F.QueueFoodEntryScan();now=300;count=20
F.GetState=function() return 'hidden','Pet is happy' end
F.button={Hide=function() end};F.Disarm=function() end;F.Render=function() end
F.CheckHungerSound=function() end;F.FoodLists=function() end
F.Refresh();assert(F.foodEntryPending)
now=302;F.Refresh();assert(not F.foodEntryPending and F.foodCount==20)
assert(#warnings==1)
print('PASS: login empty bags, recovered food, genuine exhaustion, uncached items, quiet-period reset and ticker rescans')
