local AS = AscensionSilencer
AS.version = "0.3.9"

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"

local function IsInsideScrollFrame(frame)
    local parent = frame and frame.GetParent and frame:GetParent()
    local depth = 0
    while parent and depth < 8 do
        if parent.GetObjectType and parent:GetObjectType() == "ScrollFrame" then return true end
        parent = parent.GetParent and parent:GetParent() or nil
        depth = depth + 1
    end
    return false
end

local function GetCheckedTexture(checkBox)
    if not checkBox then return nil end
    return (checkBox.GetCheckedTexture and checkBox:GetCheckedTexture())
        or checkBox.CheckedTexture
        or checkBox.checkedTexture
end

local function ReadStyle(source)
    local sourceTexture = GetCheckedTexture(source)
    if not sourceTexture then return nil end

    local texture = sourceTexture.GetTexture and sourceTexture:GetTexture() or WHITE_TEXTURE
    local r, g, b, a = 1, 0.82, 0, 1
    if sourceTexture.GetVertexColor then
        local sr, sg, sb, sa = sourceTexture:GetVertexColor()
        if sr and sg and sb then r, g, b = sr, sg, sb end
        if sa then a = sa end
    end
    if sourceTexture.GetAlpha then a = sourceTexture:GetAlpha() or a end

    local width, height = 14, 14
    if sourceTexture.GetWidth then
        local value = tonumber(sourceTexture:GetWidth())
        if value and value >= 8 and value <= 24 then width = value end
    end
    if sourceTexture.GetHeight then
        local value = tonumber(sourceTexture:GetHeight())
        if value and value >= 8 and value <= 24 then height = value end
    end

    return texture or WHITE_TEXTURE, r, g, b, a, width, height
end

local function UpdateVisual(checkBox)
    local indicator = checkBox and checkBox.asScrollCheckedIndicator
    if not indicator then return end
    if checkBox:GetChecked() then indicator:Show() else indicator:Hide() end
end

local function ApplyVisual(checkBox, texture, r, g, b, a, width, height)
    if not checkBox.asScrollCheckedIndicator then
        local original = GetCheckedTexture(checkBox)
        if original and original.SetAlpha then original:SetAlpha(0) end

        local indicator = CreateFrame("Frame", nil, checkBox)
        indicator:SetPoint("CENTER", checkBox, "CENTER", 0, 0)
        indicator:EnableMouse(false)

        local fill = indicator:CreateTexture(nil, "OVERLAY")
        fill:SetAllPoints(indicator)

        checkBox.asScrollCheckedIndicator = indicator
        checkBox.asScrollCheckedFill = fill
        checkBox:HookScript("OnClick", UpdateVisual)
        checkBox:HookScript("OnShow", UpdateVisual)
    end

    local indicator = checkBox.asScrollCheckedIndicator
    local fill = checkBox.asScrollCheckedFill
    indicator:SetWidth(width)
    indicator:SetHeight(height)
    indicator:SetFrameLevel((checkBox:GetFrameLevel() or 0) + 10)
    fill:SetTexture(texture)
    fill:SetVertexColor(r, g, b, a)
    UpdateVisual(checkBox)
end

function AS:SyncScrollCheckboxVisuals()
    if not self:IsElvUIAvailable() then return end

    local source = self.controls and self.controls.hygiene and self.controls.hygiene.enabled
    local texture, r, g, b, a, width, height = ReadStyle(source)
    if not texture then return end

    for _, checkBox in ipairs(self.skinnables and self.skinnables.checkboxes or {}) do
        if checkBox ~= source and IsInsideScrollFrame(checkBox) then
            ApplyVisual(checkBox, texture, r, g, b, a, width, height)
        end
    end
end

local OriginalApplyOptionsSkin = AS.ApplyOptionsSkin
function AS:ApplyOptionsSkin()
    OriginalApplyOptionsSkin(self)
    self:SyncScrollCheckboxVisuals()
end
