local _,F=...
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function number(v) return public(v) and type(v)=='number' and v==v and math.abs(v)<10000000 end
local function query(fn,...)
    if type(fn)~='function' then return end
    local function pack(...) return {n=select('#',...),...} end
    local values=pack(pcall(fn,...))
    if not values[1] then return end
    for i=2,values.n do if not public(values[i]) then values[i]=nil end end
    return unpack(values,2,values.n)
end
F.weaponScopes={
    {id=4405,name='Crude Scope',damage=1,level=5,enchant=30},
    {id=4406,name='Standard Scope',damage=2,level=10,enchant=32},
    {id=4407,name='Accurate Scope',damage=3,level=20,enchant=33},
    {id=10546,name='Deadly Scope',damage=5,level=30,enchant=663},
    {id=10548,name='Sniper Scope',damage=7,level=40,enchant=664},
}
local scopesByEnchant,scopesByID={},{}
for _,s in ipairs(F.weaponScopes) do scopesByEnchant[s.enchant]=s;scopesByID[s.id]=s end
function F.WeaponCompareSettings()
    if type(F.db.weaponCompare)~='table' then F.db.weaponCompare={} end
    local s=F.db.weaponCompare
    if type(s.enabled)~='boolean' then s.enabled=true end
    if s.scope~='actual' and s.scope~='none' and s.scope~='equipped' and not scopesByID[s.scope] then s.scope='actual' end
    return s
end
local function clean(text)
    if not public(text) or type(text)~='string' then return '' end
    return text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|T.-|t','')
end
function F.WeaponScopeOnLink(link)
    if not public(link) or type(link)~='string' then return end
    local enchant=link:match('item:%d+:(%d*)')
    enchant=tonumber(enchant) or 0
    if enchant==0 then return {name='No scope',damage=0,enchant=0} end
    return scopesByEnchant[enchant]
end
function F.WeaponScopeAllowed(scope,weapon,level)
    -- Conservative Classic minimum weapon-item-level rule; application is a preview.
    return number(level) and level>=scope.level and number(weapon.itemLevel) and weapon.itemLevel>=scope.level
end
local itemCache={};local cacheSize=0
function F.ClearWeaponComparisonCache() itemCache={};cacheSize=0 end
function F.ReadComparisonWeapon(link)
    if not public(link) or type(link)~='string' then return end
    local _,_,_,_,_,class,subclass=query(C_Item and C_Item.GetItemInfoInstant,link)
    if class~=2 or (subclass~=2 and subclass~=3 and subclass~=18) then return end
    if itemCache[link] then return itemCache[link] end
    local locale=query(GetLocale)
    if locale and locale~='enUS' and locale~='enGB' then return nil,'Weapon damage parsing currently supports English tooltips.' end
    -- Remove only the enchant field, preserving suffix/bonus fields on this exact item.
    -- Live damage already includes the equipped scope; base item damage must not include it again.
    local bare=link:gsub('(item:%d+:)[^:]*:',function(prefix) return prefix..'0:' end,1)
    local name,_,_,itemLevel,requiredLevel=query(C_Item and C_Item.GetItemInfo or GetItemInfo,bare)
    if not name or not number(itemLevel) or not number(requiredLevel) then
        return nil,'Weapon details are loading. Hover again when the item is available.'
    end
    local tip=query(C_TooltipInfo and C_TooltipInfo.GetHyperlink,bare)
    if type(tip)~='table' or not public(tip.lines) or type(tip.lines)~='table' then return nil,'Weapon tooltip data is loading.' end
    local low,high,speed,hasEffects
    for _,line in ipairs(tip.lines) do
        if public(line) and type(line)=='table' then
            local left,right=clean(line.leftText),clean(line.rightText)
            local a,b=left:match('(%d+%.?%d*)%s*%-%s*(%d+%.?%d*)%s+[Dd]amage')
            if a and b then low,high=tonumber(a),tonumber(b) end
            local value=(right..' '..left):match('[Ss]peed%s+(%d+%.?%d*)')
            if value then speed=tonumber(value) end
            if left:match('^Chance on hit:') or left:match('^Use:') or left:match('^Set:') or left:match('^%(%d+%) Set:') then hasEffects=true end
        end
    end
    local stats=query(C_Item and C_Item.GetItemStats or GetItemStats,bare)
    if type(stats)~='table' then return nil,'Weapon stat data is loading.' end
    local copied={}
    for key,value in pairs(stats) do
        if not public(key) or type(key)~='string' or not number(value) then return nil,'Weapon stats are unavailable.' end
        copied[key]=value
    end
    if not number(low) or not number(high) or not number(speed) or high<=low or low<0 or speed<0.1 or speed>20 then
        return nil,'No readable physical weapon damage/speed is available.'
    end
    local weapon={link=link,name=name,subclass=subclass,kind=subclass==3 and 3 or 2,
        itemLevel=itemLevel,requiredLevel=requiredLevel,min=low,max=high,speed=speed,stats=copied,
        scope=F.WeaponScopeOnLink(link),hasEffects=hasEffects}
    if cacheSize>=80 then F.ClearWeaponComparisonCache() end
    itemCache[link]=weapon;cacheSize=cacheSize+1
    return weapon
