local F={db={},Print=function() end}
local widgets={}
local function widget()
    local w={scripts={},shown=false,text='',lines={}}
    setmetatable(w,{__index=function(_,k)
        if k=='HunterToolsWeaponAdded' then return nil end
        if k=='CreateFontString' then return widget end
        if k:match('^[A-Z]') then return function() end end
    end})
    function w:SetScript(e,fn) self.scripts[e]=fn end
    function w:HookScript(e,fn) self.scripts[e]=fn end
    function w:SetText(v) self.text=v end
    function w:SetChecked(v) self.checked=v end
    function w:GetChecked() return self.checked end
    function w:SetEnabled(v) self.enabled=v end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:AddLine(text) self.lines[#self.lines+1]=text end
    widgets[#widgets+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
GameTooltip=widget();ItemRefTooltip=widget()
local post
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn) assert(kind==0);post=fn end};Enum={TooltipDataType={Item=0}}
local combat=false;local level=25;local now=100
InCombatLockdown=function() return combat end;GetTime=function() return now end
GetLocale=function() return 'enUS' end
UnitClass=function() return 'Hunter','HUNTER' end
UnitLevel=function() return level end
local current='item:1001:32:0:0:0:0:0:0'
local candidate='item:1002:30:0:0:0:0:17:99'
GetInventoryItemLink=function() return current end
local ammoID=2519;GetInventoryItemID=function() return ammoID end
local remaining=100
local rows={
 [1001]={min=10,max=20,speed=2,ilvl=20,required=10,sub=3,stats={}},
 [1002]={min=15,max=25,speed=3,ilvl=30,required=20,sub=3,stats={ITEM_MOD_AGILITY_SHORT=5,ITEM_MOD_ATTACK_POWER_SHORT=7,ITEM_MOD_RANGED_ATTACK_POWER_SHORT=7}},
 [1003]={min=10,max=20,speed=3,ilvl=30,required=20,sub=3,stats={}},
 [1004]={min=20,max=40,speed=2.5,ilvl=30,required=20,sub=2,stats={}},
 [1005]={min=10,max=20,speed=2,ilvl=20,required=10,sub=3,stats={ITEM_MOD_HASTE_RATING_SHORT=10}},
 [1006]={min=10,max=20,speed=2,ilvl=20,required=10,sub=3,stats={ITEM_MOD_INTELLECT_SHORT=8}},
 [1007]={min=10,max=20,speed=2,ilvl=20,required=10,sub=3,stats={ITEM_MOD_CRIT_RATING_SHORT=4,ITEM_MOD_HIT_RATING_SHORT=3}},
}
local function id(link) return tonumber(link:match('item:(%d+)')) end
local function row(link) return rows[id(link)] end
local infoCalls,tooltipCalls,observed=0,0,nil
C_Item={
 GetItemInfoInstant=function(link) local r=row(link);return id(link),nil,nil,nil,nil,r and 2 or 4,r and r.sub or 0 end,
 GetItemInfo=function(link) infoCalls=infoCalls+1;local r=row(link);return r and 'Weapon '..id(link),link,1,r and r.ilvl,r and r.required end,
 GetItemStats=function(link) return row(link).stats end,
 GetItemCount=function() return remaining end,
}
C_TooltipInfo={GetHyperlink=function(link)
 tooltipCalls=tooltipCalls+1;observed=link
 local r=row(link)
 return {lines={{leftText=('%g - %g Damage'):format(r.min,r.max),rightText=('Speed %.2f'):format(r.speed)}}}
end}
local liveMin,liveMax,liveSpeed=48.4,59.4,2/1.15
UnitRangedDamage=function() return liveSpeed,liveMin,liveMax,0,0,1.1 end
UnitRangedAttackPower=function() return 100,50,-10 end
GetRangedAttackPowerForStat=function(index,value) return (index==2 and 2 or index==4 and 0.25 or 0)*value end
F.AmmoInfo=function() return 'Heavy Shot' end
F.ammoUpgradeCatalog={[2519]={kind=3,dps=3.5}}
assert(loadfile('HunterTools/WeaponCompare.lua'))('test',F)
local function near(a,b) assert(math.abs(a-b)<0.00001,('%s ~= %s'):format(tostring(a),tostring(b))) end
local function build(link) local r,reason=F.BuildWeaponComparison(link);assert(r,reason);return r end
assert(F.WeaponCompareSettings().enabled and F.WeaponCompareSettings().scope=='actual')
F.db.weaponCompare.scope='bad';assert(F.WeaponCompareSettings().scope=='actual')
-- Baseline identity must include scope, ammo, buffs and haste exactly once.
local r=build(current);near(r.min,liveMin);near(r.max,liveMax);near(r.dpsDelta,0);near(r.shotDelta,0)
r=build(candidate)
near(r.apDelta,24)
near(r.min,(15+(164/14+3.5)*3+1+5)*1.1)
near(r.max,(25+(164/14+3.5)*3+1+5)*1.1)
near(r.speed,3/1.15);assert(r.ammoName=='Heavy Shot' and not r.statScalingUnverified)
assert(observed=='item:1002:0:0:0:0:0:17:99','neutralizing enchant must preserve item instance suffix/bonus fields')
local before=tooltipCalls;build(candidate);assert(tooltipCalls==before,'cache avoids repeat tooltip scans')
F.ClearWeaponComparisonCache();build(candidate);assert(tooltipCalls>before)
-- Scope preview replaces the candidate scope and leaves the reference equipped scope alone.
F.WeaponCompareSettings().scope='none';r=build(current);near(r.shotDelta,-2*1.1)
F.WeaponCompareSettings().scope='equipped';r=build(candidate);near(r.scope.damage,2)
F.WeaponCompareSettings().scope=4407;r=build(candidate);near(r.scope.damage,3)
F.WeaponCompareSettings().scope=10548;local result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('level 40',1,true))
assert(F.WeaponScopeAllowed(F.weaponScopes[3],{itemLevel=20},20))
assert(not F.WeaponScopeAllowed(F.weaponScopes[3],{itemLevel=19},20))
assert(not F.WeaponScopeAllowed(F.weaponScopes[3],{itemLevel=30},19))
F.WeaponCompareSettings().scope='actual'
-- A slower weapon can have more damage per shot without more DPS.
r=build('item:1003:0:0:0:0:0:0:0');assert(r.shotDelta>0 and r.dpsDelta<0)
r=build('item:1004:0:0:0:0:0:0:0');assert(r.base.kind~=r.candidate.kind)
-- Query the live client for stat-to-ranged-AP conversions, including talent-dependent Int.
r=build('item:1006:32:0:0:0:0:0:0');near(r.apDelta,2)
local statQuery=GetRangedAttackPowerForStat;GetRangedAttackPowerForStat=nil
r=build(candidate);near(r.apDelta,24);assert(r.statScalingUnverified)
GetRangedAttackPowerForStat=statQuery
-- Use the native rating converter when supported; otherwise flag an omitted change.
CR_HASTE_RANGED=19
GetCombatRatingBonus=function(index) assert(index==19);return 10 end
GetCombatRatingBonusForCombatRatingValue=function(index,value) assert(index==19);return value end
r=build('item:1005:32:0:0:0:0:0:0');near(r.min,liveMin);near(r.speed,liveSpeed*1.1/1.2);assert(not r.hasteUnmodeled)
GetCombatRatingBonusForCombatRatingValue=nil
r=build('item:1005:32:0:0:0:0:0:0');assert(r.hasteUnmodeled)
remaining=0;result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('depleted',1,true))
remaining=100;ammoID=999;result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('verified',1,true));ammoID=2519
local previous=current;current='item:1001:9999:0:0:0:0:0:0';result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('unrecognized',1,true));current=previous
result,reason=F.BuildWeaponComparison('item:1002:9999:0:0:0:0:0:0');assert(not result and reason:find('unrecognized',1,true))
F.WeaponCompareSettings().scope='none';build('item:1002:9999:0:0:0:0:0:0');F.WeaponCompareSettings().scope='actual'
level=10;result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('level 20',1,true));level=25
F.ClearWeaponComparisonCache();GetLocale=function() return 'deDE' end
result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('English',1,true));GetLocale=function() return 'enUS' end
-- Missing data, invalid arithmetic and secret values suppress estimates safely.
local savedStats=C_Item.GetItemStats;C_Item.GetItemStats=function() return nil end
result,reason=F.BuildWeaponComparison(candidate);assert(not result and reason:find('loading',1,true));C_Item.GetItemStats=savedStats
liveSpeed=0;result=F.BuildWeaponComparison(candidate);assert(not result);liveSpeed=2/1.15
local secret={};issecretvalue=function(v) return v==secret end
UnitRangedAttackPower=function() return 100,secret,-10 end
assert(not F.BuildWeaponComparison(candidate))
UnitRangedAttackPower=function() return 100,50,-10 end
-- Hook integration, copy-deduplication, other tooltip exclusion, combat and enable gates.
GameTooltip.GetItem=function() return 'Weapon',candidate end
post(GameTooltip);assert(GameTooltip.HunterToolsWeaponAdded and #GameTooltip.lines>5)
local text=table.concat(GameTooltip.lines,'\n');assert(text:find('Heavy Shot',1,true) and text:find('Scope (as attached)',1,true) and text:find('Before armor/misses/crit',1,true))
before=#GameTooltip.lines;post(GameTooltip);assert(#GameTooltip.lines==before)
GameTooltip.scripts.OnTooltipCleared(GameTooltip);GameTooltip.lines={};combat=true;before=infoCalls;post(GameTooltip);assert(#GameTooltip.lines==0 and infoCalls==before)
combat=false;F.WeaponCompareSettings().enabled=false;post(GameTooltip);assert(#GameTooltip.lines==0)
F.WeaponCompareSettings().enabled=true;local other=widget();other.GetItem=GameTooltip.GetItem;post(other);assert(#other.lines==0)
GameTooltip.GetItem=function() return 'Armor','item:999:0' end;post(GameTooltip);assert(#GameTooltip.lines==0)
GameTooltip.GetItem=function() return 'Weapon','item:1007:32:0:0:0:0:0:0' end;post(GameTooltip)
text=table.concat(GameTooltip.lines,'\n');assert(text:find('+4 crit, +3 hit',1,true))
F.MenuText=function(parent,text) local t=widget();t:SetText(text);return t end
F.FinishMenu=function() end;F.HideConfigPages=function() if F.weaponSettingsPanel then F.weaponSettingsPanel:Hide() end end
F.OpenConfig=function() F.returned=true end
assert(loadfile('HunterTools/WeaponCompareUI.lua'))('test',F)
level=15;F.OpenWeaponComparisonSettings();local p=F.weaponSettingsPanel
assert(p.shown and p.enabled.checked and p.scopeChoices[4406].enabled and not p.scopeChoices[4407].enabled)
p.scopeChoices.none.scripts.OnClick();assert(F.WeaponCompareSettings().scope=='none' and p.scopeChoices.none.checked and not p.scopeChoices.actual.checked)
p.enabled.checked=false;p.enabled.scripts.OnClick(p.enabled);F.OpenWeaponComparisonSettings();assert(not p.enabled.checked)
level=40;p.scripts.OnEvent();assert(p.scopeChoices[10548].enabled)
combat=true;p:Hide();F.OpenWeaponComparisonSettings();assert(not p.shown)
print('PASS: live baseline identity, AP/agility/intellect stat swap, scope replacement, level/item-level gates, speed/DPS tradeoffs, native haste conversion, unknown scopes, ammo depletion, exact item cache, English/missing/secret data guards, tooltip hooks/deduplication, saved settings UI and combat gates')
