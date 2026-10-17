local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c=pcall(fn,...)
    if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    if not safe(c) then c=nil end
    return a,b,c
end
local function text(v) return safe(v) and type(v)=='string' and #v<500 and v~='' and v or nil end
local function number(v) return safe(v) and type(v)=='number' and v==v and v>=0 and v<100000000 and v or nil end
local function clock() return query(GetTime) or 0 end
local function stamp() return query(GetServerTime) or query(time) or 0 end
local function enabled()
    if not F.db then return false end
    if type(F.db.beastJournal)~='table' then F.db.beastJournal={enabled=true,records={}} end
    local journal=F.db.beastJournal
    if type(journal.records)~='table' then journal.records={} end
    return journal.enabled~=false
end
function F.BeastNPCID(unit)
    local guid=query(UnitGUID,unit)
    return text(guid) and tonumber(guid:match('^Creature%-.*%-(%d+)%-%x+$')) or nil
end
local function record(id)
    if not id or not enabled() then return end
    local records=F.db.beastJournal.records
    if not records[id] then
        local count,oldest,oldTime=0,nil,math.huge
        for key,row in pairs(records) do
            count=count+1
            if (row.lastSeen or 0)<oldTime then oldest=key;oldTime=row.lastSeen or 0 end
        end
        if count>=2000 and oldest then records[oldest]=nil end
        records[id]={firstSeen=stamp(),locations={}}
    end
    return records[id]
end
function F.ReadBeastLore(unit)
    local tip=query(C_TooltipInfo and C_TooltipInfo.GetUnit,unit)
    if type(tip)~='table' or not safe(tip.lines) or type(tip.lines)~='table' then return end
    local diet,abilities
    for _,line in ipairs(tip.lines) do
        local s=text(line.leftText)
        if s then
            s=s:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
            diet=s:match('^[Dd]iet:%s*(.+)') or s:match('^[Ff]ood [Tt]ypes?:%s*(.+)') or diet
            abilities=s:match('^[Aa]bilities:%s*(.+)') or s:match('^[Pp]et [Aa]bilities:%s*(.+)') or abilities
        end
    end
    return diet,abilities
