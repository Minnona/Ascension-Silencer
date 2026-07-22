local AS = AscensionSilencer

local function BindTooltip(control, title, text)
    if not control then return end
    control:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text and text ~= "" then
            GameTooltip:AddLine(text, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

function AS:CreateHygieneSlider(parent, name, label, x, y, width, minimum, maximum, step, value, suffix, onChanged, tooltip)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(width or 250)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)

    local low = _G[name .. "Low"]
    local high = _G[name .. "High"]
    local title = _G[name .. "Text"]

    if low then low:SetText(tostring(minimum)) end
    if high then high:SetText(tostring(maximum)) end

    local function UpdateTitle(newValue)
        newValue = math.floor((newValue or minimum) + 0.5)
        if title then title:SetText(label .. ": " .. newValue .. (suffix or "")) end
        return newValue
    end

    slider:SetScript("OnValueChanged", function(self, newValue)
        newValue = UpdateTitle(newValue)
        if onChanged and not self.asRefreshing then onChanged(newValue) end
    end)
    slider:SetValue(value or minimum)

    self:RegisterSkinnable("sliders", slider)
    self:SkinSlider(slider)
    BindTooltip(slider, label, tooltip)
    return slider
end

function AS:RefreshHygienePanel()
    if not self.controls or not self.controls.hygiene or not self.db then return end
    local controls = self.controls.hygiene
    local settings = self.db.hygiene

    local checks = {
        enabled = settings.enabled,
        routeCommercial = settings.routeCommercial,
        keepTradeClean = settings.keepTradeClean,
        suppressCrossChannel = settings.suppressCrossChannel,
        throttleRepeats = settings.throttleRepeats,
    }

    for key, value in pairs(checks) do
        if controls[key] then controls[key]:SetChecked(value and true or false) end
    end

    local sliders = {
        duplicateWindow = settings.duplicateWindow,
        repeatCooldown = settings.repeatCooldown,
        lfgCooldown = settings.lfgCooldown,
        tradeChannel = settings.tradeChannel,
    }

    for key, value in pairs(sliders) do
        local slider = controls[key]
        if slider then
            slider.asRefreshing = true
            slider:SetValue(value)
            slider.asRefreshing = false
        end
    end
end

function AS:BuildHygienePanel(panel)
    local settings = self.db.hygiene
    local y = -16

    self:CreateText(panel, "Channel Hygiene", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Routes posts to appropriate public channels and suppresses repeated copies from the same sender.", 16, y, 560)
    y = y - 40

    self.controls.hygiene = {}
    local controls = self.controls.hygiene

    controls.enabled = self:CreateCheckbox(panel, "AscensionSilencer_HygieneEnabled", "Enable Channel Hygiene", 16, y, settings.enabled, function(value)
        settings.enabled = value
        AS.hygieneHistory = {}
    end, "Turns channel routing and repeat throttling on or off.", 420)
    y = y - 36

    controls.routeCommercial = self:CreateCheckbox(panel, "AscensionSilencer_RouteCommercial", "Hide commercial posts outside Trade", 28, y, settings.routeCommercial, function(value)
        settings.routeCommercial = value
    end, "WTS, WTB, WTT, priced item sales and crafting services are allowed in Trade and hidden in other public channels.", 440)
    y = y - 30

    controls.keepTradeClean = self:CreateCheckbox(panel, "AscensionSilencer_KeepTradeClean", "Hide non-commercial posts in Trade", 28, y, settings.keepTradeClean, function(value)
        settings.keepTradeClean = value
    end, "Keeps LFG, conversation and unrelated messages out of Trade.", 440)
    y = y - 30

    controls.suppressCrossChannel = self:CreateCheckbox(panel, "AscensionSilencer_CrossChannel", "Suppress cross-channel duplicates", 28, y, settings.suppressCrossChannel, function(value)
        settings.suppressCrossChannel = value
        AS.hygieneHistory = {}
    end, "Shows the first suitable copy and hides rapid copies in other public channels.", 440)
    y = y - 52

    controls.duplicateWindow = self:CreateHygieneSlider(panel, "AscensionSilencer_DuplicateWindow", "Cross-channel window", 40, y, 260, 5, 30, 1, settings.duplicateWindow, "s", function(value)
        settings.duplicateWindow = value
        AS.hygieneHistory = {}
    end, "How long copies posted in different public channels count as immediate duplicates.")
    y = y - 58

    controls.throttleRepeats = self:CreateCheckbox(panel, "AscensionSilencer_ThrottleRepeats", "Throttle repeated messages", 28, y, settings.throttleRepeats, function(value)
        settings.throttleRepeats = value
        AS.hygieneHistory = {}
    end, "Suppresses the same normalized message from the same sender until its cooldown expires.", 440)
    y = y - 54

    controls.repeatCooldown = self:CreateHygieneSlider(panel, "AscensionSilencer_RepeatCooldown", "General repeat cooldown", 40, y, 260, 15, 180, 15, settings.repeatCooldown, "s", function(value)
        settings.repeatCooldown = value
        AS.hygieneHistory = {}
    end, "Cooldown for trade advertisements and ordinary public messages.")

    controls.lfgCooldown = self:CreateHygieneSlider(panel, "AscensionSilencer_LFGCooldown", "LFG repeat cooldown", 326, y, 220, 15, 120, 15, settings.lfgCooldown, "s", function(value)
        settings.lfgCooldown = value
        AS.hygieneHistory = {}
    end, "A shorter cooldown for LFG and LFM messages because group needs change more quickly.")
    y = y - 72

    controls.tradeChannel = self:CreateHygieneSlider(panel, "AscensionSilencer_TradeChannel", "Fallback Trade channel", 40, y, 260, 1, 10, 1, settings.tradeChannel, "", function(value)
        settings.tradeChannel = value
        AS.hygieneHistory = {}
    end, "Used when the channel name does not contain Trade. Project Ascension normally uses /4.")

    panel:SetScript("OnShow", function() AS:RefreshHygienePanel() end)
end

local OriginalBuildOptions = AS.BuildOptions
function AS:BuildOptions()
    OriginalBuildOptions(self)

    local hygiene = self:CreateOptionsPanel("Channel Hygiene", "Ascension Silencer")
    self.hygienePanel = hygiene
    self:BuildHygienePanel(hygiene)

    self:ApplyOptionsSkin()
    self:RefreshHygienePanel()
end
