local _,F=...
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if not ok then return end
    if not public(a) then a=nil end;if not public(b) then b=nil end
    if not public(c) then c=nil end;if not public(d) then d=nil end
    if not public(e) then e=nil end;if not public(f) then f=nil end;if not public(g) then g=nil end
    return a,b,c,d,e,f,g
end
function F.AmmoUpgradeSettings()
    local a=F.db.ammo
    if type(a.upgrades)~='table' then a.upgrades={} end
    if type(a.upgrades.enabled)~='boolean' then a.upgrades.enabled=false end
    if type(a.upgrades.includeEngineered)~='boolean' then a.upgrades.includeEngineered=false end
    local s=a.upgrades
    if type(s.notify)~='boolean' then s.notify=false end
    if type(s.minutes)~='number' or s.minutes~=s.minutes or s.minutes<0.1 or s.minutes>120 then s.minutes=5 end
    if s.mode~='chat' and s.mode~='both' then s.mode='screen' end
    return s
end
local function engineeringSkill()
    local first,second=query(GetProfessions)
    for i=1,2 do
        local index=i==1 and first or second
        local name,_,rank,_,_,_,skillID=query(GetProfessionInfo,index)
        if (skillID==202 or name=='Engineering') and type(rank)=='number' then return rank end
    end
    local n=query(GetNumSkillLines)
    if type(n)~='number' then return nil end
    for i=1,n do
        local name,header,_,rank=query(GetSkillLineInfo,i)
        if not header and name=='Engineering' and type(rank)=='number' then return rank end
    end
    return nil
end
function F.AmmoUpgradeContext(scanOK)
    local s=F.AmmoUpgradeSettings()
    if not s.enabled then return nil,'Enable upgrade recommendations to compare ammunition.' end
    if not F.db.ammo.enabled then return nil,'Enable Ammo Reminder to use upgrade recommendations.' end
    if InCombatLockdown() then return nil,'Updates resume after combat.' end
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return nil,'Ammo upgrade recommendations are for hunters.' end
    local level=query(UnitLevel,'player')
    if type(level)~='number' or level~=level or level<1 or level>1000 then return nil,'Character level is unavailable.' end
    local weapon=query(GetInventoryItemID,'player',18)
    if not weapon then return nil,'Equip a bow, crossbow, or gun to compare ammunition.' end
    local _,_,_,_,_,itemClass,subclass=query(C_Item and C_Item.GetItemInfoInstant,weapon)
    if type(itemClass)~='number' or type(subclass)~='number' then return nil,'Ranged weapon data is loading.' end
    local kind=itemClass==2 and ((subclass==2 or subclass==18) and 2 or subclass==3 and 3 or nil)
    if not kind then return nil,'This ranged weapon does not use arrows or bullets.' end
    if not scanOK or F.ammoEntryReadyAt then return nil,'Inventory is settling; recommendations will update when ready.' end
    local equipmentOK,equipped=pcall(GetInventoryItemID,'player',0)
    if not equipmentOK or not public(equipped) then return nil,'Equipped ammo is unavailable; try again after inventory settles.' end
    local current=equipped and F.ammoUpgradeCatalog[equipped]
    if equipped and not current then return nil,'Equipped ammo has no verified damage reference; comparison unavailable.' end
    local faction=query(UnitFactionGroup,'player')
    local counts={};for id,n in pairs(F.ammoCounts or {}) do counts[id]=n end
    local getCount=C_Item and C_Item.GetItemCount or GetItemCount
    if getCount then
        for id in pairs(F.ammoUpgradeCatalog) do
            local n=query(getCount,id,false,false)
            if type(n)~='number' or n<0 then return nil,'Carried ammo totals are unavailable; try again after inventory settles.' end
            -- Native carried total is authoritative after readiness checks; do not
            -- keep a stale positive bag snapshot after the last stack is spent.
            counts[id]=n
        end
    end
    local equippedEntry=current and current.kind==kind and current or nil
    local depleted=equippedEntry~=nil and (counts[equipped] or 0)<=0
    local baselineID,baseline
    if equippedEntry and not depleted then baselineID,baseline=equipped,equippedEntry end
    local baselineUnknown=false
    if not baseline then
        for id,n in pairs(counts) do
            if n>0 then
                local entry=F.ammoUpgradeCatalog[id]
                if entry and entry.kind==kind and entry.level<=level then
                    if not baseline or entry.dps>baseline.dps or (entry.dps==baseline.dps and id<baselineID) then baselineID,baseline=id,entry end
                elseif not entry and F.ammoCatalog[id] and F.ammoCatalog[id].kind==kind then baselineUnknown=true end
            end
        end
    end
    return {level=level,kind=kind,faction=faction,engineering=engineeringSkill(),equipped=equipped,
        equippedEntry=equippedEntry,depleted=depleted,baselineID=baselineID,baselineUnknown=baselineUnknown,
        current=baseline,settings=s,counts=counts}