end
local seen={}
function F.ObserveBeast(unit)
    if not enabled() or query(InCombatLockdown) or query(UnitPlayerControlled,unit) or query(UnitIsPlayer,unit) then return end
    local id=F.BeastNPCID(unit)
    if not id or query(UnitCreatureType,unit)~='Beast' then return end
    local diet,abilities=F.ReadBeastLore(unit)
    -- Throttle repeated hovering; newly revealed Beast Lore still records immediately.
    local signature=(diet or '')..'|'..(abilities or '')
    if seen[id] and F.db.beastJournal.records[id] and clock()-seen[id].at<5 and seen[id].signature==signature then
        return id,F.db.beastJournal.records[id]
    end
    seen[id]={at=clock(),signature=signature}
    local row=record(id);if not row then return end
    row.name=text(query(UnitName,unit)) or row.name
    row.family=text(query(UnitCreatureFamily,unit)) or row.family
    local level=number(query(UnitLevel,unit))
    if level and level>0 then row.minLevel=math.min(row.minLevel or level,level);row.maxLevel=math.max(row.maxLevel or level,level) end
    row.lastSeen=stamp()
    local version,build=query(GetBuildInfo)
    row.build=text(version);row.buildNumber=text(build);row.locale=text(query(GetLocale))
    if diet then row.diet=diet;row.dietSource='Observed Beast Lore' end
    if abilities then row.loreAbilities=abilities end
    local zone=text(query(GetRealZoneText));local subzone=text(query(GetSubZoneText))
    local map=number(query(C_Map and C_Map.GetBestMapForUnit,'player'))
    row.zone=zone or row.zone
    row.locations=row.locations or {}
    -- These are the player's sighting coordinates, never claimed as exact beast coordinates.
    if map and zone then
        local pos=query(C_Map.GetPlayerMapPosition,map,'player')
        local x,y
        if pos and safe(pos) then x,y=query(pos.GetXY,pos);x=number(x);y=number(y) end
        local location={mapID=map,zone=zone,subzone=subzone,x=x,y=y}
        local last=row.locations[#row.locations]
        if not last or last.mapID~=map or (x and y and (not last.x or math.abs(last.x-x)+math.abs((last.y or y)-y)>0.03)) then
            if #row.locations>=5 then table.remove(row.locations,1) end
            row.locations[#row.locations+1]=location
        end
    end
    return id,row
end
-- Resolve each field independently: observed data, Petopia Forever, Wowhead Forever,
-- then our legacy Classic reference (Petopia's Wowhead Classic-linked facts).
function F.BeastRecord(id)
    local result,sources={},{}
    local localRow=F.db and F.db.beastJournal and F.db.beastJournal.records and F.db.beastJournal.records[id]
    local rows={{localRow,'Observed in Forever'},{F.petopiaForeverCreatures and F.petopiaForeverCreatures[id],'Petopia Forever'},
        {F.petopiaCommunityCreatures and F.petopiaCommunityCreatures[id],'Petopia community report (unverified)'},
        {F.foreverPetCreatureDB and F.foreverPetCreatureDB[id],'Wowhead Forever'},
        {F.petCreatureDB and F.petCreatureDB[id],'Classic reference (Wowhead Classic-linked)'}}
    for _,pair in ipairs(rows) do
        local row,label=pair[1],pair[2]
        if row then
            for _,field in ipairs({'name','family','zone','minLevel','maxLevel','tameable','diet','abilities'}) do
                local value=row[field]
                if field=='abilities' and row==localRow then value=row.tameAbilities or row.loreAbilities end
                if value~=nil and result[field]==nil then
                    result[field]=value;sources[field]=(field=='abilities' and row.abilityReference) or label
                    if row==localRow and field=='abilities' then sources[field]=row.tameAbilities and 'Observed fresh tame' or 'Observed Beast Lore' end
                end
            end
        end
    end
    result.sources=sources
    return next(sources) and result or nil
end
function F.BeastDiet(family)
    local row=F.petopiaForeverFamilies and F.petopiaForeverFamilies[family]
    if row and row.diet then return row.diet,'Petopia Forever' end
    if F.foreverPetFamilyDiets and F.foreverPetFamilyDiets[family] then return F.foreverPetFamilyDiets[family],'Wowhead Forever' end
    return F.petFamilyDiets and F.petFamilyDiets[family],'Classic reference (Wowhead Classic-linked)'
end
function F.BeastSourceURLs(id)
    local row=(F.petopiaForeverCreatures and F.petopiaForeverCreatures[id]) or (F.petopiaCommunityCreatures and F.petopiaCommunityCreatures[id])
    return row and row.source,'https://www.wowhead.com/forever/npc='..id,'https://www.wowhead.com/classic/npc='..id
end
function F.BeastTeachers(key,rank,fallback)
    local rows,ids={},{}
    local function add(row) if not ids[row.id] then ids[row.id]=true;rows[#rows+1]=row end end
    for id,row in pairs(F.db and F.db.beastJournal and F.db.beastJournal.records or {}) do
        for _,spell in ipairs(row.tameSpells or {}) do
            if spell.key==key and spell.rank==rank then
                add({id=id,name=row.name or ('NPC '..id),family=row.family or 'Unknown',levels=tostring(row.minLevel or '?'),zone=row.zone or 'Unknown',reference='Observed fresh tame'})
            end
        end
    end
    local ranks=F.petopiaForeverTeachers and F.petopiaForeverTeachers[key]
    for _,row in ipairs(ranks and ranks[rank] or {}) do add(row) end
    ranks=F.petopiaCommunityTeachers and F.petopiaCommunityTeachers[key]
    for _,row in ipairs(ranks and ranks[rank] or {}) do add(row) end
    for _,row in ipairs(fallback or {}) do add(row) end
    return rows
end
function F.BeastCollectionEnabled() return enabled() end
local function json(value)
    if type(value)=='string' then
        return '"'..value:gsub('[%z\1-\31\\"]',function(c)
            if c=='"' then return '\\"' elseif c=='\\' then return '\\\\' end
            return ('\\u%04x'):format(c:byte())
        end)..'"'
    elseif type(value)=='number' then return value==value and tostring(value) or 'null'
    elseif type(value)=='boolean' then return tostring(value)
    elseif type(value)~='table' then return 'null' end
    local keys={};for k in pairs(value) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local parts={};for _,k in ipairs(keys) do parts[#parts+1]=json(tostring(k))..':'..json(value[k]) end
    return '{'..table.concat(parts,',')..'}'
end
function F.ExportBeastJournal()
    enabled()
    return json({schema=1,addon='HunterTools',version=F.VERSION or 'development',records=F.db.beastJournal.records})
end
function F.BeastJournalCounts()
    enabled();local sightings,tames=0,0
    for _,row in pairs(F.db.beastJournal.records) do sightings=sightings+1;if row.tamedAt then tames=tames+1 end end
    return sightings,tames
end
-- Keep reported new skills browsable without inventing spell IDs or pet-level requirements.
for key,ranks in pairs(F.petopiaCommunityTeachers or {}) do
    local group
    for _,ability in ipairs(F.petBrowserAbilities or {}) do if ability.key==key then group=ability;break end end
    if not group then
        group={key=key,name=F.petopiaCommunityAbilityNames[key],ranks={}}
        F.petBrowserAbilities=F.petBrowserAbilities or {};F.petBrowserAbilities[#F.petBrowserAbilities+1]=group
    end
    for rank in pairs(ranks) do
        local found=false;for _,r in ipairs(group.ranks) do if r.rank==rank then found=true end end
        if not found then group.ranks[#group.ranks+1]={rank=rank,animals={},classicSource='unknown',reference='Petopia community report (unverified)'} end
    end
    table.sort(group.ranks,function(a,b) return a.rank<b.rank end)
end
if F.petBrowserAbilities then table.sort(F.petBrowserAbilities,function(a,b) return a.name<b.name end) end
local pending
function F.BeginBeastTame(castGUID)
    if pending and pending.castGUID==castGUID then return end
    pending=nil
    if query(InCombatLockdown) then return end
    if query(UnitExists,'pet') then return end
    local id,row=F.ObserveBeast('target')
    if id and row then pending={id=id,at=clock(),castGUID=castGUID,family=row.family} end
end
function F.CaptureFreshTame()
    if not pending then return end
    if clock()-pending.at>30 or not enabled() then pending=nil;return end
    if query(InCombatLockdown) then return end
    local guid=text(query(UnitGUID,'pet'))
    if not guid or not guid:match('^Pet%-') then return end
    if pending.petGUID and pending.petGUID~=guid then pending=nil;return end
    if pending.petAt and clock()-pending.petAt>5 then pending=nil;return end
    pending.petGUID=guid;pending.petAt=pending.petAt or clock()
    local family=text(query(UnitCreatureFamily,'pet'))
    if pending.family and family and pending.family~=family then pending=nil;return end
    local book=C_SpellBook
    local n=number(query(book and book.HasPetSpells or HasPetSpells))
    if not n or n<1 or n>200 then return end
    local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    local snapshot,raw={},{}
    for i=1,n do
        local info=bank and query(book and book.GetSpellBookItemInfo,i,bank)
        local id=type(info)=='table' and number(info.spellID)
        if not id and GetSpellBookItemInfo then local _,legacy=query(GetSpellBookItemInfo,i,'pet');id=number(legacy) end
        if not id then return end -- Incomplete spellbook: retry, never infer an empty ability list.
        local name=text(query(C_Spell and C_Spell.GetSpellName,id))
        raw[#raw+1]={spellID=id,name=name}
        for _,ability in ipairs(F.petBrowserAbilities or {}) do
            for _,r in ipairs(ability.ranks) do
                if r.spellID==id and r.classicSource~='t' then snapshot[#snapshot+1]={spellID=id,key=ability.key,name=ability.name,rank=r.rank} end
            end
        end
    end
    local row=record(pending.id)
    if row then
        row.tameable=true;row.family=family or row.family;row.tamedAt=stamp()
        row.tameLevel=number(query(UnitLevel,'pet'));row.petAttackSpeed=number(query(UnitAttackSpeed,'pet'))
        row.tameSpells=snapshot
        row.petSpellbook=raw -- Retain unknown spells for later database research.
        local skills={};for _,spell in ipairs(snapshot) do skills[#skills+1]=spell.name..' '..spell.rank end
        row.tameAbilities=#skills>0 and table.concat(skills,'; ') or nil
        local foods=query(C_PetInfo and C_PetInfo.GetPetFoodTypes)
        if type(foods)=='table' then
            local clean={};for _,food in ipairs(foods) do if text(food) then clean[#clean+1]=food end end
            if #clean>0 then row.diet=table.concat(clean,', ');row.dietSource='Observed fresh tame' end
        end
    end
    pending=nil
end
local frame=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_TARGET_CHANGED','UPDATE_MOUSEOVER_UNIT','UNIT_SPELLCAST_SENT','UNIT_SPELLCAST_CHANNEL_START','UNIT_SPELLCAST_SUCCEEDED','UNIT_SPELLCAST_FAILED','UNIT_SPELLCAST_INTERRUPTED','UNIT_PET','PET_BAR_UPDATE','PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED'}) do frame:RegisterEvent(event) end
frame:SetScript('OnEvent',function(_,event,unit,castGUID,spellID,sentSpellID)
    if not enabled() then pending=nil;return end
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return end
    if event=='PLAYER_TARGET_CHANGED' then F.ObserveBeast('target')
    elseif event=='UPDATE_MOUSEOVER_UNIT' then F.ObserveBeast('mouseover')
    elseif event=='PLAYER_ENTERING_WORLD' then pending=nil;seen={}
    elseif event=='UNIT_SPELLCAST_SENT' and unit=='player' and number(sentSpellID)==1515 then
        -- SENT includes target name before cast GUID; capture identity before taming enters combat.
        F.BeginBeastTame(spellID)
    elseif unit=='player' and number(spellID)==1515 then
        if event=='UNIT_SPELLCAST_CHANNEL_START' then F.BeginBeastTame(castGUID)
        elseif event=='UNIT_SPELLCAST_SUCCEEDED' and pending and pending.castGUID==castGUID then
            F.CaptureFreshTame()
            if C_Timer and C_Timer.After then
                local token=pending
                for _,delay in ipairs({0.5,1.5,3}) do C_Timer.After(delay,function() if pending==token and token then F.CaptureFreshTame() end end) end
            end
        elseif event=='UNIT_SPELLCAST_FAILED' or event=='UNIT_SPELLCAST_INTERRUPTED' then pending=nil end
    elseif event=='UNIT_PET' and unit=='player' or event=='PET_BAR_UPDATE' or event=='PLAYER_REGEN_ENABLED' then
        F.CaptureFreshTame()
        if pending and C_Timer and C_Timer.After then
            local token=pending
            C_Timer.After(0.5,function() if pending==token then F.CaptureFreshTame() end end)
        end
    end
end)
