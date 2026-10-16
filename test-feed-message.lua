local F={db={}}
assert(loadfile('HunterTools/Core.lua'))('test',F)
local now,pet=100,'bird'
GetTime=function() return now end
time=function() return 1000 end
InCombatLockdown=function() return false end
UnitGUID=function() return pet end
UnitName=function() return 'Tallstrider' end
IsShiftKeyDown=function() return false end
F.Refresh=function() end
F.Disarm=function() end
F.mode='food'; F.food={name='Tough Jerky'}
local messages={};F.Print=function(s) messages[#messages+1]=s end
F.PreClick(nil,'LeftButton');assert(#messages==0,'click is not proof of success')
F.food={name='Changed bag item'}
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL)
assert(messages[1]=='Fed Tallstrider a delicious Tough Jerky','use food captured before synchronous bag changes')
assert(F.db.petLastFeeds.bird.food=='Tough Jerky' and F.db.petLastFeeds.bird.at==1000,'persist the confirmed feeding for pet status')
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL);assert(#messages==1,'one notice per feeding')
F.PreClick(nil,'LeftButton');F.HandleFeedCastEvent('UNIT_SPELLCAST_FAILED','player',F.FEED_SPELL)
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL);assert(#messages==1,'failed feeding must not announce')
F.PreClick(nil,'LeftButton');F.HandleFeedCastEvent('UNIT_SPELLCAST_INTERRUPTED','player',F.FEED_SPELL);assert(not F.pendingFeedNotice)
F.PreClick(nil,'RightButton');F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL);assert(#messages==1)
IsShiftKeyDown=function() return true end
F.PreClick(nil,'LeftButton');assert(not F.pendingFeedNotice)
IsShiftKeyDown=function() return false end
F.mode='hidden';F.PreClick(nil,'LeftButton');assert(not F.pendingFeedNotice)
F.mode='food';F.PreClick(nil,'LeftButton');pet='new-pet'
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL);assert(#messages==1,'do not misattribute pet swap')
F.PreClick(nil,'LeftButton');now=106
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL);assert(#messages==1,'discard expired attempts')
F.PreClick(nil,'LeftButton');F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','pet',F.FEED_SPELL)
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',123);assert(#messages==1 and F.pendingFeedNotice)
F.HandleFeedCastEvent('UNIT_SPELLCAST_SUCCEEDED','player',F.FEED_SPELL);assert(#messages==2)
print('PASS: confirmed feeding text, snapshot, duplicates, failed/interrupted/blocked actions, pet swap, expiry and unrelated events')
