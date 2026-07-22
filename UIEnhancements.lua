local AS = AscensionSilencer

local PAGE_WIDTH = 548
local CARD_WIDTH = 532

local function SetTooltip(control, title, text)
    if not control then return end
    control.asTooltipTitle = title
    control.asTooltipText = text

    if control.asTooltipBound then return end
    control.asTooltipBound = true

    local function ShowTooltip(self)
        if not GameTooltip or not self.asTooltipTitle then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.asTooltipTitle, 1, 1, 1)
        if self.asTooltipText and self.asTooltipText ~= "" then
            GameTooltip:AddLine(self.asTooltipText, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end

    local function HideTooltip()
        if GameTooltip then GameTooltip:Hide() end
    end

    if control.HookScript then
        control:HookScript("OnEnter", ShowTooltip)
        control:HookScript("OnLeave", HideTooltip)
    else
        control:SetScript("OnEnter", ShowTooltip)
        control:SetScript("OnLeave", HideTooltip)
    end
end

function AS:RegisterSkinnable(kind, control)
    if not kind or not control then return end
    self.skinnables = self.skinnables or {}
    self.skinnables[kind] = self.skinnables[kind] or {}
    table.insert(self.skinnables[kind], control)
end

function AS:ApplyOptionsSkin()
    if not self:IsElvUIAvailable() or not self.skinnables then return end

    local methods = {
        panels = "SkinPanel",
        cards = "SkinCard",
        buttons = "SkinButton",
        checkboxes = "SkinCheckBox",
        sliders = "SkinSlider",
        editboxes = "SkinEditBox",
        scrollframes = "SkinScrollFrame",
    }

    for kind, method in pairs(methods) do
        for _, control in ipairs(self.skinnables[kind] or {}) do
            if self[method] then self[method](self, control) end
        end
    end
end

function AS:CreateText(parent, text, x, y, width, fontObject)
    local label = parent:CreateFontString(nil, "ARTWORK", fontObject or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or PAGE_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text or "")
    return label
end

function AS:CreateParagraph(parent, text, x, y, width, fontObject)
    local label = self:CreateText(parent, text, x, y, width, fontObject)
    local height = 14
    if label.GetStringHeight then
        height = math.ceil(tonumber(label:GetStringHeight()) or height)
    end
    if height < 14 then height = 14 end
    label:SetHeight(height)
    return label, height
end

function AS:CreateCheckbox(parent, name, label, x, y, checked, onClick, tooltip, textWidth)
    local checkBox = CreateFrame("CheckButton", name, parent, "OptionsCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    checkBox:SetChecked(checked and true or false)

    local text = _G[name .. "Text"]
    if text then
        text:SetText(label or "")
        text:SetWidth(textWidth or 220)
        text:SetJustifyH("LEFT")
        text:ClearAllPoints()
        text:SetPoint("LEFT", checkBox, "RIGHT", 5, 1)
    end

    checkBox:SetScript("OnClick", function(self)
        if onClick then onClick(self:GetChecked() and true or false) end
    end)

    self:RegisterSkinnable("checkboxes", checkBox)
    self:SkinCheckBox(checkBox)
    SetTooltip(checkBox, label, tooltip)
    return checkBox
end

function AS:CreateButton(parent, name, label, x, y, width, onClick)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width or 120)
    button:SetHeight(24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    self:RegisterSkinnable("buttons", button)
    self:SkinButton(button)
    return button
end

function AS:CreateSensitivitySlider(parent, name, x, y, width, value, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(width or 220)
    slider:SetHeight(16)
    slider:SetMinMaxValues(1, 3)
    slider:SetValueStep(1)

    local low = _G[name .. "Low"]
    local high = _G[name .. "High"]
    local title = _G[name .. "Text"]

    if low then
        low:SetText("Relaxed")
        low:ClearAllPoints()
        low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
    end
    if high then
        high:SetText("Aggressive")
        high:ClearAllPoints()
        high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -4)
    end
    if title then
        title:ClearAllPoints()
        title:SetPoint("BOTTOM", slider, "TOP", 0, 5)
        title:SetWidth(width or 220)
    end

    slider:SetScript("OnValueChanged", function(self, newValue)
        newValue = math.floor((newValue or 2) + 0.5)
        local labels = { "Relaxed", "Balanced", "Aggressive" }
        if title then title:SetText("Sensitivity: " .. labels[newValue]) end
        if onChanged and not self.asRefreshing then onChanged(newValue) end
    end)
    slider:SetValue(value or 2)

    self:RegisterSkinnable("sliders", slider)
    self:SkinSlider(slider)
    SetTooltip(slider, "Sensitivity", "Relaxed blocks only strong matches. Aggressive catches more spam but can produce more false positives.")
    return slider
end

function AS:CreateEditBox(parent, name, x, y, width)
    local editBox = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    editBox:SetWidth(width or 430)
    editBox:SetHeight(28)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self:RegisterSkinnable("editboxes", editBox)
    self:SkinEditBox(editBox)
    return editBox
end

function AS:CreateMultilineBox(parent, name, x, y, width, height, text, onSave)
    local scroll = CreateFrame("ScrollFrame", name .. "Scroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    scroll:SetWidth(width or 520)
    scroll:SetHeight(height or 90)

    local editBox = CreateFrame("EditBox", name, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth((width or 520) - 24)
    editBox:SetHeight(math.max(height or 90, 240))
    editBox:SetTextInsets(6, 6, 6, 6)
    editBox:SetText(text or "")
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEditFocusLost", function(self)
        if onSave then onSave(self:GetText() or "") end
    end)
    scroll:SetScrollChild(editBox)

    self:RegisterSkinnable("editboxes", editBox)
    self:RegisterSkinnable("scrollframes", scroll)
    self:SkinEditBox(editBox)
    self:SkinScrollFrame(scroll)
    return editBox, scroll
end

function AS:CreateScrollPage(panel, name)
    local scroll = CreateFrame("ScrollFrame", "AscensionSilencer_" .. name .. "Scroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -14)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 16)

    local page = CreateFrame("Frame", "AscensionSilencer_" .. name .. "Page", scroll)
    page:SetWidth(PAGE_WIDTH)
    page:SetHeight(1)
    scroll:SetScrollChild(page)

    self:RegisterSkinnable("scrollframes", scroll)
    self:SkinScrollFrame(scroll)
    return page
end

function AS:CreateFilterCard(parent, moduleKey, y)
    local safeKey = string.gsub(moduleKey, "[^%w]", "")
    local card = CreateFrame("Frame", "AscensionSilencer_FilterCard_" .. safeKey, parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    card:SetWidth(CARD_WIDTH)
    self:RegisterSkinnable("cards", card)
    self:SkinCard(card)
    return card, safeKey
end

function AS:BuildFiltersPanel(panel)
    local y = -12
    self:CreateText(panel, "Filters", 8, y, PAGE_WIDTH, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Each filter can be disabled or tuned independently.", 8, y, PAGE_WIDTH)
    y = y - 34

    self.controls.modules = {}

    for _, key in ipairs(self.moduleOrder) do
        local moduleKey = key
        local module = self.modules[moduleKey]
        local moduleDB = self:GetModuleDB(moduleKey)
        local card, safeKey = self:CreateFilterCard(panel, moduleKey, y)
        local innerY = -14

        self:CreateText(card, module.name, 14, innerY, CARD_WIDTH - 28, "GameFontNormal")
        innerY = innerY - 23

        local _, descriptionHeight = self:CreateParagraph(card, module.description or "", 14, innerY, CARD_WIDTH - 28)
        innerY = innerY - descriptionHeight - 18

        local enabled = self:CreateCheckbox(card, "AscensionSilencer_Filter_" .. safeKey, "Enabled", 14, innerY, moduleDB.enabled, function(value)
            AS:SetModuleEnabled(moduleKey, value)
        end, module.description, 120)

        local slider = self:CreateSensitivitySlider(card, "AscensionSilencer_Sensitivity_" .. safeKey, 274, innerY - 1, 226, moduleDB.sensitivity, function(value)
            moduleDB.sensitivity = value
        end)

        self.controls.modules[moduleKey] = { enabled = enabled, slider = slider }
        local cardHeight = math.abs(innerY) + 45

        if moduleKey == "StreamAdvertising" then
            local clipY = innerY - 43
            local clips = self:CreateCheckbox(card, "AscensionSilencer_AllowClips", "Allow Twitch clip links", 14, clipY, moduleDB.allowClips, function(value)
                moduleDB.allowClips = value
            end, "Allows ordinary Twitch clip links unless the message also contains strong stream-promotion language.", 260)
            self.controls.modules[moduleKey].allowClips = clips
            cardHeight = math.abs(clipY) + 38
        end

        card:SetHeight(cardHeight)
        y = y - cardHeight - 10
    end

    panel:SetHeight(math.abs(y) + 12)
end

function AS:CreateOptionsPanel(name, parentName)
    local panel = CreateFrame("Frame", "AscensionSilencerOptions_" .. string.gsub(name, "%s", ""), InterfaceOptionsFramePanelContainer)
    panel.name = name
    panel.parent = parentName
    self:RegisterSkinnable("panels", panel)
    self:SkinPanel(panel)
    InterfaceOptions_AddCategory(panel)
    return panel
end

function AS:BuildOptions()
    self.controls = {}
    self.skinnables = {}

    local general = self:CreateOptionsPanel("Ascension Silencer", nil)
    self.optionsPanel = general
    self:BuildGeneralPanel(general)

    local filters = self:CreateOptionsPanel("Filters", "Ascension Silencer")
    self.filtersPanel = filters
    self.filtersPage = self:CreateScrollPage(filters, "Filters")
    self:BuildFiltersPanel(self.filtersPage)

    local exceptions = self:CreateOptionsPanel("Exceptions", "Ascension Silencer")
    self.exceptionsPanel = exceptions
    self.exceptionsPage = self:CreateScrollPage(exceptions, "Exceptions")
    self:BuildExceptionsPanel(self.exceptionsPage)

    local review = self:CreateOptionsPanel("Review", "Ascension Silencer")
    self.reviewPanel = review
    self:BuildReviewPanel(review)

    self:ApplyOptionsSkin()
    self:RefreshOptions()
end