end
local function carried(c,id) return type(c.counts[id])=='number' and c.counts[id]>0 end
function F.AmmoUpgradeAllowed(c,id,entry,future)
    if entry.kind~=c.kind then return false end
    if entry.engineered and not c.settings.includeEngineered then return false end
    if not future and entry.level>c.level then return false end
    if carried(c,id) then return true end
    if entry.sourceType=='vendor' then return c.faction=='Alliance' or c.faction=='Horde' end
    if entry.sourceType=='craft' then
        if entry.personalCraft then return type(c.engineering)=='number' and c.engineering>=entry.craftSkill end
        return true
    end
    -- Dungeon/quest/rep/exchange/unknown sources cannot make ordinary carried
    -- ammo obsolete on speculation. Already-carried versions can be compared.
    return false
end
function F.AmmoUpgradeBest(c)
    if c.baselineUnknown then return nil end
    local best,bestID,owned,ownedID
    for id,e in pairs(F.ammoUpgradeCatalog) do
        if F.AmmoUpgradeAllowed(c,id,e) then
            if not best or e.dps>best.dps or (e.dps==best.dps and id<bestID) then best,bestID=e,id end
            if carried(c,id) and (not owned or e.dps>owned.dps or (e.dps==owned.dps and id<ownedID)) then owned,ownedID=e,id end
        end
    end
    return bestID,best,ownedID,owned
end
function F.AmmoIsObsolete(id,c,best)
    if not c or c.baselineUnknown or not best then return false end
    local e=F.ammoUpgradeCatalog[id]
    return e and e.kind==c.kind and e.level<=c.level and best.dps>e.dps or false
end
function F.AmmoUpgradeSource(id,e,c)
    if e.sourceType=='vendor' then return e[c.faction] or 'Vendor faction unavailable' end
    if e.sourceType=='craft' then
        return 'Engineering '..e.craftSkill..(e.personalCraft and '; bind-on-pickup, craft it yourself (schematic required).' or '; craft it or buy from an engineer / Auction House. No Engineering requirement to use.')
    end
    return e[c.faction] or e.source or 'Acquisition requirements unverified'
