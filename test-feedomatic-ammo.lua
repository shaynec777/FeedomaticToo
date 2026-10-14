local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F)
assert(loadfile('HunterTools/AmmoCatalog.lua'))('test',F)
assert(loadfile('HunterTools/Ammo.lua'))('test',F)
assert(loadfile('HunterTools/AmmoUI.lua'))('test',F)
HunterToolsDB={}
F.LoadSettings()
assert(F.db.ammo.enabled==false and F.db.ammo.minimum==200 and F.db.ammo.minutes==5)
F.db.ammo.enabled=true; F.LoadSettings(); assert(F.db.ammo.enabled==true, 'explicit enabled preference survives loading')
local now,combat,class,dead=100,false,'HUNTER',false
local equipped,weapon=2512,999
local chats,screens,sounds,scans=0,0,0,0
local bags={[0]={{itemID=2512,stackCount=80}},[1]={{itemID=2512,stackCount=90,isLocked=true},{itemID=2516,stackCount=500}}}
NUM_TOTAL_EQUIPPED_BAG_SLOTS=1
GetTime=function() return now end
InCombatLockdown=function() return combat end
UnitClass=function() return class,class end
UnitIsDeadOrGhost=function() return dead end
GetInventoryItemID=function(_,slot) assert(not combat); return slot==0 and equipped or (slot==18 and weapon or nil) end
C_Container={GetContainerNumSlots=function(b) assert(not combat); scans=scans+1; return #(bags[b] or {}) end,
    GetContainerItemInfo=function(b,s) return bags[b][s] end}
C_Item={GetItemInfo=function(id) return nil end,
    GetItemInfoInstant=function(id)
        if id==999 then return id,nil,nil,nil,nil,2,2 end
        if id==998 then return id,nil,nil,nil,nil,2,3 end
        return id,nil,nil,nil,nil,6,2
    end}
DEFAULT_CHAT_FRAME={AddMessage=function() chats=chats+1 end}
RaidWarningFrame={}; RaidNotice_AddMessage=function() screens=screens+1 end
PlaySound=function(_,channel) assert(channel=='Master'); sounds=sounds+1 end
F.CheckAmmoReminder(); assert(screens==0,'empty selection silent')
F.db.ammo.selected={[2512]=true,[2516]=true}; F.db.ammo.minimums={[2512]=180,[2516]=600}
F.CheckAmmoReminder(); assert(screens==2 and F.ammoCounts[2512]==170,'multiple thresholds')
local oldScans=scans; F.CheckAmmoReminder(); assert(screens==2 and scans==oldScans)
F.db.ammo.selected[2512]=nil; now=400; F.CheckAmmoReminder(); assert(screens==3,'unchecked stops')
F.db.ammo.selected={}; now=800; F.CheckAmmoReminder(); assert(screens==3)
F.db.ammo.selected={[2512]=true,[2516]=true}; F.ResetAmmoReminder(); F.db.ammo.minutes=0
F.CheckAmmoReminder(); assert(screens==5); now=2000; F.CheckAmmoReminder(); assert(screens==5)
bags[0][1].stackCount=200; F.ammoDirty=true; F.CheckAmmoReminder(); assert(not F.ammoAlerts[2512])
bags[0][1].stackCount=1; F.ammoDirty=true; F.CheckAmmoReminder(); assert(screens==6)
bags[0]={}; bags[1][1].stackCount=0; F.ammoDirty=true; F.CheckAmmoReminder(); assert(screens==7)
combat=true; F.ammoDirty=true; F.CheckAmmoReminder(); assert(screens==7 and F.ammoDirty)
combat=false; F.CheckAmmoReminder(); assert(not F.ammoDirty)
class='MAGE'; F.CheckAmmoReminder(); assert(screens==7)
class='HUNTER'; dead=true; F.CheckAmmoReminder(); assert(screens==7)
dead=false; F.db.ammo.enabled=false; F.CheckAmmoReminder(); assert(screens==7)
F.db.ammo.enabled=true; F.db.ammo.mode='both'; F.db.ammo.sound=true; F.CheckAmmoReminder()
assert(screens==9 and chats==2 and sounds==2)
F.db.ammo.minimums[2512]=0; F.ResetAmmoReminder(2512); F.CheckAmmoReminder(); assert(screens==10)
local before=F.ammoAlerts[2512]; F.ShowAmmoReminder(2512,0,true); assert(F.ammoAlerts[2512]==before)
F.db.ammo.selected={}; F.LoadSettings(); assert(next(F.db.ammo.selected)==nil)
F.db.ammo.selected=nil; F.db.ammo.itemID=2516; F.db.ammo.minimum=420; F.LoadSettings()
assert(F.db.ammo.selected[2516] and F.AmmoMinimum(2516)==420 and F.db.ammo.itemID==nil)
F.db.ammo.selected={}; F.LoadSettings(); assert(next(F.db.ammo.selected)==nil)
F.db.ammo.minimum=200
bags[0]={{itemID=777,stackCount=10}}; F.ScanAmmo(); assert(F.ammoCatalog[777])
F.IsPublic=function(v) return v~='secret' end
bags[0][1].stackCount='secret'; F.ammoDirty=true; assert(not F.ScanAmmo() and F.ammoDirty)
F.IsPublic=function() return true end
F.db.ammo.selected={[2512]=true}; F.db.ammo.minimums[2512]=200
F.db.ammo.enabled=true; F.db.ammo.mode='screen'; F.db.ammo.sound=false
F.ResetAmmoReminder(); now=3000; bags[0]={}; bags[1]={}
local entryScreens=screens
F.QueueAmmoEntryScan(); F.CheckAmmoReminder(); assert(screens==entryScreens)
now=3010; F.CheckAmmoReminder(); assert(screens==entryScreens,'first empty scan is not a warning')
bags[0]={{itemID=2512,stackCount=1000}}; now=3011; F.CheckAmmoReminder()
now=3012; F.CheckAmmoReminder(); assert(screens==entryScreens and F.ammoCounts[2512]==1000)
F.QueueAmmoEntryScan(); bags[0]={{itemID=2512,stackCount=50}}
now=3022; F.CheckAmmoReminder(); assert(screens==entryScreens)
now=3023; F.CheckAmmoReminder(); assert(screens==entryScreens+1,'confirmed low ammo still warns')
F.db.ammo.selected={[2512]=true}; F.ResetAmmoReminder(); F.ammoDirty=true
bags[0]={}; bags[1]={}
C_Item.GetItemCount=function(id,bank,charges) assert(id==2512 and bank==false and charges==false); return 1000 end
local countScreens=screens; F.CheckAmmoReminder()
assert(F.ammoCounts[2512]==1000 and screens==countScreens,'client carried total prevents false low equipped-ammo warning')
F.ammoCounts[2512]=0; F.ammoDirty=false; F.ResetAmmoReminder()
F.CheckAmmoReminder(); assert(screens==countScreens and F.ammoCounts[2512]==1000,'stale zero cache must not alert')
C_Item.GetItemCount=nil
F.db.ammo.lastEquipped=2512; weapon=nil; equipped=nil
F.ResetAmmoReminder(); F.ammoDirty=true; bags[0]={}; bags[1]={}
local loadingScreens=screens
assert(not F.ScanAmmo(),'missing equipment during loading must not commit zero count')
F.CheckAmmoReminder(); assert(screens==loadingScreens and F.ammoDirty)
weapon=999; equipped=2512; bags[0]={{itemID=2512,stackCount=1213}}
F.CheckAmmoReminder(); assert(screens==loadingScreens and F.ammoCounts[2512]==1213)
bags[0]={}; equipped=nil; F.ammoDirty=true
F.CheckAmmoReminder(); assert(screens==loadingScreens+1,'genuine exhaustion with loaded weapon still alerts')
print('PASS: per-ammo minimums, multiple/empty selections, migration, cadence, restock, combat and channels')

