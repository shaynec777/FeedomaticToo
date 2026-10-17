local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F)
F.LoadSettings()
local pet,now,combat='new-wolf',100,false
UnitGUID=function() return pet end;GetTime=function() return now end
UnitName=function() return 'Wolf' end
InCombatLockdown=function() return combat end
F.db.enabled=true;F.db.textReminder='both';F.db.reminderMinutes=1
local messages,sounds={},0
F.Print=function(s) messages[#messages+1]=s end
F.PlayHungerSound=function() sounds=sounds+1 end
F.foodEntryPending=true;F.pendingItems=true;F.food=nil
F.CheckTextReminder('hungry','Unhappy')
assert(#messages==1 and messages[1]:find('Wolf is hungry',1,true) and messages[1]:find('still loading',1,true) and not messages[1]:find('no suitable',1,true))
F.CheckTextReminder('hungry','Unhappy');assert(#messages==1)
now=160;F.CheckTextReminder('hungry','Unhappy');assert(#messages==2)
F.CheckHungerSound('hungry','Unhappy');F.CheckHungerSound('hungry','Unhappy');assert(sounds==1)
pet='another-new-wolf';now=161
F.CheckHungerSound('hungry','Unhappy');assert(sounds==2,'new pet needs its own initial sound')
F.CheckTextReminder('hungry','Unhappy');assert(#messages==3,'new pet needs its own initial text')
F.GetState=function() return 'hungry','Unhappy' end
assert(F.HungerAlertStatus():find('Next reminder in 60 seconds',1,true))
F.GetState=function() return 'hidden','Learn Feed Pet first' end
assert(F.HungerAlertStatus():find('Learn Feed Pet first',1,true))
combat=true;now=1000;F.CheckTextReminder('hungry','Unhappy');F.CheckHungerSound('hungry','Unhappy');assert(#messages==3 and sounds==2)
assert(F.HungerAlertStatus():find('combat',1,true))
combat=false;F.db.enabled=false;assert(F.HungerAlertStatus():find('disabled',1,true))
F.CheckTextReminder('hungry','Unhappy');assert(#messages==3)
print('PASS: hungry alerts survive inventory loading, no false stock claim, repeat intervals, new-pet sound/text reset, combat and disabled guards, pause diagnostics')
