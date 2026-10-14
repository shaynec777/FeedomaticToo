local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
function F.TargetPetDetails()
    if not UnitExists('target') then return nil end
    local s=F.RangeSettings()
    if not s.showPetAbilities and not s.showPetDiet then return nil end
    if InCombatLockdown() then return 'Pet details unavailable in combat.' end
    local family=UnitCreatureFamily and UnitCreatureFamily('target')
    if not safe(family) or type(family)~='string' or family=='' then return nil end
    local guid=UnitGUID and UnitGUID('target')
    local npcID=safe(guid) and type(guid)=='string' and guid:match('^Creature%-.*%-(%d+)%-%x+$')
    local record=npcID and F.petCreatureDB and F.petCreatureDB[tonumber(npcID)]
    local lines={}
    local level=UnitLevel and UnitLevel('target')
    if s.showPetAbilities then
        lines[#lines+1]=family..(safe(level) and type(level)=='number' and level>0 and (' - level '..level) or '')
    end
    local diet,abilities
    local tip=C_TooltipInfo and C_TooltipInfo.GetUnit and C_TooltipInfo.GetUnit('target')
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
    if not abilities and record then abilities=record.abilities; baseline=s.showPetAbilities end
    if not diet and F.petFamilyDiets then diet=F.petFamilyDiets[family]; baseline=baseline or (s.showPetDiet and diet~=nil) end
    if abilities and F.MarkTargetAbilities then abilities=F.MarkTargetAbilities(abilities) end
    if s.showPetAbilities then lines[#lines+1]='Abilities: '..(abilities or 'no database record; inspect with Beast Lore.') end
    if s.showPetDiet then lines[#lines+1]='Eats: '..(diet or 'not revealed; inspect with Beast Lore.') end
    if baseline then lines[#lines+1]='Classic baseline - Forever may differ.' end
    return #lines>0 and table.concat(lines,'\n') or nil
end
