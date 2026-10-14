local _, F = ...

local function number(value, default, maximum)
    local n=tonumber(value)
    if not n or n~=n or n<0 or n>maximum then return default end
    return n
end

function F.LoadAmmoSettings()
    if type(F.db.ammo)~='table' then F.db.ammo={} end
    local a=F.db.ammo
    if type(a.enabled)~='boolean' then a.enabled=false end
    if type(a.sound)~='boolean' then a.sound=false end
    a.minimum=math.floor(number(a.minimum,200,99999))
    a.minutes=number(a.minutes,5,120)
    if a.mode~='chat' and a.mode~='both' and a.mode~='off' then a.mode='screen' end
    if a.itemID~=nil and (type(a.itemID)~='number' or a.itemID<1 or a.itemID%1~=0) then a.itemID=nil end
    if type(a.minimums)~='table' then a.minimums={} end
    if type(a.selected)~='table' then
        a.selected={}
        if a.itemID then a.selected[a.itemID]=true; a.minimums[a.itemID]=a.minimum end
    end
    a.itemID=nil
    for id,value in pairs(a.minimums) do a.minimums[id]=math.floor(number(value,200,99999)) end
    if type(a.discovered)~='table' then a.discovered={} end
    for id,entry in pairs(a.discovered) do
        if type(id)=='number' and type(entry)=='table' and type(entry.name)=='string'
            and (entry.kind==2 or entry.kind==3) then F.ammoCatalog[id]=entry end
    end
    F.ammoDirty=true
end

function F.AmmoInfo(id)
    if not id then return nil end
    local entry=F.ammoCatalog[id]
    local name,_,_,_,_,_,_,_,_,icon=C_Item.GetItemInfo(id)
    return name or (entry and entry.name) or ('Item '..id),icon
end

local function discover(id)
    if F.ammoCatalog[id] or not C_Item.GetItemInfoInstant then return end
    local _,_,_,_,_,class,kind=C_Item.GetItemInfoInstant(id)
    if F.IsPublic(class) and F.IsPublic(kind) and class==6 and (kind==2 or kind==3) then
        local entry={name=F.AmmoInfo(id),kind=kind}
        F.ammoCatalog[id]=entry; F.db.ammo.discovered[id]=entry
    end
end

function F.QueueAmmoEntryScan()
    F.ammoEntryReadyAt=GetTime()+10
    F.ammoEntrySnapshot=nil
    F.db.ammo.lastWarning=nil
    F.ammoCounts=nil
    F.ammoDirty=true
end

function F.ScanAmmo()
    if F.ammoEntryReadyAt and GetTime()<F.ammoEntryReadyAt then return false end
    if InCombatLockdown() then return false end
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return false end
    -- Zoning can temporarily report both no equipped ammo and empty bags.
    -- If equipment is still unavailable, zero is not evidence of exhaustion.
    if F.db.ammo.lastEquipped and GetInventoryItemID then
        local weapon=GetInventoryItemID('player',18)
        if not F.IsPublic(weapon) or not weapon then
            F.ammoDirty=true
            return false
        end
    end
    local counts={}
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local slots=C_Container.GetContainerNumSlots(bag)
        if not F.IsPublic(slots) or type(slots)~='number' then return false end
        for slot=1,slots do
            local item=C_Container.GetContainerItemInfo(bag,slot)
            if not F.IsPublic(item) then return false end
            if item then
                if not F.IsPublic(item.itemID) or not F.IsPublic(item.stackCount) then return false end
                local id,n=item.itemID,item.stackCount
                if id and type(n)=='number' then
                    discover(id)
                    counts[id]=(counts[id] or 0)+n
                end
            end
        end
    end
    -- The client's carried-item total also covers equipped ammunition that
    -- a container-only scan can miss. Bank items and charges are excluded.
    local getCount=C_Item.GetItemCount or GetItemCount
    if getCount then
        for id,selected in pairs(F.db.ammo.selected) do
            if selected then
                local total=getCount(id,false,false)
                if not F.IsPublic(total) or type(total)~='number' then return false end
                counts[id]=math.max(counts[id] or 0,total)
            end
        end
    end
    F.ammoCounts=counts; F.ammoDirty=false
    return true
end

function F.AmmoTarget()
    if InCombatLockdown() then return nil,'Updates resume after combat.' end
    if not GetInventoryItemID then return nil,'Choose an ammo type below; equipped-ammo lookup is unavailable.' end
    local id=GetInventoryItemID('player',0)
    if not F.IsPublic(id) then return nil,'Equipped ammo is unavailable.' end
    if id then
        discover(id)
        F.db.ammo.lastEquipped=id
        return id
    end
    -- The ammo slot can clear when its last stack is consumed. Remember it
    -- only while a compatible ranged weapon is equipped, including on login.
    local previous=F.db.ammo.lastEquipped
    local weapon=GetInventoryItemID('player',18)
    if previous and F.ammoCatalog[previous] and F.IsPublic(weapon) and weapon and C_Item.GetItemInfoInstant then
        local _,_,_,_,_,class,kind=C_Item.GetItemInfoInstant(weapon)
        if F.IsPublic(class) and F.IsPublic(kind) and class==2 then
            local ammoKind=F.ammoCatalog[previous].kind
            if (ammoKind==2 and (kind==2 or kind==18)) or (ammoKind==3 and kind==3) then return previous end
        end
    end
    return nil,'No equipped ammo detected. Equip ammo or select a type below.'
