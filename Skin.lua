local AS = AscensionSilencer

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local CHECK_TEXTURE = "Interface\\Buttons\\UI-CheckBox-Check"

local function ReadColor(value, fallbackR, fallbackG, fallbackB, fallbackA)
    if type(value) == "table" then
        local r = tonumber(value.r or value[1])
        local g = tonumber(value.g or value[2])
        local b = tonumber(value.b or value[3])
        local a = tonumber(value.a or value[4])
        if r and g and b then
            return r, g, b, a or fallbackA or 1
        end
    end
    return fallbackR, fallbackG, fallbackB, fallbackA or 1
end

local function TryMethod(owner, method, target)
    if owner and type(owner[method]) == "function" then
        return pcall(owner[method], owner, target)
    end
    return false
end

local function HideTexture(texture)
    if not texture then return end
    if texture.SetTexture then texture:SetTexture(nil) end
    if texture.Hide then texture:Hide() end
end

local function RaiseTexture(texture, subLevel)
    if texture and texture.SetDrawLayer then
        texture:SetDrawLayer("OVERLAY", subLevel or 7)
    end
end

local function IsInsideScrollFrame(frame)
    local parent = frame and frame.GetParent and frame:GetParent()
    local depth = 0

    while parent and depth < 8 do
        if parent.GetObjectType and parent:GetObjectType() == "ScrollFrame" then
            return true
        end
        parent = parent.GetParent and parent:GetParent() or nil
        depth = depth + 1
    end

    return false
end

local function UpdateManagedCheckBox(checkBox)
    local mark = checkBox and checkBox.asManagedCheckMark
    if not mark then return end

    if checkBox:GetChecked() then
        mark:Show()
    else
        mark:Hide()
    end
end

local function SkinManagedCheckBox(checkBox, theme)
    if not checkBox.asManagedCheckBox then
        HideTexture(checkBox.GetNormalTexture and checkBox:GetNormalTexture())
        HideTexture(checkBox.GetPushedTexture and checkBox:GetPushedTexture())
        HideTexture(checkBox.GetDisabledTexture and checkBox:GetDisabledTexture())
        HideTexture(checkBox.GetCheckedTexture and checkBox:GetCheckedTexture())
        HideTexture(checkBox.GetDisabledCheckedTexture and checkBox:GetDisabledCheckedTexture())
        HideTexture(checkBox.GetHighlightTexture and checkBox:GetHighlightTexture())

        local indicator = CreateFrame("Frame", nil, checkBox)
        indicator:SetWidth(18)
        indicator:SetHeight(18)
        indicator:SetPoint("CENTER", checkBox, "CENTER", 0, 0)
        indicator:EnableMouse(false)
        indicator:SetFrameLevel((checkBox:GetFrameLevel() or 0) + 10)
        indicator:SetBackdrop({
            bgFile = theme.blankTex,
            edgeFile = theme.blankTex,
            tile = false,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        indicator:SetBackdropColor(theme.backdrop[1], theme.backdrop[2], theme.backdrop[3], 0.95)
        indicator:SetBackdropBorderColor(theme.border[1], theme.border[2], theme.border[3], theme.border[4])

        local mark = indicator:CreateTexture(nil, "OVERLAY")
        mark:SetTexture(CHECK_TEXTURE)
        mark:SetPoint("TOPLEFT", indicator, "TOPLEFT", -2, 2)
        mark:SetPoint("BOTTOMRIGHT", indicator, "BOTTOMRIGHT", 2, -2)
        mark:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])

        checkBox.asManagedCheckBox = indicator
        checkBox.asManagedCheckMark = mark
        checkBox:HookScript("OnClick", UpdateManagedCheckBox)
        checkBox:HookScript("OnShow", UpdateManagedCheckBox)

        local hooked = false
        if hooksecurefunc then
            hooked = pcall(hooksecurefunc, checkBox, "SetChecked", UpdateManagedCheckBox)
        end

        if not hooked and type(checkBox.SetChecked) == "function" then
            local originalSetChecked = checkBox.SetChecked
            checkBox.SetChecked = function(self, value)
                originalSetChecked(self, value)
                UpdateManagedCheckBox(self)
            end
        end
    end

    UpdateManagedCheckBox(checkBox)
