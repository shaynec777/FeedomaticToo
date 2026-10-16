local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F)
F.LoadSettings()
InCombatLockdown=function() return false end
local guid,name,family='guid-1','Smiley','Raptor'
UnitGUID=function() return guid end;UnitName=function() return name end;UnitCreatureFamily=function() return family end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
F.FoodLists();guid='guid-2';F.FoodLists();assert(count(F.db.petFoodLists)==1,'summoning saves one default profile across GUID changes')
local raptor=F.FoodLists(true);raptor.blacklist[1]=true;local raptorKey=F.CurrentPetKey()
guid='guid-3';assert(F.FoodLists()==raptor and count(F.db.petFoodLists)==1,'summons must reuse name/family rules')
family='Tallstrider';guid='bird-1';local bird=F.FoodLists(true);local birdKey=F.CurrentPetKey();assert(bird~=raptor and not bird.blacklist[1],'same name, different family must not share rules')
F.db.petFoodLists.oldA={name='Smiley',whitelist={[2]=true},blacklist={}}
F.db.petFoodLists.oldB={name='Smiley',whitelist={},blacklist={[3]=true}}
assert(not F.FoodLists().whitelist[2],'unknown-family rules must not be applied by name')
local groups=F.SavedPetListGroups();assert(#groups==3,'legacy duplicate names should have one cleanup group')
local legacy
for _,g in ipairs(groups) do if g.family=='Family unknown (legacy)' then legacy=g end end
assert(legacy and #legacy.keys==2 and legacy.active)
assert(not F.DeleteSavedPetLists(legacy.keys),'protect unknown-family records with current pet name')
assert(not F.DeleteSavedPetLists({raptorKey,birdKey}));assert(F.db.petFoodLists[raptorKey],'bulk rejection must be atomic')
guid=nil;assert(F.DeleteSavedPetLists(legacy.keys));assert(not F.db.petFoodLists.oldA and not F.db.petFoodLists.oldB)
assert(F.DeletePetLists(raptorKey));guid='guid-4';family='Raptor';F.FoodLists();assert(F.db.petFoodLists[raptorKey] and not F.FoodLists().blacklist[1],'summoning after deletion creates a fresh default list')
-- Exact legacy GUID may safely acquire family metadata without touching others.
F.db.petFoodLists[guid]={name='Smiley',whitelist={},blacklist={[9]=true}}
local migrated=F.FoodLists();assert(migrated.blacklist[9] and migrated.family=='Raptor' and not F.db.petFoodLists[guid] and F.db.petFoodLists[raptorKey]==migrated)
-- Test manager buttons and two-click confirmations against populated data.
local frames={}
local function widget()
 local w={scripts={}};setmetatable(w,{__index=function(_,key) if key=='CreateFontString' then return widget end;if key:match('^[A-Z]') then return function() end end end})
 function w:SetScript(e,f) self.scripts[e]=f end
 function w:SetText(s) self.text=s end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent={};F.Print=function() end
assert(loadfile('HunterTools/FoodList.lua'))('test',F)
guid=nil;F.OpenPetLists();local p=F.petListPanel
local selected,all,nextButton
for _,w in ipairs(frames) do
 if w.text=='Delete selected lists' then selected=w elseif w.text=='Delete all inactive lists' then all=w elseif w.text=='Next saved pet' then nextButton=w end
end
local before=count(F.db.petFoodLists);selected.scripts.OnClick();assert(count(F.db.petFoodLists)==before)
selected.scripts.OnClick();assert(count(F.db.petFoodLists)==before-1 and p.result.text:find('deleted',1,true))
F.OpenPetLists();assert(count(F.db.petFoodLists)==before-1,'reopening must not restore deleted defaults')
local beforeAll=count(F.db.petFoodLists);all.scripts.OnClick();assert(count(F.db.petFoodLists)==beforeAll);all.scripts.OnClick();assert(count(F.db.petFoodLists)==0)
guid='guid-5';F.FoodLists();F.OpenPetLists();assert(count(F.db.petFoodLists)==1 and p.group)
F.sessionPetFoodLists=nil;F.petFoodGuidProfiles=nil;F.LoadSettings();F.FoodLists();assert(count(F.db.petFoodLists)==1,'reload must reuse the single default profile')
-- Defaults allow every edible food; protections and explicit restrictions win.
F.FoodProtectionReason=function(id) if id==99 then return 'protected' end end
assert(F.FoodAllowed(10) and F.FoodAllowed(11) and not F.FoodAllowed(99))
F.FoodLists().blacklist[10]=true;assert(not F.FoodAllowed(10))
F.FoodLists().whitelist[11]=true;assert(F.FoodAllowed(11) and not F.FoodAllowed(12))
-- Missing family must not create a GUID profile while unit details settle.
family=nil;guid='settling';F.FoodLists();assert(not F.db.petFoodLists[guid])
family='Raptor';F.FoodLists();assert(count(F.db.petFoodLists)==1)
InCombatLockdown=function() return true end
UnitGUID=function() error('restricted unit query') end
assert(not F.DeleteSavedPetLists({'bad'}));assert(not F.DeletePetLists('bad'))
print('PASS: name/family identity, session GUID changes, legacy safety/grouping, default creation/reuse and food protections, selected/bulk confirmations, UI refresh and combat guard')
