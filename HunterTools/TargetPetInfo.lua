local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c,d=pcall(fn,...)
    if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    if not safe(c) then c=nil end
    if not safe(d) then d=nil end
    return a,b,c,d
end
F.animalFields={{'info','Potential pet information'},{'role','Pet role'},
    {'abilities','Abilities / learned ranks'},{'diet','Diet'},{'food','Inventory food counts'}}
function F.AnimalSettings()
    if type(F.db.animals)~='table' then F.db.animals={} end
    local s=F.db.animals
    for _,surface in ipairs({'mouseover','target'}) do
        if type(s[surface])~='table' then s[surface]={} end
        local fields=s[surface]
        if type(fields.enabled)~='boolean' then fields.enabled=true end
        for _,field in ipairs(F.animalFields) do
            local key=field[1]
            if type(fields[key])~='boolean' then
                local old=F.RangeSettings()
                if surface=='target' and key=='abilities' then fields[key]=old.showPetAbilities~=false
                elseif surface=='target' and key=='diet' then fields[key]=old.showPetDiet~=false
                else fields[key]=true end
            end
        end
    end
    return s
end
-- Traditional Classic roles; not a claim about Forever's modified family stats.
local roles={Bat='Offensive',Bear='Defensive',Boar='Defensive',Cat='Offensive',
    ['Carrion Bird']='General (balanced)',Crab='Defensive',Crocolisk='Defensive',
    Gorilla='Defensive',Hyena='General (balanced)',Owl='Offensive',Raptor='Offensive',
    Scorpid='Defensive',Spider='Offensive',Tallstrider='Defensive',Turtle='Defensive',
    ['Wind Serpent']='Offensive',Wolf='General (balanced)'}
function F.PetRole(family)
    return family and roles[family] and (roles[family]..' (Classic baseline)') or 'Unknown'