end
local function stat(w,key) return w.stats[key] or 0 end
local function rating(w,general,ranged) return w.stats[general] or w.stats[ranged] or 0 end
function F.EstimateRangedSwap(base,candidate,live,scope)
    -- Calibrate multiplicative damage and haste from the current character sheet.
    -- Existing talents/buffs stay in live values; add only the weapon's stat delta.
    if not base.scope or not scope then return nil,'Unrecognized scope/enchant; no damage estimate is guessed.' end
    local factor=(live.max-live.min)/(base.max-base.min)
    if not number(factor) or factor<0.1 or factor>10 then return nil,'Ranged damage is settling; try again shortly.' end
    local agility=stat(candidate,'ITEM_MOD_AGILITY_SHORT')-stat(base,'ITEM_MOD_AGILITY_SHORT')
    local ap=stat(candidate,'ITEM_MOD_ATTACK_POWER_SHORT')-stat(base,'ITEM_MOD_ATTACK_POWER_SHORT')
        +stat(candidate,'ITEM_MOD_RANGED_ATTACK_POWER_SHORT')-stat(base,'ITEM_MOD_RANGED_ATTACK_POWER_SHORT')
    local statScalingUnverified=false
    for index,key in ipairs({'ITEM_MOD_STRENGTH_SHORT','ITEM_MOD_AGILITY_SHORT','ITEM_MOD_STAMINA_SHORT','ITEM_MOD_INTELLECT_SHORT','ITEM_MOD_SPIRIT_SHORT'}) do
        local delta=stat(candidate,key)-stat(base,key)
        if delta~=0 then
            local contribution=query(GetRangedAttackPowerForStat,index,math.abs(delta))
            if number(contribution) then ap=ap+(delta<0 and -contribution or contribution)
            else
                statScalingUnverified=true
                if index==2 then ap=ap+2*delta end
            end
        end
    end
    ap=math.max(0,live.ap+ap)-live.ap
    local speedDelta=candidate.speed-base.speed
    local bonus=(live.ap/14+live.ammoDPS)*speedDelta+ap/14*candidate.speed+scope.damage-base.scope.damage
    local low=live.min+factor*(candidate.min-base.min+bonus)
    local high=live.max+factor*(candidate.max-base.max+bonus)
    local speed=candidate.speed*(live.speed/base.speed)
    local hasteDelta=rating(candidate,'ITEM_MOD_HASTE_RATING_SHORT','ITEM_MOD_HASTE_RANGED_RATING_SHORT')
        -rating(base,'ITEM_MOD_HASTE_RATING_SHORT','ITEM_MOD_HASTE_RANGED_RATING_SHORT')
    local hasteUnmodeled=false
    if hasteDelta~=0 then
        local current=query(GetCombatRatingBonus,CR_HASTE_RANGED)
        local delta=query(GetCombatRatingBonusForCombatRatingValue,CR_HASTE_RANGED,math.abs(hasteDelta))
        if number(CR_HASTE_RANGED) and number(current) and number(delta) and 1+(current+(hasteDelta<0 and -delta or delta))/100>0 then
            speed=speed*(1+current/100)/(1+(current+(hasteDelta<0 and -delta or delta))/100)
        else hasteUnmodeled=true end
    end
    if not number(low) or not number(high) or low<0 or high<low or not number(speed) or speed<0.05 then return nil,'No reliable ranged estimate is available.' end
    local shot=(low+high)/2;local currentShot=(live.min+live.max)/2
    return {min=low,max=high,speed=speed,dps=shot/speed,shot=shot,shotDelta=shot-currentShot,
        dpsDelta=shot/speed-currentShot/live.speed,agilityDelta=agility,apDelta=ap,
        hasteDelta=hasteDelta,hasteUnmodeled=hasteUnmodeled,statScalingUnverified=statScalingUnverified,
        critDelta=rating(candidate,'ITEM_MOD_CRIT_RATING_SHORT','ITEM_MOD_CRIT_RANGED_RATING_SHORT')-rating(base,'ITEM_MOD_CRIT_RATING_SHORT','ITEM_MOD_CRIT_RANGED_RATING_SHORT'),
        hitDelta=rating(candidate,'ITEM_MOD_HIT_RATING_SHORT','ITEM_MOD_HIT_RANGED_RATING_SHORT')-rating(base,'ITEM_MOD_HIT_RATING_SHORT','ITEM_MOD_HIT_RANGED_RATING_SHORT')}
