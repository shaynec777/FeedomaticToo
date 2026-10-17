local F={db={ammo={enabled=true}},ammoCounts={},Print=function() end}
local frames={}
local function widget()
 local w={scripts={},text='',shown=false}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' or k=='CreateTexture' then return widget end;if k:match('^[A-Z]') then return function() end end end})
 function w:SetScript(e,f) self.scripts[e]=f end
 function w:SetText(t) self.text=t end
 function w:GetText() return self.text end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 function w:HasFocus() return false end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:IsShown() return self.shown end
 function w:SetShown(v) self.shown=v end
 frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
local level,faction,subclass,equipped,combat,skill=15,'Alliance',3,2516,false,0
InCombatLockdown=function() return combat end
UnitClass=function() return 'Hunter','HUNTER' end
UnitLevel=function() return level end
UnitFactionGroup=function() return faction end
GetInventoryItemID=function(_,slot) assert(not combat);return slot==18 and 999 or equipped end
local function nativeCount(id) return id==equipped and 100 or (F.ammoCounts[id] or 0) end
C_Item={GetItemInfoInstant=function() return 999,nil,nil,nil,nil,2,subclass end,GetItemCount=nativeCount}
GetNumSkillLines=function() return 1 end
GetSkillLineInfo=function() return 'Engineering',false,false,skill end
assert(loadfile('HunterTools/AmmoCatalog.lua'))('test',F)
assert(loadfile('HunterTools/AmmoUpgradeData.lua'))('test',F)
assert(loadfile('HunterTools/AmmoUpgrades.lua'))('test',F)
F.AmmoInfo=function(id) return F.ammoCatalog[id] and F.ammoCatalog[id].name or 'Item '..id end
F.ScanAmmo=function() return true end
local s=F.AmmoUpgradeSettings();assert(not s.enabled and not s.includeEngineered)
s.enabled=true
local c=F.AmmoUpgradeContext(true);local id,best=F.AmmoUpgradeBest(c)
assert(id==2519 and best.dps==3.5)
assert(F.AmmoUpgradeAdvice(c):find('Thurman Mullby',1,true))
s.includeEngineered=true;c=F.AmmoUpgradeContext(true);id,best=F.AmmoUpgradeBest(c);assert(id==8068 and best.dps==4.5)
assert(F.AmmoIsObsolete(2519,c,best) and not F.AmmoIsObsolete(2512,c,best),'no arrow obsolete labels with a gun')
assert(not F.AmmoIsObsolete(3033,c,best),'future ammo must not be obsolete')
s.includeEngineered=false;c=F.AmmoUpgradeContext(true);id,best=F.AmmoUpgradeBest(c);assert(not F.AmmoIsObsolete(2519,c,best),'excluded engineering must not make vendor ammo obsolete')
faction='Horde';c=F.AmmoUpgradeContext(true);assert(F.AmmoUpgradeAdvice(c):find("Trak'gen",1,true))
subclass=18;level=25;equipped=3030;c=F.AmmoUpgradeContext(true);id,best=F.AmmoUpgradeBest(c);assert(id==3030)
assert(F.AmmoUpgradeAdvice(c):find('at level 40',1,true))
level=30;F.ammoCounts={[3464]=60};c=F.AmmoUpgradeContext(true);local advice=F.AmmoUpgradeAdvice(c)
assert(advice:find('Already carrying better ammo',1,true) and advice:find('Feathered Arrow',1,true))
F.ammoCounts={};c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==3030,'unowned quest reward must not outclass vendor ammo')
C_Item.GetItemCount=function(id,bank,charges) assert(bank==false and charges==false);return id==3464 and 20 or 0 end
c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==3464,'native carried total must work for unmonitored ammo')
C_Item.GetItemCount=function() return nil end;assert(F.AmmoUpgradeContext(true)==nil)
C_Item.GetItemCount=nativeCount
level=60;subclass=3;equipped=11284;s.includeEngineered=true;c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==15997,'BoP crafting must not be assumed without the skill')
skill=300;c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==274388)
assert(F.AmmoUpgradeAdvice(c):find('bind-on-pickup',1,true))
level=50;c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==10513)
level=51;s.includeEngineered=false;F.ammoCounts={};c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==11284,'do not assume reputation purchases are accessible')
F.ammoCounts={[19317]=20};c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==19317)
F.db.ammo.enabled=false;assert(F.AmmoUpgradeContext(true)==nil)
F.db.ammo.enabled=true;s.enabled=false;assert(F.AmmoUpgradeContext(true)==nil)
s.enabled=true;combat=true;assert(F.AmmoUpgradeContext(true)==nil);combat=false
assert(F.AmmoUpgradeContext(false)==nil,'unsettled inventory must not produce recommendations or labels')
equipped=99999;assert(F.AmmoUpgradeContext(true)==nil,'unknown current ammo cannot be claimed obsolete')
equipped=nil;subclass=16;assert(F.AmmoUpgradeContext(true)==nil,'thrown weapons do not use ammo')
subclass=2;faction='Neutral';F.ammoCounts={};c=F.AmmoUpgradeContext(true);id=F.AmmoUpgradeBest(c);assert(id==nil,'unaligned characters must not get faction vendor claims')
s.includeEngineered=false;level=10;faction='Alliance';equipped=2512
F.HideConfigPages=function() end;F.OpenAmmoSettings=function() F.backOpened=true end
F.OpenAmmoUpgradeSettings();local p=F.ammoUpgradePanel;assert(p.shown)
p.checks.includeEngineered.checked=true;p.checks.includeEngineered.scripts.OnClick();assert(s.includeEngineered)
p.checks.enabled.checked=false;p.checks.enabled.scripts.OnClick();assert(not s.enabled and p.advice.text:find('Enable upgrade',1,true))
s.enabled=true;combat=true;p.scripts.OnEvent();assert(p.advice.text:find('after combat',1,true))
combat=false
-- Exercise actual AmmoUI list label wiring without altering reminder behavior.
F.db.ammo.minimum=200;F.db.ammo.minutes=5;F.db.ammo.mode='screen';F.db.ammo.selected={};F.db.ammo.minimums={}
F.ResetAmmoReminder=function() end;F.AmmoMinimum=function() return 200 end
assert(loadfile('HunterTools/AmmoUI.lua'))('test',F)
F.OpenAmmoSettings=nil -- replace test stub with real UI method by reloading.
assert(loadfile('HunterTools/AmmoUI.lua'))('test',F)
F.OpenAmmoSettings();local ammoPanel=F.ammoPanel
local found=false
for _,row in ipairs(ammoPanel.rows) do if row.id==2512 then assert(row.text.text:find('|cffff3333[Obsolete]|r',1,true));found=true end end
-- Alphabetic first page may omit Rough Arrow; search it through the actual edit box.
for _,w in ipairs(frames) do if w.scripts.OnTextChanged then w.text='Rough Arrow';w.scripts.OnTextChanged();break end end
assert(ammoPanel.rows[1].id==2512 and ammoPanel.rows[1].text.text:find('[Obsolete]',1,true))
s.enabled=false;ammoPanel:Refresh();assert(not ammoPanel.rows[1].text.text:find('[Obsolete]',1,true))
assert(not F.ammoUpgradeCatalog[19286] and not F.ammoUpgradeCatalog[2514] and not F.ammoUpgradeCatalog[231806])
print('PASS: weapon type, levels, factions, engineering toggle and BoP skill, carried upgrades, future ranks, conditional sources, missing data/combat guards, saved settings, upgrade UI, and red obsolete list wiring')

