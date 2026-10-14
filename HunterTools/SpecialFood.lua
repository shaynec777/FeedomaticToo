local _,F=...
function F.SpecialFoodSettings()
    -- Undo the initial development build's aggressive defaults once.
    if F.db.specialFoodDefaultsVersion~=1 then
        F.db.protectBuffFood=false
        F.db.protectCookingFood=false
        F.db.specialFoodDefaultsVersion=1
    end
    for _,key in ipairs({'protectBuffFood','protectCookingFood'}) do
        if type(F.db[key])~='boolean' then F.db[key]=false end
    end
end
function F.SpecialFoodReason(id)
    if InCombatLockdown() then return nil end
    F.SpecialFoodSettings()
    if F.db.protectCookingFood and C_Item.GetItemInfoInstant then
        local _,_,_,_,_,class,subclass=C_Item.GetItemInfoInstant(id)
        if F.IsPublic(class) and F.IsPublic(subclass) and class==7 and subclass==8 then return 'Cooking ingredient' end
    end
    if F.db.protectBuffFood and C_TooltipInfo and C_TooltipInfo.GetItemByID then
        local tip=C_TooltipInfo.GetItemByID(id)
        if F.IsPublic(tip) and tip and F.IsPublic(tip.lines) and tip.lines then
            for _,line in ipairs(tip.lines) do
                local text=line.leftText
                if F.IsPublic(text) and type(text)=='string' then
                    local plain=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):lower()
                    if plain:find('well fed',1,true) then return 'Buff food' end
                end
            end
        end
    end
end
function F.FoodProtectionReason(id)
    return (F.QuestFoodReason and F.QuestFoodReason(id)) or F.SpecialFoodReason(id)
end
function F.OpenFoodProtection()
    if InCombatLockdown() then F.Print('Open protection settings after combat.'); return end
    F.SpecialFoodSettings()
    if F.protectionPanel then F.protectionPanel:Show(); return end
    local p=CreateFrame('Frame','HunterToolsFoodProtection',UIParent,'BackdropTemplate'); F.protectionPanel=p
    p:SetSize(480,270); p:SetPoint('CENTER'); p:SetFrameStrata('FULLSCREEN_DIALOG')
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); title:SetPoint('TOP',0,-25); title:SetText('Food protection')
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    for i,spec in ipairs({{'protectQuestFood','Preserve active quest food'},{'protectBuffFood','Preserve buff food'},{'protectCookingFood','Preserve cooking ingredients'}}) do
        local key=spec[1]; local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate')
        c:SetPoint('TOPLEFT',25,-55-(i-1)*38); c:SetChecked(F.db[key])
        local label=c:CreateFontString(nil,'OVERLAY','GameFontHighlight'); label:SetPoint('LEFT',c,'RIGHT',3,0); label:SetText(spec[2])
        c:SetScript('OnClick',function()
            F.db[key]=c:GetChecked() and true or false; F.bagsDirty=true; F.Refresh(true)
            if F.foodPanel then F.foodPanel:Refresh() end
        end)
    end
    local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); help:SetPoint('TOPLEFT',30,-185); help:SetWidth(420)
    help:SetText('Protection overrides allowed lists. Cooking uses the client Food & Drink ingredient category. Buff detection uses English Well Fed tooltip text; block other special foods manually.')
    table.insert(UISpecialFrames,'HunterToolsFoodProtection')
end
