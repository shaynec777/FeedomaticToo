local F={db={}}
CreateFrame=function() return {RegisterEvent=function() error('unknown event must not be registered') end,SetScript=function() end} end
C_EventUtils={IsEventValid=function() return false end}
assert(loadfile('HunterTools/KnownPetAbilities.lua'))('test',F)
InCombatLockdown=function() return false end
C_Spell={GetSpellName=function() return 'Beast Training' end}
GetCraftDisplaySkillLine=function() return 'Beast Training' end
GetNumCrafts=function() return 1 end
GetCraftInfo=function() return 'Bite','Rank 1','used' end
assert(F.MarkTargetAbilities('Bite 2 (pet level 8)'):find('[Not Learned]',1,true))
assert(F.MarkTargetAbilities('Bite Rank 1'):find('[Learned]',1,true))
assert(F.MarkTargetAbilities('Charge 1'):find('status unavailable',1,true))
GetCraftInfo=function() return 'Bite','Rank 2','used' end
assert(F.MarkTargetAbilities('Bite 2'):find('[Learned]',1,true))
GetCraftDisplaySkillLine=function() return 'Enchanting' end
GetCraftInfo=function() error('must not scan other professions') end
assert(F.MarkTargetAbilities('Bite 2'):find('[Learned]',1,true))
print('PASS: training cache, missing ranks, learned ranks, unknown abilities and profession guard')

C_Trainer={GetTrainerType=function() return 1 end}; Enum={TrainerType={Pet=1}}
GetNumTrainerServices=function() return 2 end
GetTrainerServiceInfo=function(i) return i==1 and 'Charge' or 'Claw', i==1 and 'available' or 'used',nil,1,'Rank 2' end
F.ScanForeverPetTraining(); assert(F.db.knownPetAbilities.charge==2 and F.db.knownPetAbilities.claw==2)
ERR_LEARN_ABILITY_S='You have learned a new ability: %s.'
F.LearnedPetAbilityMessage('You have learned a new ability: Bite (Rank 3).')
assert(F.db.knownPetAbilities.bite==3)
F.LearnedPetAbilityMessage('Someone mentions Bite (Rank 9).'); assert(F.db.knownPetAbilities.bite==3)
print('PASS: Forever trainer services and automatic learned-ability messages')

local missing=F.MarkTargetAbilities('Scorpid Poison 1 (pet level 8)')
assert(missing:find('|cffff5555',1,true) and missing:find('[Not Learned]',1,true))
local learned=F.MarkTargetAbilities('Claw 2')
assert(learned:find('|cff33ff66[Learned]|r',1,true))
print('PASS: green Learned and red Not Learned labels after training scan')