-- Upgrade notices have their own preferences/cadence and never reuse stock alerts.
assert(s.notify==false and s.minutes==5 and s.mode=='screen')
local now,chat,screen=100,{},{}
GetTime=function() return now end
UnitIsDeadOrGhost=function() return false end
F.Print=function(message) chat[#chat+1]=message end
RaidWarningFrame={};RaidNotice_AddMessage=function(_,message) screen[#screen+1]=message end
s.enabled=true;s.notify=true;s.includeEngineered=false;s.minutes=1;s.mode='screen'
level=10;subclass=2;equipped=2512;faction='Alliance';F.ammoCounts={};F.db.ammo.enabled=true
F.ResetAmmoUpgradeNotifications();F.CheckAmmoUpgradeNotifications();assert(#screen==0,'require stable data twice')
now=105;F.CheckAmmoUpgradeNotifications();assert(#screen==1 and #chat==0)
assert(screen[1]:find('Sharp Arrow',1,true) and screen[1]:find('Thurman Mullby',1,true))
now=164;F.CheckAmmoUpgradeNotifications();assert(#screen==1)
now=165;F.CheckAmmoUpgradeNotifications();assert(#screen==2,'repeat at own configured minute interval')
s.mode='chat';F.ResetAmmoUpgradeNotifications();F.CheckAmmoUpgradeNotifications();now=170;F.CheckAmmoUpgradeNotifications();assert(#chat==1 and #screen==2)
s.mode='both';F.ResetAmmoUpgradeNotifications();F.CheckAmmoUpgradeNotifications();now=175;F.CheckAmmoUpgradeNotifications();assert(#chat==2 and #screen==3)
now=235;combat=true;F.CheckAmmoUpgradeNotifications();assert(#chat==2 and #screen==3)
combat=false;F.CheckAmmoUpgradeNotifications();now=240;F.CheckAmmoUpgradeNotifications();assert(#chat==3 and #screen==4,'resume after combat without consuming the interval')
F.ammoEntryReadyAt=999;now=300;F.CheckAmmoUpgradeNotifications();assert(#screen==4)
F.ammoEntryReadyAt=nil;F.CheckAmmoUpgradeNotifications();now=305;F.CheckAmmoUpgradeNotifications();assert(#screen==5,'wait for zoning readiness')
equipped=2515;now=365;F.CheckAmmoUpgradeNotifications();now=370;F.CheckAmmoUpgradeNotifications();assert(#screen==5,'no future-only upgrade notices')
equipped=2512;F.ammoCounts={[2515]=100};F.ResetAmmoUpgradeNotifications();F.CheckAmmoUpgradeNotifications();now=375;F.CheckAmmoUpgradeNotifications();assert(screen[6]:find('Already in your bags',1,true))
s.notify=false;now=500;F.CheckAmmoUpgradeNotifications();assert(#screen==6 and not F.ammoUpgradeLastNotice)
s.notify=true;s.enabled=false;F.CheckAmmoUpgradeNotifications();assert(#screen==6)
s.enabled=true;F.db.ammo.enabled=false;F.CheckAmmoUpgradeNotifications();assert(#screen==6)
F.db.ammo.enabled=true;UnitIsDeadOrGhost=function() return true end;F.CheckAmmoUpgradeNotifications();assert(#screen==6)
UnitIsDeadOrGhost=function() return false end
F.OpenAmmoUpgradeSettings();p=F.ammoUpgradePanel
p.interval.text='0';p.interval.scripts.OnEnterPressed(p.interval);assert(s.minutes==1 and p.interval.text=='1')
p.interval.text='0.5';p.interval.scripts.OnEnterPressed(p.interval);assert(s.minutes==0.5 and F.db.ammo.minutes==5,'upgrade interval is independent')
p.interval.text='nan';p.interval.scripts.OnEnterPressed(p.interval);assert(s.minutes==0.5)
s.mode='screen';p.destination.scripts.OnClick();assert(s.mode=='chat');p.destination.scripts.OnClick();assert(s.mode=='both');p.destination.scripts.OnClick();assert(s.mode=='screen')
p.checks.notify.checked=false;p.checks.notify.scripts.OnClick();assert(not s.notify)
print('PASS: independent upgrade notification settings, banner/chat/both, stable scans, repeat interval, combat/death/zoning deferral, carried upgrades, no future-only notices, disable gates and validated UI controls')

-- An empty ammo-slot selection is not a usable comparison baseline.
level=15;subclass=3;equipped=8068;faction='Horde';combat=false
s.enabled=true;s.notify=true;s.includeEngineered=true;s.minutes=0.1;s.mode='both'
local stock={[2519]=120}
C_Item.GetItemCount=function(id) return stock[id] or 0 end
F.ammoCounts={[8068]=100,[2519]=120} -- simulate a stale positive bag snapshot
c=F.AmmoUpgradeContext(true);assert(c.depleted and c.counts[8068]==0 and c.baselineID==2519 and c.current.dps==3.5)
local depletedAdvice=F.AmmoUpgradeAdvice(c)
assert(depletedAdvice:find('Equipped ammo depleted: Crafted Heavy Shot (0 left)',1,true))
assert(depletedAdvice:find('Available in bags: Heavy Shot',1,true) and depletedAdvice:find('+1.0 vs available ammo',1,true))
assert(not depletedAdvice:find('Already carrying better ammo: Crafted Heavy Shot',1,true))
F.ResetAmmoUpgradeNotifications();local beforeChat,beforeScreen=#chat,#screen
now=1000;F.CheckAmmoUpgradeNotifications();now=1005;F.CheckAmmoUpgradeNotifications()
assert(#chat==beforeChat+1 and #screen==beforeScreen+1)
assert(chat[#chat]:find('Equipped ammo depleted',1,true) and chat[#chat]:find('Equip Heavy Shot',1,true) and chat[#chat]:find('Ammo upgrade: Crafted Heavy Shot',1,true))
-- Empty selected ammo still warns even if no upgrade passes the engineering filter.
s.includeEngineered=false;F.ResetAmmoUpgradeNotifications();now=1010;F.CheckAmmoUpgradeNotifications();now=1015;F.CheckAmmoUpgradeNotifications()
assert(chat[#chat]:find('Equipped ammo depleted',1,true) and not chat[#chat]:find('Ammo upgrade:',1,true))
-- Replenishing the selected ammo restores it as the actual baseline.
stock[8068]=30;s.includeEngineered=true;c=F.AmmoUpgradeContext(true)
assert(not c.depleted and c.baselineID==8068 and c.current.dps==4.5)
F.ResetAmmoUpgradeNotifications();beforeChat=#chat;now=1020;F.CheckAmmoUpgradeNotifications();now=1025;F.CheckAmmoUpgradeNotifications();assert(#chat==beforeChat)
-- No arrow stack or too-high-level bullet can stand in for usable carried ammo.
stock={[2512]=200,[3033]=100};F.ammoCounts={};c=F.AmmoUpgradeContext(true)
assert(c.depleted and not c.current and not c.baselineID)
assert(F.AmmoUpgradeAdvice(c):find('No usable compatible ammo left',1,true))
assert(F.AmmoUpgradeContext(false)==nil)
F.ammoEntryReadyAt=9999;assert(F.AmmoUpgradeContext(true)==nil);F.ammoEntryReadyAt=nil
C_Item.GetItemCount=function() return nil end;assert(F.AmmoUpgradeContext(true)==nil,'missing counts must not be treated as depletion')
print('PASS: depleted ammo-slot selection, authoritative remaining stock, carried baseline and equip advice, upgrade and depletion notifications, engineered filter, replenishment, incompatible/future stock and loading guards')
