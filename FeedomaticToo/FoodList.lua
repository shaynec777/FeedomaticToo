local _, F = ...
function F.CatalogMatches(id, count, filters, cached)
    if filters.inBags and count <= 0 then return false end
    if filters.blocked and not F.db.blacklist[id] then return false end
    if filters.edible then
        if InCombatLockdown() or not UnitExists('pet') or not cached then return false end
        local edible=C_PetInfo.CanPetEatItem(id)
        if not F.IsPublic(edible) or edible ~= true then return false end
    end
    return true
end

function F.CatalogEdibility(id, cached)
    if InCombatLockdown() then return 'Unknown',0.6,0.6,0.6 end
    if not UnitExists('pet') then return 'No pet',0.6,0.6,0.6 end
    if not cached then return 'Loading',0.6,0.6,0.6 end
    local canEat=C_PetInfo.CanPetEatItem(id)
    if not F.IsPublic(canEat) or canEat==nil then return 'Unknown',0.6,0.6,0.6 end
    if canEat then return 'Can eat',0.3,1,0.3 end
    return 'Cannot eat',0.75,0.75,0.75
end

function F.UpdateFoodCatalog()
    if InCombatLockdown() then return end
    F.bagFoodCounts = {}
    for _,list in ipairs({F.db.blacklist,F.db.whitelist,F.db.discoveredFoods or {}}) do
        for id in pairs(list) do
            if not F.foodCatalog[id] then
                F.foodCatalog[id]={name=C_Item.GetItemInfo(id) or ('Item '..id)}
            end
        end
    end
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        for slot=1,C_Container.GetContainerNumSlots(bag) do
            local item=C_Container.GetContainerItemInfo(bag,slot)
            if item and F.IsPublic(item.itemID) and item.itemID and F.IsPublic(item.stackCount) then
                F.bagFoodCounts[item.itemID]=(F.bagFoodCounts[item.itemID] or 0)+(item.stackCount or 0)
            end
            if item and F.IsPublic(item.itemID) and item.itemID and C_PetInfo.CanPetEatItem(item.itemID) then
                local name=C_Item.GetItemInfo(item.itemID)
                if name then
                    F.foodCatalog[item.itemID]={name=name}
                    F.db.discoveredFoods=F.db.discoveredFoods or {}
                    F.db.discoveredFoods[item.itemID]=true
                end
            end
        end
    end