end

function AS:GetElvUIEngine()
    local E = nil
    if type(_G.ElvUI) == "table" then E = _G.ElvUI[1] end
    if not E and type(_G.E) == "table" then E = _G.E end
    return E
end

function AS:IsElvUIAvailable()
    return self:GetElvUIEngine() and true or false
end

function AS:GetElvUISkinModule()
    local E = self:GetElvUIEngine()
    if not E or type(E.GetModule) ~= "function" then return nil end

    local ok, skins = pcall(E.GetModule, E, "Skins")
    if ok then return skins end
    return nil
end

function AS:GetElvUITheme()
    local E = self:GetElvUIEngine()
    local media = E and E.media or {}
    local general = E and E.db and E.db.general or {}

    local accentSource = general.valuecolor or media.rgbvaluecolor
    local backdropSource = general.backdropcolor or media.backdropcolor
    local borderSource = general.bordercolor or media.bordercolor

    local ar, ag, ab, aa = ReadColor(accentSource, 0.10, 0.62, 0.90, 1)
    local br, bg, bb, ba = ReadColor(backdropSource, 0.06, 0.06, 0.06, 0.92)
    local er, eg, eb, ea = ReadColor(borderSource, 0.22, 0.22, 0.22, 1)

    return {
        normTex = media.normTex or media.blankTex or WHITE_TEXTURE,
        blankTex = media.blankTex or WHITE_TEXTURE,
        accent = { ar, ag, ab, aa },
        backdrop = { br, bg, bb, ba },
        border = { er, eg, eb, ea },
    }
end