end
function F.BuildWeaponComparison(link)
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return end
    local candidate,reason=F.ReadComparisonWeapon(link)
    if not candidate then return nil,reason end
    local level=query(UnitLevel,'player')
    if not number(level) then return nil,'Character level is unavailable.' end
    if candidate.requiredLevel>level then return nil,'Requires level '..candidate.requiredLevel..'; not usable yet.' end
    local equipped=query(GetInventoryItemLink,'player',18)
    local base,baseReason=F.ReadComparisonWeapon(equipped)
    if not base then return nil,baseReason or 'Equip a bow, gun or crossbow to compare weapons.' end
    if not base.scope then return nil,'Equipped scope/enchant is unrecognized; comparison unavailable.' end
    local speed,low,high=query(UnitRangedDamage,'player')
    local ap,pos,neg=query(UnitRangedAttackPower,'player')
    if not number(speed) or speed<=0 or not number(low) or not number(high) or high<=low
        or not number(ap) or not number(pos) or not number(neg) then return nil,'Live ranged stats are unavailable; try outside combat.' end
    local ammoID=query(GetInventoryItemID,'player',0)
    local ammo=ammoID and F.ammoUpgradeCatalog and F.ammoUpgradeCatalog[ammoID]
    if not ammo or ammo.kind~=base.kind then return nil,'Select ammunition with verified damage before comparing weapons.' end
    local count=query(C_Item and C_Item.GetItemCount or GetItemCount,ammoID,false,false)
    if not number(count) then return nil,'Ammunition totals are loading.' end
    if count<=0 then return nil,'Equipped ammo is depleted. Equip stocked ammunition before comparing.' end
    local setting=F.WeaponCompareSettings().scope
    local scope=setting=='actual' and candidate.scope or setting=='none' and {name='No scope',damage=0}
        or setting=='equipped' and base.scope or scopesByID[setting]
    if not scope then return nil,'Hovered scope/enchant is unrecognized. Choose a known scope preview.' end
    if (setting~='actual' and scope.level and not F.WeaponScopeAllowed(scope,candidate,level)) then
        return nil,'Selected scope needs level '..scope.level..' and weapon item level '..scope.level..'. Choose another preview.'
    end
    local result,errorText=F.EstimateRangedSwap(base,candidate,{speed=speed,min=low,max=high,ap=math.max(0,ap+pos+neg),ammoDPS=ammo.dps},scope)
    if not result then return nil,errorText end
    result.base=base;result.candidate=candidate;result.scope=scope;result.scopeMode=setting;result.ammo=ammo;result.ammoName=F.AmmoInfo and F.AmmoInfo(ammoID) or ('Ammo '..ammoID)
    result.currentDPS=(low+high)/2/speed;result.currentMin=low;result.currentMax=high
    return result
end
local function signed(value,suffix)
    if math.abs(value)<0.05 then return '0.0'..(suffix or '') end
    return (value>0 and '|cff66ee88' or '|cffff7777')..('%+.1f'):format(value)..(suffix or '')..'|r'