end
function F.OpenFoodList()
    if InCombatLockdown() then F.Print('Open the food list after combat.'); return end
    F.UpdateFoodCatalog()
    if F.foodPanel then F.foodPanel.page=1; F.foodPanel:Show(); F.foodPanel:Refresh(); return end
    local p=CreateFrame('Frame','GFWForeverFoodList',UIParent,'BackdropTemplate')
    F.foodPanel=p
    p:SetSize(680,780); p:SetPoint('CENTER'); p:SetFrameStrata('DIALOG')
    p:SetMovable(true); p:EnableMouse(true); p:RegisterForDrag('LeftButton')
    p:SetScript('OnDragStart',p.StartMoving); p:SetScript('OnDragStop',p.StopMovingOrSizing)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    title:SetPoint('TOP',0,-18); title:SetText('FeedomaticToo food list')
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
    local search=CreateFrame('EditBox',nil,p,'InputBoxTemplate'); p.search=search
    search:SetSize(610,25); search:SetPoint('TOPLEFT',30,-55); search:SetAutoFocus(false)
    search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    help:SetPoint('TOPLEFT',25,-90); help:SetText('Food rows: check to block; uncheck to allow (whitelist still applies). Saves immediately.')
    local order=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    order:SetSize(280,25); order:SetPoint('TOPLEFT',25,-110)
    order:SetScript('OnClick',function()
        F.db.foodOrder=F.db.foodOrder=='low' and 'high' or 'low'
        F.bagsDirty=true; F.Refresh(true); p:Refresh()
    end)
    local explanation=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    explanation:SetPoint('TOPLEFT',25,-145); explanation:SetWidth(630)
    explanation:SetJustifyH('LEFT')
    explanation:SetText('Chooses unlocked food in your bags that your pet can eat. Blacklist wins; a nonempty whitelist limits choices. Ranks by item level (not vendor price or measured happiness), then uses the smaller stack on ties. Low to high saves higher-level food. Changes affect the next feeding.')
    local function checkbox(label,x,y,checked,change)
        local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate')
        c:SetPoint('TOPLEFT',x,y); c:SetChecked(checked)
        local text=c:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        text:SetPoint('LEFT',c,'RIGHT',2,0); text:SetText(label)
        c:SetScript('OnClick',function(self) change(self:GetChecked() and true or false) end)
        return c
    end
    checkbox('Use default wolf sound',22,-205,F.db.wolfSound,function(value) F.db.wolfSound=value end)
    checkbox('Mute hunger sounds',250,-205,F.db.mute,function(value) F.db.mute=value end)
    local testSound=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    testSound:SetSize(100,24); testSound:SetPoint('TOPLEFT',530,-209); testSound:SetText('Test sound')
    testSound:SetScript('OnClick',function() F.PlayHungerSound(true) end)
    local soundHelp=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    soundHelp:SetPoint('TOPLEFT',25,-241)
    soundHelp:SetText('Unchecked: pet-family sound, with wolf fallback. Mute overrides both. Uses Master volume.')
    local reminderMode=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    reminderMode:SetSize(280,25); reminderMode:SetPoint('TOPLEFT',25,-265)
    local modes={'off','chat','screen','both'}
    local modeLabels={off='Off',chat='Chat',screen='On-screen',both='Both'}
    local function updateReminderLabel()
        reminderMode:SetText('Text reminders: '..modeLabels[F.db.textReminder])
    end
    updateReminderLabel()
    reminderMode:SetScript('OnClick',function()
        for i,mode in ipairs(modes) do
            if F.db.textReminder==mode then F.db.textReminder=modes[i % #modes + 1]; break end
        end
        updateReminderLabel()
    end)
    local testReminder=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    testReminder:SetSize(125,25); testReminder:SetPoint('TOPLEFT',505,-265)
    testReminder:SetText('Test reminder')
    testReminder:SetScript('OnClick',function() F.ShowTextReminder(true) end)
    local repeatLabel=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    repeatLabel:SetPoint('TOPLEFT',25,-308); repeatLabel:SetText('Repeat every (minutes):')
    local minutes=CreateFrame('EditBox',nil,p,'InputBoxTemplate')
    minutes:SetSize(55,25); minutes:SetPoint('TOPLEFT',190,-300); minutes:SetAutoFocus(false)
    minutes:SetMaxLetters(6); minutes:SetText(tostring(F.db.reminderMinutes))
    local function saveInterval(self)
        local value=tonumber(self:GetText())
        if value and value==value and value>=0 and value<=120 then
            F.db.reminderMinutes=value
        else
            F.Print('Reminder time must be 0 to 120 minutes. 0 means once per hunger episode.')
        end
        self:SetText(tostring(F.db.reminderMinutes)); self:ClearFocus()
    end
    minutes:SetScript('OnEnterPressed',saveInterval)
    minutes:SetScript('OnEditFocusLost',function(self)
        if self:GetText()~=tostring(F.db.reminderMinutes) then saveInterval(self) end
    end)
    minutes:SetScript('OnEscapePressed',function(self)
        self:SetText(tostring(F.db.reminderMinutes)); self:ClearFocus()
    end)
    local repeatHelp=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    repeatHelp:SetPoint('TOPLEFT',260,-308); repeatHelp:SetText('0 = once. Range: 0-120. Press Enter to save.')
    local reminderHelp=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    reminderHelp:SetPoint('TOPLEFT',25,-334)
    reminderHelp:SetText('Private reminders only. First alert when hungry; repeats pause during combat or feeding.')
    p.filters={}
    for _,spec in ipairs({{'In bags','inBags',22},{'Edible by current pet','edible',175},{'Blocked','blocked',415}}) do
        local key=spec[2]
        checkbox(spec[1],spec[3],-353,false,function(value)
            p.filters[key]=value; p.page=1; p:Refresh()
        end)
    end
    local blockHelp=p:CreateFontString(nil,'OVERLAY','GameFontNormal')
    blockHelp:SetPoint('TOPLEFT',25,-390)
    blockHelp:SetText('CHECK TO BLOCK a food. Uncheck to remove its block.')
    p.rows={}; p.page=1
    for i=1,12 do
        local row=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate')
        row:SetPoint('TOPLEFT',22,-412-(i-1)*25)
        row.text=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        row.icon=row:CreateTexture(nil,'ARTWORK')
        row.icon:SetSize(22,22); row.icon:SetPoint('LEFT',row,'RIGHT',3,0)
        row.text:SetPoint('LEFT',row.icon,'RIGHT',6,0)
        row.text:SetWidth(440); row.text:SetJustifyH('LEFT')
        row.diet=row:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        row.diet:SetPoint('LEFT',row.text,'RIGHT',8,0)
        row:SetScript('OnEnter',function(self)
            if not self.id then return end
            GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
            GameTooltip:SetHyperlink('item:'..self.id)
            GameTooltip:Show()
        end)
        row:SetScript('OnLeave',function() GameTooltip:Hide() end)
        row.header=p:CreateFontString(nil,'OVERLAY','GameFontNormal')
        row.header:SetPoint('TOPLEFT',25,-417-(i-1)*25)
        row:SetScript('OnClick',function(self)
            if not self.id then return end
            F.db.blacklist[self.id]=self:GetChecked() and true or nil
            F.bagsDirty=true; F.Refresh(true); p:Refresh()
        end)
        p.rows[i]=row
    end
    local status=p:CreateFontString(nil,'OVERLAY','GameFontNormalSmall'); p.status=status
    status:SetPoint('BOTTOM',0,48)
    for _,spec in ipairs({{'Previous',-1,-100},{'Next',1,100}}) do
        local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
        b:SetSize(85,24); b:SetPoint('BOTTOM',spec[3],16); b:SetText(spec[1])
        local step=spec[2]
        b:SetScript('OnClick',function() p.page=p.page+step; p:Refresh() end)
    end
    function p:Refresh()
        order:SetText('Food item level: '..(F.db.foodOrder=='low' and 'Low to high' or 'High to low'))
        local carried,other={},{}; local query=(search:GetText() or ''):lower()
        for id,entry in pairs(F.foodCatalog) do
            local cached=C_Item.GetItemInfo(id)
            local name=cached or entry.name
            local label=name..' ['..id..']'
            local count=(F.bagFoodCounts or {})[id] or 0
            if label:lower():find(query,1,true) and F.CatalogMatches(id,count,self.filters,cached) then
                table.insert(count>0 and carried or other,{id=id,label=label,count=count})
            end
        end
        local function byName(a,b) return a.label<b.label end
        table.sort(carried,byName); table.sort(other,byName)
        local list={{header='In bags ('..#carried..' matching types)'}}
        for _,e in ipairs(carried) do table.insert(list,e) end
        table.insert(list,{header='Other catalog foods ('..#other..')'})
        for _,e in ipairs(other) do table.insert(list,e) end
        local pages=math.max(1,math.ceil(#list/12)); self.page=math.max(1,math.min(pages,self.page))
        for i,row in ipairs(self.rows) do
            local e=list[(self.page-1)*12+i]
            row.id=nil
            row:SetShown(e~=nil and not e.header)
            row.header:SetShown(e~=nil and e.header~=nil)
            if e and e.header then row.header:SetText(e.header) end
            if e and not e.header then
                local cached,_,_,_,_,_,_,_,_,icon=C_Item.GetItemInfo(e.id)
                row.icon:SetTexture(icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
                local diet,r,g,b=F.CatalogEdibility(e.id,cached)
                row.diet:SetText(diet); row.diet:SetTextColor(r,g,b)
                row.id=e.id; row:SetChecked(F.db.blacklist[e.id]==true)
                local restricted=next(F.db.whitelist) and not F.db.whitelist[e.id]
                row.text:SetText(e.label..(e.count>0 and (' x'..e.count) or '')..(restricted and ' (outside whitelist)' or ''))
            end
        end
        local note=self.filters.edible and (InCombatLockdown() and ' | Edibility unavailable in combat' or
            (not UnitExists('pet') and ' | Summon a pet to filter by diet' or '')) or ''
        status:SetText(('%d matching foods | Page %d/%d%s'):format(#carried+#other,self.page,pages,note))
    end
    search:SetScript('OnTextChanged',function() p.page=1; p:Refresh() end)
    for _,event in ipairs({'BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED','PLAYER_REGEN_ENABLED','UNIT_PET'}) do p:RegisterEvent(event) end
    p:SetScript('OnEvent',function()
        if p:IsShown() and not InCombatLockdown() then F.UpdateFoodCatalog(); p:Refresh() end
    end)
    table.insert(UISpecialFrames,'GFWForeverFoodList')
    p:Refresh()
end
