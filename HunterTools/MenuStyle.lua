local _,F=...
local white='Interface\\Buttons\\WHITE8X8'
-- Shared, lightweight presentation. No model loading or external artwork.
function F.MenuText(parent,text,x,y,width,font)
    local t=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
    t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');t:SetText(text)
    return t
end
function F.MenuSection(parent,x,y,w,h)
    local box=CreateFrame('Frame',nil,parent,'BackdropTemplate')
    box:SetPoint('TOPLEFT',x,y);box:SetSize(w,h)
    box:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
    box:SetBackdropColor(0.075,0.105,0.10,1);box:SetBackdropBorderColor(0.23,0.29,0.24,1)
    return box
end
function F.StyleMenuButton(b)
    if b.menuStyled then return end;b.menuStyled=true
    b:SetNormalTexture(white);b:GetNormalTexture():SetVertexColor(0.12,0.21,0.17,1)
    b:SetPushedTexture(white);b:GetPushedTexture():SetVertexColor(0.07,0.12,0.10,1)
    b:SetHighlightTexture(white);b:GetHighlightTexture():SetVertexColor(0.5,0.65,0.4,0.22)
    b:SetDisabledTexture(white);b:GetDisabledTexture():SetVertexColor(0.09,0.11,0.10,1)
    b:SetNormalFontObject('GameFontHighlight');b:SetDisabledFontObject('GameFontDisable')
end
function F.FinishMenu(p,w,h)
    p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile=white,edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    p:SetBackdropColor(0.035,0.047,0.044,1)
    p:SetBackdropBorderColor(0.64,0.65,0.49,1)
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    if type(width)=='number' and type(height)=='number' then p:SetScale(math.min(1,(width-30)/w,(height-30)/h)) end
    local function buttons(parent)
        for _,child in ipairs({parent:GetChildren()}) do
            if child:GetObjectType()=='Button' and child:GetWidth()>40 then F.StyleMenuButton(child) end
            buttons(child)
        end
    end
    buttons(p)
end
