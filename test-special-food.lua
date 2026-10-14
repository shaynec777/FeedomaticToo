local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F)
assert(loadfile('HunterTools/SpecialFood.lua'))('test',F)
F.db={whitelist={},blacklist={}}
InCombatLockdown=function() return false end
UnitGUID=nil
C_Item={GetItemInfoInstant=function(id) return id,nil,nil,nil,nil,id==1 and 7 or 0,8 end}
C_TooltipInfo={GetItemByID=function(id) return {lines={{leftText=id==2 and 'You will become well fed and gain strength.' or 'Restores health.'}}} end}
F.SpecialFoodSettings(); assert(not F.db.protectBuffFood and not F.db.protectCookingFood)
F.db.protectBuffFood=true; F.db.protectCookingFood=true
F.SpecialFoodSettings(); assert(F.db.protectBuffFood and F.db.protectCookingFood,'explicit opt-in persists')
assert(F.SpecialFoodReason(1)=='Cooking ingredient')
assert(F.SpecialFoodReason(2)=='Buff food')
assert(F.SpecialFoodReason(3)==nil)
F.db.whitelist[1]=true; assert(not F.FoodAllowed(1),'whitelist must not bypass protection')
F.db.protectCookingFood=false; assert(F.FoodAllowed(1))
F.db.protectBuffFood=false; assert(F.SpecialFoodReason(2)==nil)
F.db.protectBuffFood=true; C_TooltipInfo.GetItemByID=function() return nil end
assert(F.SpecialFoodReason(2)==nil,'uncached tooltip is not proof of buff food')
F.reason='Pet is dead'; F.mode='hidden'; assert(F.TooltipStatus()=='Revive your pet before feeding.')
F.reason='Pet is already being fed'; assert(F.TooltipStatus():find('Feeding in progress',1,true))
print('PASS: special food categories, buff tooltip, protection toggles, whitelist and feeding explanations')
