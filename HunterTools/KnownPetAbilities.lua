local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
function F.RememberPetAbility(name,rank)
    if not F.db or not safe(name) or type(name)~='string' or not rank then return end
    F.db.knownPetAbilities=F.db.knownPetAbilities or {}
    local key=name:lower()
    F.db.knownPetAbilities[key]=math.max(F.db.knownPetAbilities[key] or 0,rank)
end
function F.ScanForeverPetTraining()
    if not F.db or InCombatLockdown() or not C_Trainer or not C_Trainer.GetTrainerType
        or not Enum or not Enum.TrainerType or not GetNumTrainerServices or not GetTrainerServiceInfo then return end
    if C_Trainer.GetTrainerType()~=Enum.TrainerType.Pet then return end
    local n=GetNumTrainerServices()
    if not safe(n) or type(n)~='number' or n==0 then return end
    F.db.petTrainingScanned=true
    for i=1,n do
        local name,state,_,_,sub=GetTrainerServiceInfo(i)
        if safe(name) and safe(state) and safe(sub) and type(name)=='string' then
            local rank=type(sub)=='string' and tonumber(sub:match('(%d+)')) or 1
            if state=='available' or state=='used' then F.RememberPetAbility(name,rank) end
        end
    end
end
function F.LearnedPetAbilityMessage(message)
    if not F.db or not safe(message) or type(message)~='string' then return end
    for _,format in ipairs({ERR_LEARN_ABILITY_S or '',ERR_LEARN_SPELL_S or ''}) do
        if format~='' then
            local pattern=format:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])','%%%1'):gsub('%%%%s','(.+)')
            local ability=message:match('^'..pattern..'$')
            if ability then
                ability=ability:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|H.-|h(.-)|h','%1')
                local name,rank=ability:match('^(.-)%s*%([Rr]ank%s+(%d+)%)$')
                if name and rank then F.RememberPetAbility(name,tonumber(rank)) end
            end
        end
    end
end
function F.ScanKnownPetAbilities()
    F.ScanForeverPetTraining()
    if not F.db or InCombatLockdown() or not GetCraftDisplaySkillLine or not GetNumCrafts or not GetCraftInfo then return end
    local title=GetCraftDisplaySkillLine()
    local training=C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(5149)
    if not safe(title) or not safe(training) or not training or title~=training then return end
    local n=GetNumCrafts()
    if not safe(n) or type(n)~='number' or n==0 then return end
    F.db.knownPetAbilities=F.db.knownPetAbilities or {}
    local names={}
    for i=1,n do
        local name,sub,craftType=GetCraftInfo(i)
        if safe(name) and safe(sub) and safe(craftType) and craftType~='header' and type(name)=='string' then
            local rank=type(sub)=='string' and tonumber(sub:match('(%d+)')) or 1
            if rank then
                local key=name:lower()
                F.db.knownPetAbilities[key]=math.max(F.db.knownPetAbilities[key] or 0,rank)
                names[key]=true
            end
        end
    end
    F.db.petAbilityScanNames=names
end
function F.MarkTargetAbilities(text)
    F.ScanKnownPetAbilities()
    local known=F.db.knownPetAbilities or {}
    local seen=F.db.petAbilityScanNames or {}
    return (text:gsub('([^;]+)',function(part)
        local name,rank=part:match('^%s*(.-)%s+[Rr]ank%s+(%d+)')
        if not name then name,rank=part:match('^%s*(.-)%s+(%d+)') end
        if not name or not rank then return part end
        local key=name:lower(); rank=tonumber(rank)
        if known[key] and known[key]>=rank then return part..' |cff33ff66[Learned]|r' end
        -- Missing from the cached training list; confirmed entries accumulate.
        if seen[key] or F.db.petTrainingScanned then return '|cffff5555'..part..' [Not Learned]|r' end
        return part..' [Learned status unavailable]'
    end))
end
local events=CreateFrame('Frame')
-- Craft events are absent on some Forever clients. Never register an
-- unsupported event; the range display also refreshes this cache on demand.
if C_EventUtils and C_EventUtils.IsEventValid then
    for _,event in ipairs({'CRAFT_SHOW','CRAFT_UPDATE','TRAINER_SHOW','TRAINER_UPDATE','CHAT_MSG_SYSTEM'}) do
        if C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
    end
end
events:SetScript('OnEvent',function(_,event,message) if event=='CHAT_MSG_SYSTEM' then F.LearnedPetAbilityMessage(message) else F.ScanKnownPetAbilities() end end)

function F.DebugPetTraining()
    if InCombatLockdown() then F.Print('Check training after combat.'); return end
    local lines={}
    local function add(s) lines[#lines+1]=s; F.Print(s) end
    for _,name in ipairs({'GetCraftDisplaySkillLine','GetNumCrafts','GetCraftInfo','GetCraftSpellFocus','CraftFrame'}) do
        add(name..': '..type(_G[name]))
    end
    for _,ns in ipairs({'C_PetInfo','C_CraftInfo','C_TradeSkillUI','C_BeastTraining'}) do
        local api=_G[ns]; local names={}
        if type(api)=='table' then
            for key,value in pairs(api) do
                if type(value)=='function' and (key:lower():find('train') or key:lower():find('craft') or key:lower():find('spell') or key:lower():find('recipe') or key:lower():find('profession')) then names[#names+1]=key end
            end
        end
        table.sort(names); add(ns..': '..table.concat(names,', '))
    end
    if GetCraftDisplaySkillLine then local ok,title=pcall(GetCraftDisplaySkillLine); add('Craft title: '..(ok and tostring(title) or 'unavailable')) end
    if GetNumCrafts then local ok,n=pcall(GetNumCrafts); add('Craft count: '..(ok and tostring(n) or 'unavailable')) end
    if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
        local ok,info=pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if ok and type(info)=='table' then
            for _,key in ipairs({'professionName','professionID','skillLevel','parentProfessionID'}) do add(key..': '..tostring(info[key])) end
        end
    end
    F.db.petTrainingDebug=lines
end