end
function F.AmmoUpgradeAdvice(c)
    local lines={}
    local currentDPS=c.current and c.current.dps or 0
    if c.depleted then
        lines[#lines+1]='|cffff3333Equipped ammo depleted: '..F.AmmoInfo(c.equipped)..' (0 left).|r'
    elseif c.equipped and c.equippedEntry then
        lines[#lines+1]='Equipped: '..F.AmmoInfo(c.equipped)..(' (%.1f ammo DPS; %d left).'):format(c.equippedEntry.dps,c.counts[c.equipped] or 0)
    else lines[#lines+1]='No compatible ammo equipped.' end
    if c.baselineUnknown then
        lines[#lines+1]='Carried ammo has unverified damage stats; upgrade comparison unavailable.'
        return table.concat(lines,'\n\n')
    end
    if c.baselineID and c.baselineID~=c.equipped then
        lines[#lines+1]='Available in bags: '..F.AmmoInfo(c.baselineID)..(' (%.1f ammo DPS; %d left). Equip it.'):format(currentDPS,c.counts[c.baselineID] or 0)
    elseif not c.current then lines[#lines+1]='No usable compatible ammo left in your bags.' end
    local bestID,best,ownedID,owned=F.AmmoUpgradeBest(c)
    if owned and ownedID~=c.baselineID and owned.dps>currentDPS then
        lines[#lines+1]='Already carrying better ammo: '..F.AmmoInfo(ownedID)..(' (%.1f ammo DPS). Equip it.'):format(owned.dps)
    end
    if best and best.dps>currentDPS then
        lines[#lines+1]='Recommended: '..F.AmmoInfo(bestID)..(' (%.1f ammo DPS, +%.1f vs available ammo; level %d).'):format(best.dps,best.dps-currentDPS,best.level)
        lines[#lines+1]='Source: '..F.AmmoUpgradeSource(bestID,best,c)
    else
        lines[#lines+1]='No stronger usable option in the verified recommendation catalog.'
        local nextID,nextEntry
        for id,e in pairs(F.ammoUpgradeCatalog) do
            if e.level>c.level and e.dps>currentDPS and F.AmmoUpgradeAllowed(c,id,e,true) then
                if not nextEntry or e.level<nextEntry.level or (e.level==nextEntry.level and e.dps>nextEntry.dps) or (e.level==nextEntry.level and e.dps==nextEntry.dps and id<nextID) then nextID,nextEntry=id,e end
            end
        end
        if nextEntry then
            lines[#lines+1]='Next upgrade: '..F.AmmoInfo(nextID)..(' at level %d (%.1f ammo DPS).'):format(nextEntry.level,nextEntry.dps)
            lines[#lines+1]='Source: '..F.AmmoUpgradeSource(nextID,nextEntry,c)
        end
    end
    if c.faction~='Alliance' and c.faction~='Horde' then lines[#lines+1]='Choose a faction before vendor recommendations can be shown.' end
    lines[#lines+1]='Ammo DPS is the ammunition bonus, not total weapon or character DPS.'
    return table.concat(lines,'\n\n'),best
end
function F.ResetAmmoUpgradeNotifications()
    F.ammoUpgradeLastNotice=nil;F.ammoUpgradePending=nil;F.ammoUpgradeNextCheck=nil
end
function F.ShowAmmoUpgradeNotification(c,id,entry)
    local message=''
    if c.depleted then
        message='Equipped ammo depleted: '..F.AmmoInfo(c.equipped)..' (0 left). '
        if c.baselineID then message=message..'Equip '..F.AmmoInfo(c.baselineID)..' from your bags. '
        elseif not c.baselineUnknown then message=message..'No usable compatible ammo left. ' end
    end
    if entry and entry.dps>(c.current and c.current.dps or 0) then
        message=message..'Ammo upgrade: '..F.AmmoInfo(id)..(' (+%.1f ammo DPS vs available ammo). '):format(entry.dps-(c.current and c.current.dps or 0))
        if carried(c,id) then message=message..'Already in your bags - equip it.'
        else message=message..F.AmmoUpgradeSource(id,entry,c) end
    elseif c.baselineUnknown then message=message..'Carried ammo stats are unverified; comparison unavailable.' end
    local mode=c.settings.mode
    if mode=='chat' or mode=='both' then F.Print(message) end
    if mode=='screen' or mode=='both' then
        if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame,message,{r=1,g=0.8,b=0.2},5)
        elseif mode=='screen' then F.Print(message) end
    end
end
function F.CheckAmmoUpgradeNotifications()
    if not F.db or not F.db.ammo then return end
    local s=F.AmmoUpgradeSettings()
    if not F.db.ammo.enabled or not s.enabled or not s.notify then
        F.ResetAmmoUpgradeNotifications();return
    end
    if InCombatLockdown() then F.ammoUpgradePending=nil;return end
    local dead=query(UnitIsDeadOrGhost,'player');if dead~=false then F.ammoUpgradePending=nil;return end
    -- Ammo Reminder confirms inventory readiness after zoning; do not consume
    -- a notification's interval while data is loading or combat blocks reads.
    if F.ammoEntryReadyAt then F.ammoUpgradePending=nil;return end
    local now=query(GetTime);if type(now)~='number' then return end
    if F.ammoUpgradeLastNotice and now-F.ammoUpgradeLastNotice<s.minutes*60 then return end
    if F.ammoUpgradeNextCheck and now<F.ammoUpgradeNextCheck then return end
    F.ammoUpgradeNextCheck=now+5
    local c=F.AmmoUpgradeContext(F.ScanAmmo())
    if not c then F.ammoUpgradePending=nil;return end
    local id,entry=F.AmmoUpgradeBest(c)
    local upgrade=entry and entry.dps>(c.current and c.current.dps or 0)
    if not c.depleted and not upgrade then F.ammoUpgradePending=nil;return end
    local signature=table.concat({c.kind,c.equipped or 0,id or 0,c.baselineID or 0,c.depleted and 1 or 0,carried(c,id) and 1 or 0},':')
    if not F.ammoUpgradePending or F.ammoUpgradePending.signature~=signature then
        F.ammoUpgradePending={signature=signature,at=now};return
    end
    if now-F.ammoUpgradePending.at<1 then return end
    F.ShowAmmoUpgradeNotification(c,id,entry)
    F.ammoUpgradeLastNotice=now
end
function F.OpenAmmoUpgradeSettings()
    if InCombatLockdown() then F.Print('Open ammo upgrade settings after combat.');return end
    F.HideConfigPages()
    if not F.ammoUpgradePanel then
        local p=CreateFrame('Frame','HunterToolsAmmoUpgrades',UIParent,'BackdropTemplate');F.ammoUpgradePanel=p
        p:SetSize(650,690);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        local width=UIParent.GetWidth and UIParent:GetWidth();local height=UIParent.GetHeight and UIParent:GetHeight()
        if type(width)=='number' and type(height)=='number' then p:SetScale(math.min(1,width/680,height/720)) end
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        table.insert(UISpecialFrames,'HunterToolsAmmoUpgrades')
        local function text(value,y,font)
            local t=p:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall');t:SetPoint('TOPLEFT',28,y);t:SetWidth(592);t:SetJustifyH('LEFT');t:SetText(value);return t
        end
        text('Ammunition | Upgrade advice',-25,'GameFontNormalLarge')
        p.checks={}
        for i,spec in ipairs({{'enabled','Enable upgrade recommendations'},{'includeEngineered','Include engineered ammo'},{'notify','Enable upgrade notifications'}}) do
            local key=spec[1];local b=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');b:SetPoint('TOPLEFT',24,-62-(i-1)*34)
            local label=b:CreateFontString(nil,'OVERLAY','GameFontHighlight');label:SetPoint('LEFT',b,'RIGHT',3,0);label:SetText(spec[2]);p.checks[key]=b
            b:SetScript('OnClick',function() if not InCombatLockdown() then F.AmmoUpgradeSettings()[key]=b:GetChecked() and true or false;F.ResetAmmoUpgradeNotifications();p:Refresh() end end)
        end
        text('Every (minutes):',-178)
        p.interval=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.interval:SetSize(75,24);p.interval:SetPoint('TOPLEFT',160,-171);p.interval:SetAutoFocus(false);p.interval:SetMaxLetters(8)
        local function saveInterval(self)
            local n=tonumber(self:GetText());local settings=F.AmmoUpgradeSettings()
            if not n or n~=n or n<0.1 or n>120 then F.Print('Enter an upgrade interval from 0.1 to 120 minutes.');self:SetText(tostring(settings.minutes));return end
            if settings.minutes~=n then settings.minutes=n;F.ResetAmmoUpgradeNotifications() end
            self:SetText(tostring(n))
        end
        p.interval:SetScript('OnEnterPressed',function(self) saveInterval(self);self:ClearFocus();p:Refresh() end)
        p.interval:SetScript('OnEditFocusLost',saveInterval)
        p.interval:SetScript('OnEscapePressed',function(self) self:SetText(tostring(F.AmmoUpgradeSettings().minutes));self:ClearFocus() end)
        p.destination=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.destination:SetSize(330,24);p.destination:SetPoint('TOPLEFT',282,-171)
        p.destination:SetScript('OnClick',function()
            local settings=F.AmmoUpgradeSettings();settings.mode=({screen='chat',chat='both',both='screen'})[settings.mode]
            F.ResetAmmoUpgradeNotifications();p:Refresh()
        end)
        text('0.1-120 minutes. Alerts for depleted ammo or usable upgrades. Enter saves.',-211)
        text('Compares equipped ammo and carried stock for your weapon, level and faction.\nThe ammo list marks lower-damage choices red [Obsolete] only while recommendations and Ammo Reminder are enabled.',-244)
        p.advice=text('',-296);p.advice:SetHeight(300)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(210,26);back:SetPoint('BOTTOM',0,28);back:SetText('Back to Ammo Reminder')
        back:SetScript('OnClick',function() p:Hide();F.OpenAmmoSettings() end)
        function p:Refresh()
            local settings=F.AmmoUpgradeSettings();for key,b in pairs(self.checks) do b:SetChecked(settings[key]) end
            if not self.interval:HasFocus() then self.interval:SetText(tostring(settings.minutes)) end
            self.destination:SetText('Notify: '..({screen='On-screen banner',chat='Chat',both='Banner + chat'})[settings.mode])
            local scanOK=not InCombatLockdown() and F.ScanAmmo()
            local c,reason=F.AmmoUpgradeContext(scanOK)
            self.advice:SetText(c and F.AmmoUpgradeAdvice(c) or reason)
        end
        for _,event in ipairs({'BAG_UPDATE_DELAYED','PLAYER_EQUIPMENT_CHANGED','PLAYER_REGEN_ENABLED','PLAYER_REGEN_DISABLED','GET_ITEM_INFO_RECEIVED','PLAYER_LEVEL_UP','SKILL_LINES_CHANGED','PLAYER_ENTERING_WORLD','NEUTRAL_FACTION_SELECT_RESULT'}) do
            if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then p:RegisterEvent(event) end
        end
        p:SetScript('OnEvent',function() if p:IsShown() then p:Refresh() end end)
        local elapsed=0;p:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=2 then elapsed=0;if not InCombatLockdown() then p:Refresh() end end end)
    end
    if F.FinishMenu then F.FinishMenu(F.ammoUpgradePanel,650,690) end
    F.ammoUpgradePanel:Show();F.ammoUpgradePanel:Refresh()
end
