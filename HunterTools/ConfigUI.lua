local _,F=...
function F.InstanceSettings()
    if type(F.db.instanceChecks)~='table' then F.db.instanceChecks={} end
    for _,key in ipairs({'growl','pack'}) do
        if type(F.db.instanceChecks[key])~='boolean' then F.db.instanceChecks[key]=true end
    end
    return F.db.instanceChecks
end
local function panel(name,title,w,h)
    local p=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
    p:SetSize(w,h); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG'); p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    local t=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); t:SetPoint('TOP',0,-22); t:SetText(title)
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    table.insert(UISpecialFrames,name)
    return p
end
function F.HideConfigPages()
    for _,key in ipairs({'configPanel','foodPanel','ammoPanel','instanceSettingsPanel','rangeSettingsPanel','petListPanel'}) do
        if F[key] then F[key]:Hide() end
    end
end
function F.ToolEnabled(key)
    if key=='food' then return F.db.enabled end
    if key=='instance' then return F.InstanceSettings().enabled~=false end
    if key=='ammo' then return F.db.ammo.enabled end
    return F.RangeSettings().enabled
end
function F.SetToolEnabled(key,value)
    if InCombatLockdown() then F.Print('Change tool settings after combat.'); return end
    if key=='food' then F.db.enabled=value; F.Refresh()
    elseif key=='instance' then
        F.InstanceSettings().enabled=value
        if not value then F.instanceCheckPending=false; if F.instancePrompt then F.instancePrompt:Hide() end end
    elseif key=='ammo' then F.db.ammo.enabled=value; F.ResetAmmoReminder()
    else F.RangeSettings().enabled=value; F.UpdateRangeWindow() end
end
function F.OpenConfig()
    if InCombatLockdown() then F.Print('Open settings after combat.'); return end
    F.HideConfigPages()
    if not F.configPanel then
        local p=panel('HunterToolsConfig','HunterTools tools',440,310); F.configPanel=p
        p.checks={}
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        help:SetPoint('TOPLEFT',28,-53); help:SetText('Check to enable a tool. Settings opens its controls.')
        for i,spec in ipairs({{'food','Food','OpenFoodList'},{'instance','Instance','OpenInstanceSettings'},
            {'ammo','Ammo','OpenAmmoSettings'},{'range','Range','OpenRangeSettings'}}) do
            local key,method=spec[1],spec[3]
            local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate')
            c:SetPoint('TOPLEFT',25,-80-(i-1)*50); p.checks[key]=c
            local label=c:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
            label:SetPoint('LEFT',c,'RIGHT',8,0); label:SetText(spec[2])
            c:SetScript('OnClick',function() F.SetToolEnabled(key,c:GetChecked() and true or false); c:SetChecked(F.ToolEnabled(key)) end)
            local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
            b:SetSize(130,30); b:SetPoint('TOPRIGHT',-30,-83-(i-1)*50); b:SetText('Settings')
            b:SetScript('OnClick',function() if not InCombatLockdown() then F.HideConfigPages(); F[method]() end end)
        end
    end
    for key,c in pairs(F.configPanel.checks) do c:SetChecked(F.ToolEnabled(key)) end
    F.configPanel:Show()
end
function F.OpenRangeSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.'); return end
    F.HideConfigPages()
    if not F.rangeSettingsPanel then
        local p=panel('HunterToolsRangeSettings','Range settings',460,330); F.rangeSettingsPanel=p
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlight')
        help:SetPoint('TOPLEFT',30,-60); help:SetWidth(400)
        help:SetText('Shows your target name, portrait, ranged-attack status and estimated distance. Non-enemies are gray. Drag the range window outside combat to move it.')
        p.checks={}
        for i,spec in ipairs({{'showPetAbilities','Target pet abilities and level'},{'showPetDiet','Target pet edible food types'}}) do
            local key=spec[1]; local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate'); p.checks[key]=c
            c:SetPoint('TOPLEFT',25,-145-(i-1)*38)
            local label=c:CreateFontString(nil,'OVERLAY','GameFontHighlight'); label:SetPoint('LEFT',c,'RIGHT',2,0); label:SetText(spec[2])
            c:SetScript('OnClick',function() F.RangeSettings()[key]=c:GetChecked() and true or false; F.UpdateRangeWindow() end)
        end
        local reset=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); reset:SetSize(180,26); reset:SetPoint('BOTTOM',0,65); reset:SetText('Reset window position')
        reset:SetScript('OnClick',function()
            if InCombatLockdown() then return end
            local s=F.RangeSettings(); s.x=0; s.y=-230
            if F.rangeWindow then F.rangeWindow:ClearAllPoints(); F.rangeWindow:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y) end
        end)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); back:SetSize(160,26); back:SetPoint('BOTTOM',0,25); back:SetText('Back to settings'); back:SetScript('OnClick',F.OpenConfig)
    end
    for key,c in pairs(F.rangeSettingsPanel.checks) do c:SetChecked(F.RangeSettings()[key]) end
    F.rangeSettingsPanel:Show()
end
function F.OpenInstanceSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.'); return end
    F.InstanceSettings()
    F.HideConfigPages()
    if not F.instanceSettingsPanel then
        local p=panel('HunterToolsInstanceSettings','Instance settings',480,270); F.instanceSettingsPanel=p
        p.checks={}
        for i,spec in ipairs({{'growl','Check Growl autocast'},{'pack','Check Aspect of the Pack'}}) do
            local b=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate')
            b:SetPoint('TOPLEFT',25,-55-(i-1)*38)
            local text=b:CreateFontString(nil,'OVERLAY','GameFontHighlight'); text:SetPoint('LEFT',b,'RIGHT',2,0); text:SetText(spec[2])
            local key=spec[1]; p.checks[key]=b
            b:SetScript('OnClick',function() F.InstanceSettings()[key]=b:GetChecked() and true or false end)
        end
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        help:SetPoint('TOPLEFT',30,-145); help:SetWidth(420)
        help:SetText('On entering a dungeon or raid, ask before disabling the selected effects. Buttons change only your Growl autocast or your own Pack. The prompt waits until combat ends.')
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate'); back:SetSize(160,26); back:SetPoint('BOTTOM',0,25); back:SetText('Back to settings')
        back:SetScript('OnClick',F.OpenConfig)
    end
    for key,b in pairs(F.instanceSettingsPanel.checks) do b:SetChecked(F.InstanceSettings()[key]) end
    F.instanceSettingsPanel:Show()
end
