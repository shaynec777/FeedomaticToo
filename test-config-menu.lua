local F={db={enabled=true,ammo={enabled=false}},Print=function() end}
assert(loadfile('HunterTools/ConfigUI.lua'))('test',F)
local frames={}
local function widget()
    local w={scripts={}}
    setmetatable(w,{__index=function(_,key)
        if key=='CreateFontString' then return widget end
        return function() end
    end})
    function w:SetScript(event,fn) self.scripts[event]=fn end
    function w:SetText(text) self.text=text end
    function w:SetChecked(value) self.checked=value end
    function w:GetChecked() return self.checked end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    table.insert(frames,w); return w
end
CreateFrame=widget; UIParent={}; UISpecialFrames={}
InCombatLockdown=function() return false end
F.OpenFoodList=function() F.foodOpened=true end
F.OpenAmmoSettings=function() F.ammoOpened=true end
local function find(text) for _,w in ipairs(frames) do if w.text==text then return w end end; error(text) end
F.RangeSettings=function() return {enabled=true} end
F.OpenConfig(); assert(F.configPanel.shown)
local settings={}; for _,w in ipairs(frames) do if w.text=='Settings' then table.insert(settings,w) end end; assert(#settings==4); settings[1].scripts.OnClick(); assert(F.foodOpened and not F.configPanel.shown)
F.OpenConfig(); settings[3].scripts.OnClick(); assert(F.ammoOpened)
F.OpenConfig(); settings[2].scripts.OnClick()
assert(F.instanceSettingsPanel.shown and not F.configPanel.shown)
local checks=F.instanceSettingsPanel.checks
assert(checks.growl.checked and checks.pack.checked,'old settings initialize both checks')
checks.growl.checked=false; checks.growl.scripts.OnClick()
F.OpenConfig(); settings[2].scripts.OnClick()
assert(not checks.growl.checked and checks.pack.checked,'reopening preserves choices')
F.db.instanceChecks=nil; settings[2].scripts.OnClick()
assert(checks.growl.checked and checks.pack.checked,'repair missing settings on reopen')
F.db.instanceChecks='bad'; settings[2].scripts.OnClick()
assert(checks.growl.checked and checks.pack.checked,'repair malformed settings')
checks.pack.checked=true; checks.pack.scripts.OnClick(); assert(F.db.instanceChecks.pack)
find('Back to settings').scripts.OnClick(); assert(F.configPanel.shown and not F.instanceSettingsPanel.shown)
F.configPanel:Hide(); InCombatLockdown=function() return true end
F.OpenConfig(); assert(not F.configPanel.shown)
print('PASS: four-tool settings navigation, instance toggles and combat guard')
