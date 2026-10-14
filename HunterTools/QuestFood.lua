local _, F = ...

-- Temporary protection, rebuilt from the current log and bags. Never write to
-- the user's food lists. Completed objectives remain relevant until turn-in.
local function clean(text)
    if not F.IsPublic(text) or type(text) ~= 'string' then return nil end
    return (text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
        :gsub('|H.-|h(.-)|h','%1'):gsub('^%s+',''):gsub('%s+$',''))
end

function F.ScanQuestFood()
    if InCombatLockdown and InCombatLockdown() then return end
    F.questFood = {}
    if not F.db.protectQuestFood then return end
    local byName, active, names = {}, {}, {}
    for id in pairs(F.foodCatalog or {}) do names[id] = clean(C_Item.GetItemInfo(id)) end
    local function objective(text, kind, title, fulfilled, required)
        if kind ~= 'item' then return end
        text = clean(text)
        if not text then return end
        -- Classic exposes objective text rather than item IDs. Match a whole
        -- name, never a substring (e.g. meat must not match cooked meat).
        local name = text:match('^%d+%s*/%s*%d+%s+(.+)$')
            or text:match('^(.-):%s*%d+%s*/%s*%d+%s*$')
        if name then byName[clean(name)] = title end
        if not name and QUEST_ITEM_NEEDED and fulfilled and required then
            for _, itemName in pairs(names) do
                if itemName then
                    local ok, formatted = pcall(string.format, QUEST_ITEM_NEEDED, itemName, fulfilled, required)
                    if ok and clean(formatted) == text then byName[clean(itemName)] = title end
                end
            end
        end
    end
    local modern = C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo
    local entries = modern and C_QuestLog.GetNumQuestLogEntries() or
        (GetNumQuestLogEntries and GetNumQuestLogEntries() or 0)
    for index = 1, entries do
        local title, header, questID
        if modern then
            local info = C_QuestLog.GetInfo(index)
            if info then title, header, questID = info.title, info.isHeader, info.questID end
        elseif GetQuestLogTitle then
            local t, _, _, h, _, _, _, id = GetQuestLogTitle(index)
            title, header, questID = t, h, id
        end
        title = clean(title)
        if title and not header then
            if questID then active[questID] = title end
            if questID and C_QuestLog and C_QuestLog.GetQuestObjectives then
                for _, entry in ipairs(C_QuestLog.GetQuestObjectives(questID) or {}) do
                    objective(entry.text, entry.type, title, entry.numFulfilled, entry.numRequired)
                end
            elseif GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
                for n = 1, GetNumQuestLeaderBoards(index) do
                    local text, kind = GetQuestLogLeaderBoard(n, index)
                    objective(text, kind, title)
                end
            end
        end
    end
    for id, name in pairs(names) do
        if name and byName[name] then F.questFood[id] = byName[name] end
    end
    -- Native bag flags also cover objectives under collapsed quest-log headers
    -- and food absent from our catalog. A quest starter alone is not protected.
    for bag = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemInfo(bag, slot)
            if item and F.IsPublic(item.itemID) and item.itemID then
                local id = item.itemID
                local name = clean(C_Item.GetItemInfo(id))
                if name and byName[name] then F.questFood[id] = byName[name] end
                local q = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag,slot)
                if q and F.IsPublic(q.isQuestItem) and q.isQuestItem then
                    local title = F.IsPublic(q.questID) and active[q.questID]
                    F.questFood[id] = F.questFood[id] or title or 'current quest (client-marked item)'
                end
            end
        end
    end
end

function F.QuestFoodReason(id)
    if F.db.protectQuestFood and F.questFood then return F.questFood[id] end
end

-- Explicit diagnostic only: preserve the actual client responses for debugging
-- without changing quests, feeding, or sending messages to other players.
function F.DebugQuestFood()
    if InCombatLockdown() then F.Print('Run questdebug after combat.'); return end
    local lines={}
    local function value(v)
        if not F.IsPublic(v) then return '<restricted>' end
        if type(v)=='table' then
            local fields={}
            for k,x in pairs(v) do
                if type(x)~='table' and type(x)~='function' then
                    fields[#fields+1]=tostring(k)..'='..(F.IsPublic(x) and tostring(x) or '<restricted>')
                end
            end
            table.sort(fields); return '{'..table.concat(fields,', ')..'}'
        end
        return tostring(v)
    end
    local function add(text) lines[#lines+1]=text end
    local function call(label,fn,...)
        if type(fn)~='function' then add(label..': unavailable'); return end
        local function pack(...) return {n=select('#',...),...} end
        local result=pack(pcall(fn,...))
        if not result[1] then add(label..': ERROR '..value(result[2])); return end
        local fields={}
        for i=2,result.n do fields[#fields+1]=value(result[i]) end
        add(label..': '..table.concat(fields,' | '))
        return result[2]
    end
    add('HunterTools '..F.VERSION..'; protection='..value(F.db.protectQuestFood))
    local q=C_QuestLog or {}
    call('Classic entry count',GetNumQuestLogEntries)
    call('Modern entry count',q.GetNumQuestLogEntries)
    -- The currently tested quest; querying by ID also diagnoses collapsed headers.
    call('Restocking active (92553)',q.IsOnQuest,92553)
    local objectives=call('Restocking objectives',q.GetQuestObjectives,92553)
    if type(objectives)=='table' then
        for k,entry in pairs(objectives) do add('  objective '..value(k)..': '..value(entry)) end
    end
    local modern=q.GetNumQuestLogEntries and q.GetInfo
    local n=modern and q.GetNumQuestLogEntries() or (GetNumQuestLogEntries and GetNumQuestLogEntries() or 0)
    for i=1,n do
        if modern then call('Log '..i,q.GetInfo,i)
        else call('Log '..i,GetQuestLogTitle,i) end
        if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
            local count=GetNumQuestLeaderBoards(i)
            for j=1,count do call('  legacy objective '..j,GetQuestLogLeaderBoard,j,i) end
        end
    end
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        for slot=1,C_Container.GetContainerNumSlots(bag) do
            local item=C_Container.GetContainerItemInfo(bag,slot)
            if item and F.IsPublic(item.itemID) and item.itemID==5469 then
                call('Strider Meat bag '..bag..' slot '..slot,C_Container.GetContainerItemQuestInfo,bag,slot)
            end
        end
    end
    call('Strider Meat item name',C_Item.GetItemInfo,5469)
    add('Current protection: '..value(F.QuestFoodReason(5469)))
    F.db.questDebug=lines
    F.Print('Quest diagnostics saved. Run /reload so Codex can read the saved report.')
    for i=1,math.min(8,#lines) do F.Print(lines[i]) end
end
