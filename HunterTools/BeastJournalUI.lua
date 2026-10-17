local _,F=...
function F.OpenBeastJournal()
    if InCombatLockdown() then F.Print('Open the beast journal after combat.');return end
    F.HideConfigPages()
    if not F.beastJournalPanel then
        local p=CreateFrame('Frame','HunterToolsBeastJournal',UIParent,'BackdropTemplate');F.beastJournalPanel=p
        p:SetSize(750,560);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true);p:EnableMouse(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        table.insert(UISpecialFrames,'HunterToolsBeastJournal')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        local function label(message,y,font)
            local t=p:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall');t:SetPoint('TOPLEFT',28,y);t:SetWidth(694);t:SetJustifyH('LEFT');t:SetText(message);return t
        end
        label('Beast field journal',-26,'GameFontNormalLarge')
        p.enabled=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.enabled:SetPoint('TOPLEFT',25,-60)
        local caption=p.enabled:CreateFontString(nil,'OVERLAY','GameFontHighlight');caption:SetPoint('LEFT',p.enabled,'RIGHT',2,0);caption:SetText('Collect beast sightings and fresh tames')
        p.enabled:SetScript('OnClick',function() F.db.beastJournal.enabled=p.enabled:GetChecked() and true or false end)
        p.summary=label('',-106)
        label('Saved locally per character. No uploads. Target or hover a wild beast outside combat to record its identity, family, level and sighting area. Beast Lore details are saved when available. A successful Tame Beast captures the first readable pet spellbook; later training and stable pets are excluded.',-135)
        label('Copy the journal below to share with us. Sighting coordinates describe where you stood, not an exact spawn. Missing abilities remain unknown. Up to 2,000 beasts and five sighting locations per beast are retained.',-205)
        local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',30,-260);scroll:SetSize(665,200)
        p.export=CreateFrame('EditBox',nil,scroll);p.export:SetMultiLine(true);p.export:SetFontObject('GameFontHighlightSmall');p.export:SetWidth(660);p.export:SetAutoFocus(false);p.export:SetMaxLetters(0);scroll:SetScrollChild(p.export)
        p.export:SetScript('OnEscapePressed',function(self) self:ClearFocus();p:Hide() end)
        local function button(message,x,action)
            local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(200,27);b:SetPoint('BOTTOMLEFT',x,28);b:SetText(message);b:SetScript('OnClick',action)
        end
        button('Refresh / select export',28,function() F.OpenBeastJournal();p.export:SetFocus();p.export:HighlightText() end)
        button('Record target now',270,function() F.ObserveBeast('target');F.OpenBeastJournal() end)
        button('Back to animal settings',510,F.OpenAnimalSettings)
    end
    local p=F.beastJournalPanel
    p.enabled:SetChecked(F.BeastCollectionEnabled())
    local sightings,tames=F.BeastJournalCounts();p.summary:SetText(('%d beasts recorded | %d fresh tames | Ctrl+A, Ctrl+C in the export box to copy.'):format(sightings,tames))
    p.export:SetText(F.ExportBeastJournal())
    if F.FinishMenu then F.FinishMenu(p,750,560) end
    p:Show()
end