-- Build the actual settings tree and exercise its callbacks with frame mocks.
bags[0]={}; F.IsPublic=function() return true end
local frames={}
local methods={}
local function frame()
    local f={scripts={},shown=true,text=''}; setmetatable(f,{__index=methods}); frames[#frames+1]=f; return f
end
for _,name in ipairs({'SetSize','SetPoint','SetFrameStrata','SetMovable','EnableMouse','RegisterForDrag','SetBackdrop','SetWidth','SetJustifyH','SetAutoFocus','SetMaxLetters','SetTexture','RegisterEvent','StartMoving','StopMovingOrSizing'}) do methods[name]=function() end end
methods.CreateFontString=frame; methods.CreateTexture=frame
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:SetShown(value) self.shown=value end
function methods:HasFocus() return false end
function methods:IsShown() return self.shown end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:ClearFocus() if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end end
CreateFrame=frame; UIParent={}; UISpecialFrames={}
F.OpenAmmoSettings(); assert(#F.ammoPanel.rows==10)
local function find(text) for _,f in ipairs(frames) do if f.text==text then return f end end; error('Missing control: '..text) end
find('Next').scripts.OnClick(); assert(F.ammoPanel.page==2)
local row=F.ammoPanel.rows[1]; row:SetChecked(true); row.scripts.OnClick(row); assert(F.db.ammo.selected[row.id])
row:SetChecked(false); row.scripts.OnClick(row); assert(not F.db.ammo.selected[row.id])
local input=row.minimum; input:SetText('350'); input.scripts.OnEnterPressed(input); assert(F.AmmoMinimum(row.id)==350)
input:SetText('-4'); input.scripts.OnEnterPressed(input); assert(F.AmmoMinimum(row.id)==350)
find('Check equipped ammo').scripts.OnClick(); assert(F.db.ammo.selected[2512])
find('Uncheck all').scripts.OnClick(); assert(next(F.db.ammo.selected)==nil)
find('Test reminder').scripts.OnClick()
F.OpenConfig=function() F.returned=true end
find('Back to settings').scripts.OnClick(); assert(F.returned and not F.ammoPanel:IsShown())
print('PASS: ammo settings builds, pages, selects, validates input, tests and returns to food settings')
