local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F)
assert(loadfile('HunterTools/QuestFood.lua'))('test',F)
assert(loadfile('HunterTools/FoodList.lua'))('test',F)
HunterToolsDB={}; UnitGUID=nil; UnitName=nil
InCombatLockdown=function() return false end
F.LoadSettings(); assert(F.db.protectQuestFood)
local names={[1]='Raw Meat',[2]='Cooked Raw Meat',[3]='Fish',[4]='Bread'}
F.foodCatalog={}; for id,name in pairs(names) do F.foodCatalog[id]={name=name} end
C_Item={GetItemInfo=function(id) return names[id],'item:'..id,1,10 end}
C_PetInfo={CanPetEatItem=function() return true end}
local slots={{itemID=1,stackCount=20},{itemID=2,stackCount=5},{itemID=1,stackCount=10},{itemID=3,stackCount=3},{itemID=4,stackCount=2}}
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
local flags={[4]={isQuestItem=true},[5]={isQuestItem=false,questID=888,isActive=false}}
C_Container={GetContainerNumSlots=function() return #slots end,
    GetContainerItemInfo=function(_,slot) return slots[slot] end,
    GetContainerItemQuestInfo=function(_,slot) return flags[slot] end}
local quests={{title='Bring Meat',questID=101}}
local objectives={[101]={{text='Raw Meat: 20/10',type='item',finished=true,numFulfilled=20,numRequired=10}}}
C_QuestLog={GetNumQuestLogEntries=function() return #quests end,
    GetInfo=function(i) return quests[i] end,
    GetQuestObjectives=function(id) return objectives[id] end}
F.FindFood()
assert(F.QuestFoodReason(1)=='Bring Meat','completed objectives still protected')
-- Live Forever report: count precedes the name, and ordinary cooking food has
-- isQuestItem=false. Reproduce that response without any native-flag fallback.
names[5469]='Strider Meat'; F.foodCatalog[5469]={name='Strider Meat'}
slots[#slots+1]={itemID=5469,stackCount=4}
flags[#slots]={isQuestItem=false,isActive=false}
quests[#quests+1]={title='Restocking the Larders',questID=92553,isCollapsed=true}
objectives[92553]={{text='4/8 Strider Meat',type='item',finished=false,numFulfilled=4,numRequired=8,objectiveType=1}}
F.FindFood()
assert(F.QuestFoodReason(5469)=='Restocking the Larders','live Forever count-first objective protects ordinary food')
assert(not F.FoodAllowed(5469),'protected food excluded from feeding')
assert(F.foodCount==7,'protected food excluded from supply count')
objectives[92553][1].text='8/8 Strider Meat'
objectives[92553][1].finished=true
F.FindFood(); assert(F.QuestFoodReason(5469),'completed count-first objective remains protected')
slots[#slots]=nil; quests[#quests]=nil; flags[6]=nil
F.FindFood()
assert(F.QuestFoodReason(3),'native bag flag covers unlisted/collapsed objective')
assert(not F.QuestFoodReason(2),'whole-name matching, not substring')
assert(not F.QuestFoodReason(4),'unaccepted quest starter is not blocked')
assert(F.foodCount==7 and F.food.id==4,'all quest stacks excluded from selection and count')
assert(F.CatalogMatches(1,30,{blocked=true},true),'automatic protection in Blocked filter')
assert(not F.db.blacklist[1],'automatic protection does not change lists')
F.db.whitelist[1]=true; F.FindFood(); assert(not F.food,'whitelist cannot override')
F.db.protectQuestFood=false; F.LoadSettings(); assert(not F.db.protectQuestFood,'off persists')
F.FindFood(); assert(F.food.id==1 and F.foodCount==30,'toggle off restores eligibility')
F.db.blacklist[1]=true; F.FindFood(); assert(not F.food,'manual blacklist still wins')
F.db.whitelist={}; F.db.blacklist={[2]=true}; F.db.protectQuestFood=true
quests={}; flags={}; F.FindFood()
assert(not F.QuestFoodReason(1) and F.foodCount==35,'turn-in/abandonment releases protection')
assert(F.db.blacklist[2],'manual blocks survive quest removal')
-- Classic API fallback and completed objective text.
C_QuestLog=nil
GetNumQuestLogEntries=function() return 2 end
GetQuestLogTitle=function(i) if i==1 then return 'Zone',1,nil,true end return 'Classic quest',1,nil,false,false,1,nil,202 end
GetNumQuestLeaderBoards=function() return 2 end
GetQuestLogLeaderBoard=function(i) if i==1 then return 'Bread: 2/2','item',true end return 'Raw Meat: 1/1','monster',true end
F.ScanQuestFood(); assert(F.QuestFoodReason(4)=='Classic quest' and not F.QuestFoodReason(1))
F.Print=function() end
F.DebugQuestFood()
assert(F.db.questDebug and table.concat(F.db.questDebug,'\n'):find('Classic quest',1,true),'diagnostic captures live quest data')
InCombatLockdown=function() return true end
GetNumQuestLogEntries=function() error('quest API in combat') end
C_Container.GetContainerNumSlots=function() error('bag API in combat') end
F.ScanQuestFood(); F.FindFood()
print('PASS: quest protection, completed objectives, all stacks, filters, whitelist, toggle persistence, quest removal, Classic fallback, combat guard')
