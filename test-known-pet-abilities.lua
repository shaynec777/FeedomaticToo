local F={db={}}
local registered,handler={},nil
CreateFrame=function() return {RegisterEvent=function(_,event) assert(event=='CHAT_MSG_SYSTEM','unknown event must not be registered'); registered[event]=true end,SetScript=function(_,_,fn) handler=fn end} end
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

-- Reproduce automatic hunter learning before opening Beast Training.
C_Trainer=nil; GetCraftDisplaySkillLine=function() return 'Enchanting' end
F.db.knownPetAbilities.cower=nil
handler(nil,'CHAT_MSG_SYSTEM','You have learned a new ability: |cff71d5ff|Hspell:1754|h[Cower]|h|r.')
assert(F.db.knownPetAbilities.cower==3)
assert(F.MarkTargetAbilities('Cower 3'):find('|cff33ff66[Learned]|r',1,true))
assert(F.MarkTargetAbilities('Cower 4'):find('[Not Learned]',1,true))
handler(nil,'CHAT_MSG_SYSTEM','You have learned a new ability: Cower (Rank 2).')
assert(F.db.knownPetAbilities.cower==3,'lower ranks must not erase higher ranks')
F.db.knownPetAbilities.cower=nil
handler(nil,'CHAT_MSG_SYSTEM','Your pet has learned a new spell: |Hspell:1754|h[Cower]|h.')
assert(F.db.knownPetAbilities.cower==nil,'pet spell acquisition is not hunter learning')
handler(nil,'CHAT_MSG_SYSTEM','You have learned a new ability: Cower.')
assert(F.db.knownPetAbilities.cower==nil,'do not guess a missing rank')
assert(F.db.lastPetAbilityLearning.recognized==false)
ERR_LEARN_SPELL_S='You have learned a new spell: %s.'
local cowerMessage='You have learned a new spell: |cff71d5ff|Hspell:1748:0|h[Cower]|h|r.'
F.db.lastPetAbilityLearning={message=cowerMessage,recognized=false,spellID=1748}
F.ReplayPetAbilityLearning()
assert(F.db.knownPetAbilities.cower==2,'captured hunter-training spell must recover Cower 2 after reload')
assert(F.db.lastPetAbilityLearning.recognized and F.db.lastPetAbilityLearning.rank==2)
assert(F.MarkTargetAbilities('Cower 2'):find('|cff33ff66[Learned]|r',1,true))
assert(F.MarkTargetAbilities('Cower 3'):find('[Not Learned]',1,true))
F.db.knownPetAbilities.cower=nil
handler(nil,'CHAT_MSG_SYSTEM',cowerMessage)
assert(F.db.knownPetAbilities.cower==2,'live hunter-training spell message must update immediately')
C_Spell.GetSpellSubtext=function(id) assert(id==999999); return 'Rank 4' end
handler(nil,'CHAT_MSG_SYSTEM','You have learned a new ability: |Hspell:999999|h[Cower]|h.')
assert(F.db.knownPetAbilities.cower==4,'client subtext handles new Forever spell IDs')
C_Spell.GetSpellSubtext=nil
handler(nil,'CHAT_MSG_SKILL','You have learned a new ability: Cower Rank 5.')
assert(F.db.knownPetAbilities.cower==5)
issecretvalue=function(v) return v=='secret message' end
handler(nil,'CHAT_MSG_SYSTEM','secret message'); assert(F.db.knownPetAbilities.cower==5)
issecretvalue=nil
assert(registered.CHAT_MSG_SYSTEM)
local fallbackRegistered=false
C_EventUtils=nil
CreateFrame=function() return {RegisterEvent=function(_,event) assert(event=='CHAT_MSG_SYSTEM');fallbackRegistered=true end,SetScript=function() end} end
assert(loadfile('HunterTools/KnownPetAbilities.lua'))('test',{db={}})
assert(fallbackRegistered,'listen for learning even without event validator')
print('PASS: Cower hyperlink, rank display, subtext, pet-vs-hunter guard, secret guard and event fallback')
