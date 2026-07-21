local AS = AscensionSilencer

local function SetTooltip(control, title, text)
    if not control then return end
    control:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "Ascension Silencer", 1, 1, 1)
        if text and text ~= "" then
            GameTooltip:AddLine(text, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

function AS:CreateText(parent, text, x, y, width, fontObject)
    local label = parent:CreateFontString(nil, "ARTWORK", fontObject or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 560)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    return label
end

function AS:CreateCheckbox(parent, name, label, x, y, checked, onClick, tooltip)
    local checkBox = CreateFrame("CheckButton", name, parent, "OptionsCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    checkBox:SetChecked(checked and true or false)

    local text = _G[name .. "Text"]
    if text then
        text:SetText(label or "")
        text:SetWidth(500)
        text:SetJustifyH("LEFT")
    end

    checkBox:SetScript("OnClick", function(self)
        if onClick then onClick(self:GetChecked() and true or false) end
    end)

    SetTooltip(checkBox, label, tooltip)
    self:SkinCheckBox(checkBox)
    return checkBox
end

function AS:CreateButton(parent, name, label, x, y, width, onClick)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width or 120)
    button:SetHeight(24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    self:SkinButton(button)
    return button
end

function AS:CreateSensitivitySlider(parent, name, x, y, value, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(180)
    slider:SetHeight(16)
    slider:SetMinMaxValues(1, 3)
    slider:SetValueStep(1)
    slider:SetValue(value or 2)

    _G[name .. "Low"]:SetText("Relaxed")
    _G[name .. "High"]:SetText("Aggressive")
    _G[name .. "Text"]:SetText("Sensitivity: Balanced")

    slider:SetScript("OnValueChanged", function(self, newValue)
        newValue = math.floor((newValue or 2) + 0.5)
        local labels = { "Relaxed", "Balanced", "Aggressive" }
        _G[name .. "Text"]:SetText("Sensitivity: " .. labels[newValue])
        if onChanged and not self.asRefreshing then onChanged(newValue) end
    end)

    SetTooltip(slider, "Sensitivity", "Relaxed blocks only strong matches. Aggressive catches more spam but can produce more false positives.")
    self:SkinSlider(slider)
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

    self:SkinEditBox(editBox)
    self:SkinScrollFrame(scroll)
    return editBox, scroll
end


function AS:CreateScrollPage(panel, name)
    local scroll = CreateFrame("ScrollFrame", "AscensionSilencer_" .. name .. "Scroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 14)

    local page = CreateFrame("Frame", "AscensionSilencer_" .. name .. "Page", scroll)
    page:SetWidth(580)
    page:SetHeight(1)
    scroll:SetScrollChild(page)
    self:SkinScrollFrame(scroll)
    return page
end

function AS:BuildGeneralPanel(panel)
    local y = -16
    self:CreateText(panel, "Ascension Silencer", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Keeps public chat focused on conversation, groups and normal server activity.", 16, y, 560)
    y = y - 38

    self.controls.master = self:CreateCheckbox(panel, "AscensionSilencer_Master", "Enable Ascension Silencer", 16, y, self.db.enabled, function(value)
        AS:SetMasterEnabled(value)
    end, "Turns all filtering on or off.")
    y = y - 38

    self:CreateText(panel, "Channels", 16, y, 560, "GameFontNormal")
    y = y - 28

    self.controls.public = self:CreateCheckbox(panel, "AscensionSilencer_Public", "Public channels", 28, y, self.db.channels.public, function(value)
        AS.db.channels.public = value
    end, "Filters numbered public channels such as Ascension, General, Trade and Newcomers.")
    y = y - 30

    self.controls.say = self:CreateCheckbox(panel, "AscensionSilencer_Say", "Say", 28, y, self.db.channels.say, function(value)
        AS.db.channels.say = value
    end, "Optional. Disabled by default.")
    y = y - 30

    self.controls.yell = self:CreateCheckbox(panel, "AscensionSilencer_Yell", "Yell", 28, y, self.db.channels.yell, function(value)
        AS.db.channels.yell = value
    end, "Optional. Disabled by default.")
    y = y - 44

    self.statusText = self:CreateText(panel, "", 16, y, 560, "GameFontHighlight")
    y = y - 26
    self:CreateText(panel, "Use the sections under Ascension Silencer in the AddOns menu to configure filters, exceptions and review blocked messages.", 16, y, 560)
end

function AS:BuildFiltersPanel(panel)
    local y = -16
    self:CreateText(panel, "Filters", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Each filter can be disabled or tuned independently.", 16, y, 560)
    y = y - 38

    self.controls.modules = {}

    for _, key in ipairs(self.moduleOrder) do
        local moduleKey = key
        local module = self.modules[moduleKey]
        local moduleDB = self:GetModuleDB(moduleKey)
        local safeKey = string.gsub(moduleKey, "[^%w]", "")

        self:CreateText(panel, module.name, 16, y, 560, "GameFontNormal")
        y = y - 24
        self:CreateText(panel, module.description or "", 28, y, 540)
        y = y - 30

        local enabled = self:CreateCheckbox(panel, "AscensionSilencer_Filter_" .. safeKey, "Enabled", 28, y, moduleDB.enabled, function(value)
            AS:SetModuleEnabled(moduleKey, value)
        end, module.description)

        local slider = self:CreateSensitivitySlider(panel, "AscensionSilencer_Sensitivity_" .. safeKey, 210, y - 2, moduleDB.sensitivity, function(value)
            moduleDB.sensitivity = value
        end)

        self.controls.modules[moduleKey] = { enabled = enabled, slider = slider }
        y = y - 42

        if moduleKey == "StreamAdvertising" then
            local clips = self:CreateCheckbox(panel, "AscensionSilencer_AllowClips", "Allow Twitch clip links", 42, y, moduleDB.allowClips, function(value)
                moduleDB.allowClips = value
            end, "Allows ordinary Twitch clip links unless the message also contains strong stream-promotion language.")
            self.controls.modules[moduleKey].allowClips = clips
            y = y - 34
        end

        y = y - 18
    end

    panel:SetHeight(math.abs(y) + 24)
end

function AS:BuildExceptionsPanel(panel)
    local y = -16
    self:CreateText(panel, "Exceptions", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Trusted people bypass every filter.", 16, y, 560)
    y = y - 38

    local exceptions = self.db.exceptions
    self.controls.allowSelf = self:CreateCheckbox(panel, "AscensionSilencer_AllowSelf", "Always allow my messages", 16, y, exceptions.allowSelf, function(value)
        exceptions.allowSelf = value
    end)
    y = y - 30

    self.controls.allowFriends = self:CreateCheckbox(panel, "AscensionSilencer_AllowFriends", "Always allow friends", 16, y, exceptions.allowFriends, function(value)
        exceptions.allowFriends = value
    end)
    y = y - 30

    self.controls.allowGuild = self:CreateCheckbox(panel, "AscensionSilencer_AllowGuild", "Always allow guild members", 16, y, exceptions.allowGuild, function(value)
        exceptions.allowGuild = value
    end)
    y = y - 30

    self.controls.allowGroup = self:CreateCheckbox(panel, "AscensionSilencer_AllowGroup", "Always allow party and raid members", 16, y, exceptions.allowGroup, function(value)
        exceptions.allowGroup = value
    end)
    y = y - 42

    self:CreateText(panel, "Player whitelist — one name per line", 16, y, 560, "GameFontNormal")
    y = y - 22
    self.playerListBox = self:CreateMultilineBox(panel, "AscensionSilencer_PlayerList", 16, y, 540, 82, self:ListToText(exceptions.players), function(text)
        exceptions.players = AS:TextToList(text)
    end)
    y = y - 104

    self:CreateText(panel, "Phrase whitelist — one phrase per line", 16, y, 560, "GameFontNormal")
    y = y - 22
    self.phraseListBox = self:CreateMultilineBox(panel, "AscensionSilencer_PhraseList", 16, y, 540, 82, self:ListToText(exceptions.phrases), function(text)
        exceptions.phrases = AS:TextToList(text)
    end)
    y = y - 104

    panel:SetHeight(math.abs(y) + 24)
end

function AS:BuildReviewPanel(panel)
    local y = -16
    self:CreateText(panel, "Review", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self.reviewSummary = self:CreateText(panel, "", 16, y, 560)
    y = y - 32

    self:CreateButton(panel, "AscensionSilencer_RefreshHistory", "Refresh", 16, y, 100, function()
        AS:RefreshReviewPanel()
    end)
    self:CreateButton(panel, "AscensionSilencer_ClearHistory", "Clear", 126, y, 100, function()
        AS:ClearHistory()
    end)
    y = y - 38

    self.reviewRows = {}
    for index = 1, 9 do
        local row = CreateFrame("Button", "AscensionSilencer_ReviewRow" .. index, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
        row:SetWidth(560)
        row:SetHeight(20)

        local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetAllPoints(row)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
        row.text = text

        self.reviewRows[index] = row
        y = y - 22
    end

    y = y - 10
    self:CreateText(panel, "Test a message", 16, y, 560, "GameFontNormal")
    y = y - 26
    self.testBox = self:CreateEditBox(panel, "AscensionSilencer_TestBox", 16, y, 430)
    self:CreateButton(panel, "AscensionSilencer_TestButton", "Test", 460, y + 1, 96, function()
        local message = AS.testBox and AS.testBox:GetText() or ""
        local result, evaluations = AS:TestMessage(message)
        if result then
            AS.testResult:SetText("|cffff5555BLOCKED|r by " .. result.moduleName .. " — score " .. result.score .. "/" .. result.threshold .. "\nMatched: " .. AS:FormatMatches(result.matches))
        else
            local best = nil
            for _, evaluation in ipairs(evaluations or {}) do
                if not best or evaluation.score > best.score then best = evaluation end
            end
            if best then
                AS.testResult:SetText("|cff55ff55ALLOWED|r — closest match: " .. best.moduleName .. " " .. best.score .. "/" .. best.threshold .. "\nMatched: " .. AS:FormatMatches(best.matches))
            else
                AS.testResult:SetText("|cff55ff55ALLOWED|r — no enabled filters matched.")
            end
        end
    end)
    y = y - 38
    self.testResult = self:CreateText(panel, "", 16, y, 560, "GameFontHighlightSmall")
    self.testResult:SetHeight(52)
    self.testResult:SetJustifyV("TOP")

    panel:SetScript("OnShow", function()
        AS:RefreshReviewPanel()
    end)
end

function AS:CreateOptionsPanel(name, parentName)
    local panel = CreateFrame("Frame", "AscensionSilencerOptions_" .. string.gsub(name, "%s", ""), InterfaceOptionsFramePanelContainer)
    panel.name = name
    panel.parent = parentName
    self:SkinPanel(panel)
    InterfaceOptions_AddCategory(panel)
    return panel
end

function AS:BuildOptions()
    self.controls = {}

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

    self:RefreshOptions()
end

function AS:RefreshReviewPanel()
    if self.reviewSummary then
        self.reviewSummary:SetText("Blocked this session: " .. tostring(self.sessionStats.total or 0) .. "   Stored for review: " .. tostring(#self.history))
    end

    if not self.reviewRows then return end
    for index, row in ipairs(self.reviewRows) do
        local entry = self.history[index]
        if entry then
            local message = tostring(entry.message or "")
            if string.len(message) > 72 then message = string.sub(message, 1, 69) .. "..." end
            row.text:SetText(string.format("%s  [%s] %s: %s", entry.time or "", entry.moduleName or "Filter", entry.sender or "Unknown", message))
            SetTooltip(row, entry.reason or entry.moduleName, "Score: " .. tostring(entry.score) .. "/" .. tostring(entry.threshold) .. "\nChannel: " .. tostring(entry.channel) .. "\nMatched: " .. self:FormatMatches(entry.matches) .. "\n\n" .. tostring(entry.message))
            row:Show()
        else
            row.text:SetText("")
            row:SetScript("OnEnter", nil)
            row:SetScript("OnLeave", nil)
            row:Hide()
        end
    end
end

function AS:RefreshOptions()
    if not self.db or not self.controls then return end

    if self.controls.master then self.controls.master:SetChecked(self.db.enabled) end
    if self.controls.public then self.controls.public:SetChecked(self.db.channels.public) end
    if self.controls.say then self.controls.say:SetChecked(self.db.channels.say) end
    if self.controls.yell then self.controls.yell:SetChecked(self.db.channels.yell) end
    if self.controls.allowSelf then self.controls.allowSelf:SetChecked(self.db.exceptions.allowSelf) end
    if self.controls.allowFriends then self.controls.allowFriends:SetChecked(self.db.exceptions.allowFriends) end
    if self.controls.allowGuild then self.controls.allowGuild:SetChecked(self.db.exceptions.allowGuild) end
    if self.controls.allowGroup then self.controls.allowGroup:SetChecked(self.db.exceptions.allowGroup) end

    if self.controls.modules then
        for key, controls in pairs(self.controls.modules) do
            local moduleDB = self:GetModuleDB(key)
            if controls.enabled then controls.enabled:SetChecked(moduleDB.enabled) end
            if controls.slider then
                controls.slider.asRefreshing = true
                controls.slider:SetValue(moduleDB.sensitivity or 2)
                controls.slider.asRefreshing = false
            end
            if controls.allowClips then controls.allowClips:SetChecked(moduleDB.allowClips) end
        end
    end

    if self.statusText then
        local state = self.db.enabled and "|cff55ff55Enabled|r" or "|cffff5555Disabled|r"
        self.statusText:SetText("Status: " .. state .. "   Blocked this session: " .. tostring(self.sessionStats.total or 0))
    end

    self:RefreshReviewPanel()
end

function AS:OpenOptions()
    if not self.optionsPanel then return end
    InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
end