end
local foodCache={}
function F.AnimalFoodCounts(diet,level)
    if type(diet)~='string' then return 'Diet unknown; counts unavailable.' end
    local cacheKey=diet..':'..tostring(level)
    local now=GetTime and GetTime() or 0
    local cached=foodCache[cacheKey]
    if cached and now-cached.at<2 then return cached.text end
    local counts,usable={},0
    for kind in diet:gmatch('[^,]+') do counts[kind:match('^%s*(.-)%s*$')]=0 end
    local pending,unclassified=false,false
    if not C_Container or not C_Item then return 'Inventory information unavailable.' end
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local slots=query(C_Container.GetContainerNumSlots,bag)
        if type(slots)~='number' or (bag==0 and slots==0) then pending=true;slots=0 end
        for slot=1,slots do
            local item=query(C_Container.GetContainerItemInfo,bag,slot)
            if type(item)=='table' then
                local id,count=item.itemID,item.stackCount
                if safe(id) and safe(count) and type(id)=='number' and type(count)=='number' and count>0 then
                    local kind=F.petFoodTypes and F.petFoodTypes[id]
                    if kind and counts[kind] then
                        counts[kind]=counts[kind]+count
                        local name,_,_,foodLevel=query(C_Item.GetItemInfo,id)
                        if not safe(name) or not name or not safe(foodLevel) or type(foodLevel)~='number' then pending=true
                        elseif type(level)=='number' and level>0 and foodLevel>=level-30 then usable=usable+count end
                    elseif not kind and F.foodCatalog and F.foodCatalog[id] then unclassified=true end
                else pending=true end
            end
        end
    end
    local parts={}
    for token in diet:gmatch('[^,]+') do local kind=token:match('^%s*(.-)%s*$');parts[#parts+1]=kind..' ('..(counts[kind] or 0)..')' end
    local result=table.concat(parts,', ')
    if type(level)=='number' and level>0 then result=result..'\nUsable food (Classic estimate): '..usable end
    if pending or unclassified then result=result..'\nPartial count: '..(pending and 'item data loading; ' or '')..(unclassified and 'unclassified food in bags.' or 'retry after inventory settles.') end
    foodCache[cacheKey]={at=now,text=result}
    return result
end
function F.AnimalDetails(unit,s)
    if not s.enabled then return nil end
    local any=false;for _,field in ipairs(F.animalFields) do if s[field[1]] then any=true end end
    if not any or InCombatLockdown() then return nil end
    if not query(UnitExists,unit) then return nil end
    local family=query(UnitCreatureFamily,unit)
    -- Other hunters' pets are not potential tames. Your own pet has its status tooltip.
    if query(UnitIsPlayer,unit) or query(UnitPlayerControlled,unit) then return nil end
    local guid=query(UnitGUID,unit)
    local npcID=type(guid)=='string' and guid:match('^Creature%-.*%-(%d+)%-%x+$')
    npcID=tonumber(npcID)
    local forever=npcID and F.foreverPetCreatureDB and F.foreverPetCreatureDB[npcID]
    local record=forever or (npcID and F.petCreatureDB and F.petCreatureDB[npcID])
    local hasFamily=type(family)=='string' and family~=''
    if not hasFamily and record and record.family then family=record.family;hasFamily=true end
    -- Missing family is normal for new Forever beasts. Still show available info.
    -- Unknown non-beasts must not receive animal details.
    if not hasFamily and not record then
        local creatureType=query(UnitCreatureType,unit)
        if creatureType~='Beast' then return nil end
    end
    family=hasFamily and family or 'Family unknown'
    -- Creature families alone do not establish tameability; never promise a tame.
    local lines={}
    local level=query(UnitLevel,unit)
    if type(level)~='number' or level<1 then level=forever and forever.minLevel end
    if s.info then
        lines[#lines+1]=family..(type(level)=='number' and level>0 and (' - level '..level) or '')
            ..(forever and forever.tameable==true and ' (Wowhead: tameable)' or ' (tameability unconfirmed)')
        if forever and forever.zone then lines[#lines+1]='Location: '..forever.zone end
    end
    if s.role then lines[#lines+1]='Role: '..F.PetRole(family) end
    local diet,abilities
    local tip=query(C_TooltipInfo and C_TooltipInfo.GetUnit,unit)
    if safe(tip) and tip and safe(tip.lines) and tip.lines then
        for _,line in ipairs(tip.lines) do
            local text=line.leftText
            if safe(text) and type(text)=='string' then
                local clean=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
                local foods=clean:match('^[Dd]iet:%s*(.+)') or clean:match('^[Ff]ood [Tt]ypes?:%s*(.+)')
                if foods then diet=foods end
                local skills=clean:match('^[Aa]bilities:%s*(.+)') or clean:match('^[Pp]et [Aa]bilities:%s*(.+)')
                if skills then abilities=skills end
                if clean:match('[Rr]ank%s+%d+') and not skills then
                    abilities=abilities and (abilities..'; '..clean) or clean
                end
            end
        end
    end
    local baseline=false
    if not abilities and record then abilities=record.abilities;baseline=(not forever) and s.abilities and abilities~=nil end
    local wowheadDiet=false
    if not diet and forever then diet=forever.diet;wowheadDiet=diet~=nil end
    if not diet and F.foreverPetFamilyDiets then diet=F.foreverPetFamilyDiets[family];wowheadDiet=diet~=nil end
    if not diet and F.petFamilyDiets then diet=F.petFamilyDiets[family];baseline=baseline or ((s.diet or s.food) and diet~=nil) end
    if abilities and F.MarkTargetAbilities and s.abilities then abilities=F.MarkTargetAbilities(abilities) end
    if s.abilities then lines[#lines+1]='Abilities: '..(abilities or 'no database record; inspect with Beast Lore.') end
    if s.diet then lines[#lines+1]='Eats: '..(diet or 'not revealed; inspect with Beast Lore.') end
    if s.food then lines[#lines+1]='In bags: '..F.AnimalFoodCounts(diet,level) end
    if wowheadDiet and (s.diet or s.food) then lines[#lines+1]='Diet reference: Wowhead Forever.' end
    if forever then lines[#lines+1]='Wowhead Forever record; unlisted pet details remain unknown.' end
    if baseline then lines[#lines+1]='Classic baseline - Forever may differ.' end
    return #lines>0 and table.concat(lines,'\n') or nil
end
function F.TargetPetDetails()
    return F.AnimalDetails('target',F.AnimalSettings().target)
end
local building=false
function F.AddAnimalTip(tooltip)
    if building or not F.db or InCombatLockdown() or tooltip.HunterToolsAnimalTipAdded then return end
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return end
    local _,unit=query(tooltip.GetUnit,tooltip)
    if type(unit)~='string' or query(UnitIsUnit,unit,'pet') then return end
    -- GetUnit returns the hovered unit, independent of the current target.
    building=true
    local ok,details=pcall(F.AnimalDetails,unit,F.AnimalSettings().mouseover)
    building=false
    if not ok or not details then return end
    tooltip.HunterToolsAnimalTipAdded=true
    tooltip:AddLine(' ');tooltip:AddLine('HunterTools animal information',1,0.82,0)
    for line in details:gmatch('[^\n]+') do tooltip:AddLine(line,0.9,0.9,0.9,true) end
end
if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript('OnTooltipCleared',function(t) t.HunterToolsAnimalTipAdded=nil end)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,F.AddAnimalTip)
    elseif GameTooltip.HasScript and GameTooltip:HasScript('OnTooltipSetUnit') then
        GameTooltip:HookScript('OnTooltipSetUnit',F.AddAnimalTip)
    end
end

local inventory=CreateFrame('Frame')
for _,event in ipairs({'BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED','PLAYER_ENTERING_WORLD'}) do inventory:RegisterEvent(event) end
inventory:SetScript('OnEvent',function() foodCache={} end)
