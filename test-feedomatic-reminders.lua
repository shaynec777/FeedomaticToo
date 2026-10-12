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