end

function F.ShowAmmoReminder(id,count,test)
    local a=F.db.ammo
    if not test then
        local getCount=C_Item.GetItemCount or GetItemCount
        local native=getCount and getCount(id,false,false)
        local equipped=GetInventoryItemID and GetInventoryItemID('player',0)
        a.lastWarning={itemID=id,count=count,minimum=F.AmmoMinimum(id),
            native=F.IsPublic(native) and type(native)=='number' and native or nil,
            equipped=F.IsPublic(equipped) and type(equipped)=='number' and equipped or nil}
        if type(native)=='number' and F.IsPublic(native) and native>=F.AmmoMinimum(id) and native>0 then return false end
    end
    local message=(test and 'Test: ' or '')..'Low ammo: '..(id and F.AmmoInfo(id) or 'ammunition')
        ..' - '..tostring(count or 0)..' left (minimum '..F.AmmoMinimum(id)..').'
    local delivered=false
    if a.mode=='chat' or a.mode=='both' then F.Print(message); delivered=true end
    if a.mode=='screen' or a.mode=='both' then
        if RaidNotice_AddMessage and RaidWarningFrame then
            RaidNotice_AddMessage(RaidWarningFrame,message,{r=1,g=0.35,b=0.15},5)
        elseif a.mode~='both' then F.Print(message) end
        delivered=true
    end
    if a.sound and PlaySound then
        PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959,'Master'); delivered=true
    end
    if test and not delivered then F.Print('Choose a reminder type or enable sound to test the ammo alert.') end
    return delivered
end

function F.AmmoMinimum(id)
    return (id and F.db.ammo.minimums[id]) or F.db.ammo.minimum
end

function F.ResetAmmoReminder(id)
    F.ammoAlerts=F.ammoAlerts or {}
    if id then F.ammoAlerts[id]=nil else F.ammoAlerts={} end
end

function F.CheckAmmoReminder()
    if not F.db or not F.db.ammo or InCombatLockdown() then return end
    local _,class=UnitClass('player')
    if class~='HUNTER' or not F.db.ammo.enabled then F.ResetAmmoReminder(); return end
    if UnitIsDeadOrGhost('player') then return end
    if F.ammoEntryReadyAt then
        local now=GetTime()
        if now<F.ammoEntryReadyAt then return end
        -- Require two fresh matching scans after zoning before trusting low totals.
        F.ammoDirty=true
        if not F.ScanAmmo() then return end
        local previous=F.ammoEntrySnapshot
        local matches=previous~=nil
        for id,selected in pairs(F.db.ammo.selected) do
            if selected and (not previous or (previous[id] or 0)~=(F.ammoCounts[id] or 0)) then matches=false end
        end
        if not matches then
            F.ammoEntrySnapshot=F.ammoCounts
            F.ammoEntryReadyAt=now+1
            return
        end
        F.ammoEntryReadyAt=nil; F.ammoEntrySnapshot=nil
    end
    if F.ammoDirty and not F.ScanAmmo() then return end
    if not F.ammoCounts then return end
    F.ammoAlerts=F.ammoAlerts or {}
    local now=GetTime()
    for id in pairs(F.ammoAlerts) do
        if not F.db.ammo.selected[id] then F.ammoAlerts[id]=nil end
    end
    for id,selected in pairs(F.db.ammo.selected) do
        if selected then
            local count=F.ammoCounts[id] or 0
            local getCount=C_Item.GetItemCount or GetItemCount
            if getCount then
                -- Recheck at alert time, even when the previous scan was cached.
                local fresh=getCount(id,false,false)
                if not F.IsPublic(fresh) or type(fresh)~='number' then return end
                count=math.max(count,fresh)
                F.ammoCounts[id]=count
            end
            if count>0 and count>=F.AmmoMinimum(id) then F.ammoAlerts[id]=nil
            else
                local state=F.ammoAlerts[id]
                local empty=count==0
                local interval=F.db.ammo.minutes*60
                if not state or (empty and not state.empty) or (interval>0 and now-state.time>=interval) then
                    if F.ShowAmmoReminder(id,count) then F.ammoAlerts[id]={time=now,empty=empty} end
                end
            end
        end
    end
end

function F.DebugAmmo()
    local last=F.db.ammo.lastWarning
    if last then
        F.Print('Last warning: item '..tostring(last.itemID)..'; counted '..tostring(last.count)
            ..'; client total '..tostring(last.native)..'; minimum '..tostring(last.minimum)
            ..'; equipped item '..tostring(last.equipped))
    else F.Print('No automatic ammo warning recorded by this diagnostic version yet.') end
    if InCombatLockdown() then F.Print('Check ammo after combat.'); return end
    if not F.ScanAmmo() then F.Print('Ammo counts are not ready; try again after loading.'); return end
    local equipped=GetInventoryItemID and GetInventoryItemID('player',0)
    if F.IsPublic(equipped) then F.Print('Equipped ammo: '..(equipped and F.AmmoInfo(equipped) or 'none')) end
    local any=false
    for id,selected in pairs(F.db.ammo.selected) do
        if selected then
            any=true
            F.Print(F.AmmoInfo(id)..' ['..id..']: '..(F.ammoCounts[id] or 0)..' carried; minimum '..F.AmmoMinimum(id))
        end
    end
    if not any then F.Print('No ammo types selected for monitoring.') end
end