end
local building=false
function F.AddWeaponComparison(tooltip)
    if building or not F.db or not F.WeaponCompareSettings().enabled or InCombatLockdown()
        or tooltip.HunterToolsWeaponAdded or (tooltip~=GameTooltip and tooltip~=ItemRefTooltip) then return end
    if F.weaponComparisonReadyAt and GetTime()<F.weaponComparisonReadyAt then return end
    local _,link=query(tooltip.GetItem,tooltip)
    if type(link)~='string' then return end
    building=true
    local ok,result,reason=pcall(F.BuildWeaponComparison,link)
    building=false
    if not ok or (not result and not reason) then return end
    tooltip.HunterToolsWeaponAdded=true
    tooltip:AddLine(' ');tooltip:AddLine('HunterTools | Ranged comparison (experimental)',1,0.82,0)
    if not result then tooltip:AddLine(reason,0.8,0.8,0.8,true);return end
    local r=result
    tooltip:AddLine(('Estimated shot: %.1f - %.1f | %.1f Auto Shot DPS'):format(r.min,r.max,r.dps),0.95,0.95,0.95,true)
    tooltip:AddLine('Vs equipped: '..signed(r.shotDelta,' avg/shot')..' | '..signed(r.dpsDelta,' DPS'),1,1,1,true)
    tooltip:AddLine(('Equipped: %.1f - %.1f | %.1f DPS'):format(r.currentMin,r.currentMax,r.currentDPS),0.7,0.7,0.7,true)
    tooltip:AddLine('Scope '..(r.scopeMode=='actual' and '(as attached): ' or '(preview): ')..r.scope.name,0.85,0.85,0.65,true)
    tooltip:AddLine(('Ammo: %s (%.1f DPS) | Shot interval %.2fs'):format(r.ammoName,r.ammo.dps,r.speed),0.8,0.8,0.8,true)
    if r.agilityDelta~=0 or r.apDelta~=0 then tooltip:AddLine('Weapon stat swap: '..signed(r.agilityDelta,' Agi')..' | '..signed(r.apDelta,' ranged AP'),0.8,0.8,0.8,true) end
    if r.statScalingUnverified then tooltip:AddLine('Stat conversion unavailable; assumes 2 ranged AP per Agility. Other stat scaling is omitted.',1,0.75,0.35,true) end
    if r.critDelta~=0 or r.hitDelta~=0 or r.hasteUnmodeled then
        tooltip:AddLine(('Unmodeled rating change: %+g crit, %+g hit%s'):format(r.critDelta,r.hitDelta,r.hasteUnmodeled and (', '..r.hasteDelta..' haste') or ''),1,0.75,0.35,true)
    end
    if r.base.kind~=r.candidate.kind then tooltip:AddLine('Ammo DPS held equal for comparison; this weapon needs '..(r.candidate.kind==3 and 'bullets.' or 'arrows.'),1,0.75,0.35,true) end
    if r.base.subclass~=r.candidate.subclass then tooltip:AddLine('Check weapon proficiency. Weapon-specific talents/racials and quiver changes are not recalculated.',1,0.75,0.35,true) end
    if r.base.hasEffects or r.candidate.hasEffects then tooltip:AddLine('A proc, use or set effect on these weapons is omitted from this estimate.',1,0.75,0.35,true) end
    tooltip:AddLine('Before armor/misses/crit. Current buffs retained; stat multipliers, procs and special effects are not simulated.',0.65,0.65,0.65,true)
    tooltip:AddLine('Scope options: /ht weapons',0.65,0.75,0.65)
end
for _,tooltip in ipairs({GameTooltip,ItemRefTooltip}) do
    if tooltip and tooltip.HookScript then
        tooltip:HookScript('OnTooltipCleared',function(t) t.HunterToolsWeaponAdded=nil end)
    end
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,F.AddWeaponComparison)
elseif GameTooltip and GameTooltip.HasScript and GameTooltip:HasScript('OnTooltipSetItem') then
    GameTooltip:HookScript('OnTooltipSetItem',F.AddWeaponComparison)
end
local events=CreateFrame('Frame')
for _,event in ipairs({'GET_ITEM_INFO_RECEIVED','PLAYER_EQUIPMENT_CHANGED','PLAYER_ENTERING_WORLD'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event)
    F.ClearWeaponComparisonCache()
    if event=='PLAYER_ENTERING_WORLD' then F.weaponComparisonReadyAt=GetTime()+3
    elseif event=='PLAYER_EQUIPMENT_CHANGED' then F.weaponComparisonReadyAt=GetTime()+0.5 end
end)