function AS:ApplyThemeBackdrop(frame, alphaMultiplier)
    if not frame or not frame.SetBackdrop then return end
    local theme = self:GetElvUITheme()
    local alpha = (theme.backdrop[4] or 1) * (alphaMultiplier or 1)

    frame:SetBackdrop({
        bgFile = theme.blankTex,
        edgeFile = theme.blankTex,
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(theme.backdrop[1], theme.backdrop[2], theme.backdrop[3], alpha)
    frame:SetBackdropBorderColor(theme.border[1], theme.border[2], theme.border[3], theme.border[4])
end

function AS:SkinPanel(panel)
    if not panel or not self:IsElvUIAvailable() or panel.asElvUISkinned then return end

    local native = false
    if type(panel.StripTextures) == "function" then pcall(panel.StripTextures, panel) end
    if type(panel.CreateBackdrop) == "function" then
        native = pcall(panel.CreateBackdrop, panel, "Transparent")
    end
    if not native then self:ApplyThemeBackdrop(panel, 0.94) end
    panel.asElvUISkinned = true
end

function AS:SkinCard(card)
    if not card or not self:IsElvUIAvailable() or card.asElvUISkinned then return end
    self:ApplyThemeBackdrop(card, 0.58)
    card.asElvUISkinned = true
end

function AS:SkinButton(button)
    if not button or not self:IsElvUIAvailable() or button.asElvUISkinned then return end

    local skins = self:GetElvUISkinModule()
    local handled = TryMethod(skins, "HandleButton", button)

    if not handled then
        local name = button.GetName and button:GetName()
        HideTexture(button.GetNormalTexture and button:GetNormalTexture())
        HideTexture(button.GetPushedTexture and button:GetPushedTexture())
        HideTexture(button.GetDisabledTexture and button:GetDisabledTexture())
        if name then
            HideTexture(_G[name .. "Left"])
            HideTexture(_G[name .. "Middle"])
            HideTexture(_G[name .. "Right"])
        end
        self:ApplyThemeBackdrop(button, 0.82)
    end

    button.asElvUISkinned = true
end

function AS:SkinCheckBox(checkBox)
    if not checkBox or not self:IsElvUIAvailable() then return end

    local parent = checkBox.GetParent and checkBox:GetParent()
    if parent and parent.GetFrameLevel and checkBox.GetFrameLevel and checkBox.SetFrameLevel then
        local minimumLevel = (parent:GetFrameLevel() or 0) + 2
        if (checkBox:GetFrameLevel() or 0) < minimumLevel then
            checkBox:SetFrameLevel(minimumLevel)
        end
    end

    if IsInsideScrollFrame(checkBox) then
        SkinManagedCheckBox(checkBox, self:GetElvUITheme())
        checkBox.asElvUISkinned = true
    elseif not checkBox.asElvUISkinned then
        local skins = self:GetElvUISkinModule()
        TryMethod(skins, "HandleCheckBox", checkBox)
        checkBox.asElvUISkinned = true

        RaiseTexture(checkBox.GetCheckedTexture and checkBox:GetCheckedTexture(), 7)
        RaiseTexture(checkBox.GetDisabledCheckedTexture and checkBox:GetDisabledCheckedTexture(), 7)
        RaiseTexture(checkBox.GetHighlightTexture and checkBox:GetHighlightTexture(), 6)
    end

    local name = checkBox.GetName and checkBox:GetName()
    local text = name and _G[name .. "Text"]
    if text then
        text:ClearAllPoints()
        text:SetPoint("LEFT", checkBox, "RIGHT", 5, 1)
    end
end

function AS:SkinSlider(slider)
    if not slider or not self:IsElvUIAvailable() or slider.asElvUISkinned then return end

    local theme = self:GetElvUITheme()
    local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
    local regions = { slider:GetRegions() }

    for _, region in ipairs(regions) do
        if region ~= thumb and region.GetObjectType and region:GetObjectType() == "Texture" then
            HideTexture(region)
        end
    end

    if not slider.asTrackBorder then
        local border = slider:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("LEFT", slider, "LEFT", 0, 0)
        border:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        border:SetHeight(8)
        slider.asTrackBorder = border
    end

    if not slider.asTrackFill then
        local fill = slider:CreateTexture(nil, "BORDER")
        fill:SetPoint("LEFT", slider, "LEFT", 1, 0)
        fill:SetPoint("RIGHT", slider, "RIGHT", -1, 0)
        fill:SetHeight(6)
        slider.asTrackFill = fill
    end

    slider.asTrackBorder:SetTexture(theme.blankTex)
    slider.asTrackBorder:SetVertexColor(theme.border[1], theme.border[2], theme.border[3], theme.border[4])
    slider.asTrackBorder:Show()

    slider.asTrackFill:SetTexture(theme.blankTex)
    slider.asTrackFill:SetVertexColor(theme.backdrop[1], theme.backdrop[2], theme.backdrop[3], theme.backdrop[4])
    slider.asTrackFill:Show()

    if thumb then
        thumb:SetTexture(theme.normTex)
        thumb:SetVertexColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
        thumb:SetWidth(12)
        thumb:SetHeight(18)
        if thumb.SetDrawLayer then thumb:SetDrawLayer("OVERLAY", 7) end
        thumb:Show()
    end

    slider.asElvUISkinned = true
end

function AS:SkinEditBox(editBox)
    if not editBox or not self:IsElvUIAvailable() or editBox.asElvUISkinned then return end

    local skins = self:GetElvUISkinModule()
    local handled = TryMethod(skins, "HandleEditBox", editBox)
    if not handled then self:ApplyThemeBackdrop(editBox, 0.82) end
    editBox.asElvUISkinned = true
end

function AS:SkinScrollFrame(scrollFrame)
    if not scrollFrame or not self:IsElvUIAvailable() then return end
    local name = scrollFrame.GetName and scrollFrame:GetName()
    local scrollBar = name and _G[name .. "ScrollBar"]
    if not scrollBar or scrollBar.asElvUISkinned then return end

    local skins = self:GetElvUISkinModule()
    TryMethod(skins, "HandleScrollBar", scrollBar)
    scrollBar.asElvUISkinned = true
end
