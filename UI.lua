local AS = AscensionSilencer

local PAGE_WIDTH = 548
local CARD_WIDTH = 532
local REVIEW_ROW_HEIGHT = 22
local REVIEW_VIEW_HEIGHT = 220
local REVIEW_VIEW_WIDTH = 540
local REVIEW_ROW_WIDTH = 508
local REVIEW_VISIBLE_ROWS = math.ceil(REVIEW_VIEW_HEIGHT / REVIEW_ROW_HEIGHT) + 2

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
    self.skinnables[kind][#self.skinnables[kind] + 1] = control
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
    SetTooltip(slider, label, tooltip)
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

function AS:BuildGeneralPanel(panel)
    local y = -16
    self:CreateText(panel, "Ascension Silencer", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Keeps public chat focused on conversation, groups and normal server activity.", 16, y, 560)
    y = y - 38

    self.controls.master = self:CreateCheckbox(panel, "AscensionSilencer_Master", "Enable Ascension Silencer", 16, y, self.db.enabled, function(value)
        AS:SetMasterEnabled(value)
    end, "Turns all filtering on or off.", 420)
    y = y - 38

    self:CreateText(panel, "Channels", 16, y, 560, "GameFontNormal")
    y = y - 28

    self.controls.public = self:CreateCheckbox(panel, "AscensionSilencer_Public", "Public channels", 28, y, self.db.channels.public, function(value)
        AS.db.channels.public = value
    end, "Filters numbered public channels such as Ascension, General, Trade and Newcomers.", 420)
    y = y - 30

    self.controls.say = self:CreateCheckbox(panel, "AscensionSilencer_Say", "Say", 28, y, self.db.channels.say, function(value)
        AS.db.channels.say = value
    end, "Optional. Disabled by default.", 420)
    y = y - 30

    self.controls.yell = self:CreateCheckbox(panel, "AscensionSilencer_Yell", "Yell", 28, y, self.db.channels.yell, function(value)
        AS.db.channels.yell = value
    end, "Optional. Disabled by default.", 420)
    y = y - 44

    self.statusText = self:CreateText(panel, "", 16, y, 560, "GameFontHighlight")
    y = y - 26
    self:CreateText(panel, "Use the sections under Ascension Silencer in the AddOns menu to configure filters, exceptions and review blocked messages.", 16, y, 560)
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

function AS:BuildExceptionsPanel(panel)
    local y = -16
    self:CreateText(panel, "Exceptions", 16, y, 560, "GameFontNormalLarge")
    y = y - 30
    self:CreateText(panel, "Trusted people bypass every filter.", 16, y, 560)
    y = y - 38

    local exceptions = self.db.exceptions
    self.controls.allowSelf = self:CreateCheckbox(panel, "AscensionSilencer_AllowSelf", "Always allow my messages", 16, y, exceptions.allowSelf, function(value)
        exceptions.allowSelf = value
    end, nil, 420)
    y = y - 30

    self.controls.allowFriends = self:CreateCheckbox(panel, "AscensionSilencer_AllowFriends", "Always allow friends", 16, y, exceptions.allowFriends, function(value)
        exceptions.allowFriends = value
    end, nil, 420)
    y = y - 30

    self.controls.allowGuild = self:CreateCheckbox(panel, "AscensionSilencer_AllowGuild", "Always allow guild members", 16, y, exceptions.allowGuild, function(value)
        exceptions.allowGuild = value
    end, nil, 420)
    y = y - 30

    self.controls.allowGroup = self:CreateCheckbox(panel, "AscensionSilencer_AllowGroup", "Always allow party and raid members", 16, y, exceptions.allowGroup, function(value)
        exceptions.allowGroup = value
    end, nil, 420)
    y = y - 42

    self:CreateText(panel, "Player whitelist - one name per line", 16, y, 560, "GameFontNormal")
    y = y - 22
    self.playerListBox = self:CreateMultilineBox(panel, "AscensionSilencer_PlayerList", 16, y, 540, 82, self:ListToText(exceptions.players), function(text)
        exceptions.players = AS:TextToList(text)
        AS:RebuildExceptionCache()
    end)
    y = y - 104

    self:CreateText(panel, "Phrase whitelist - one phrase per line", 16, y, 560, "GameFontNormal")
    y = y - 22
    self.phraseListBox = self:CreateMultilineBox(panel, "AscensionSilencer_PhraseList", 16, y, 540, 82, self:ListToText(exceptions.phrases), function(text)
        exceptions.phrases = AS:TextToList(text)
        AS:RebuildExceptionCache()
    end)
    y = y - 104

    panel:SetHeight(math.abs(y) + 24)
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

function AS:ResetHygieneHistory()
    self.hygieneHistory = {}
    self.hygieneMessageCounter = 0
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
        AS:ResetHygieneHistory()
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
        AS:ResetHygieneHistory()
    end, "Shows the first suitable copy and hides rapid copies in other public channels.", 440)
    y = y - 52

    controls.duplicateWindow = self:CreateHygieneSlider(panel, "AscensionSilencer_DuplicateWindow", "Cross-channel window", 40, y, 260, 5, 30, 1, settings.duplicateWindow, "s", function(value)
        settings.duplicateWindow = value
        AS:ResetHygieneHistory()
    end, "How long copies posted in different public channels count as immediate duplicates.")
    y = y - 58

    controls.throttleRepeats = self:CreateCheckbox(panel, "AscensionSilencer_ThrottleRepeats", "Throttle repeated messages", 28, y, settings.throttleRepeats, function(value)
        settings.throttleRepeats = value
        AS:ResetHygieneHistory()
    end, "Suppresses the same normalized message from the same sender until its cooldown expires.", 440)
    y = y - 54

    controls.repeatCooldown = self:CreateHygieneSlider(panel, "AscensionSilencer_RepeatCooldown", "General repeat cooldown", 40, y, 260, 15, 180, 15, settings.repeatCooldown, "s", function(value)
        settings.repeatCooldown = value
        AS:ResetHygieneHistory()
    end, "Cooldown for trade advertisements and ordinary public messages.")

    controls.lfgCooldown = self:CreateHygieneSlider(panel, "AscensionSilencer_LFGCooldown", "LFG repeat cooldown", 326, y, 220, 15, 120, 15, settings.lfgCooldown, "s", function(value)
        settings.lfgCooldown = value
        AS:ResetHygieneHistory()
    end, "A shorter cooldown for LFG and LFM messages because group needs change more quickly.")
    y = y - 72

    controls.tradeChannel = self:CreateHygieneSlider(panel, "AscensionSilencer_TradeChannel", "Fallback Trade channel", 40, y, 260, 1, 10, 1, settings.tradeChannel, "", function(value)
        settings.tradeChannel = value
        AS:ResetHygieneHistory()
    end, "Used when the channel name does not contain Trade. Project Ascension normally uses /4.")

    panel:SetScript("OnShow", function() AS:RefreshHygienePanel() end)
end

local function BindReviewTooltip(row)
    if not row or row.asReviewTooltipBound then return end
    row.asReviewTooltipBound = true

    row:SetScript("OnEnter", function(self)
        local entry = self.reviewEntry
        if not entry or not GameTooltip then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(entry.reason or entry.moduleName or "Filtered message", 1, 1, 1)
        GameTooltip:AddLine("Score: " .. tostring(entry.score) .. "/" .. tostring(entry.threshold), nil, nil, nil, true)
        GameTooltip:AddLine("Channel: " .. tostring(entry.channel), nil, nil, nil, true)
        GameTooltip:AddLine("Matched: " .. AS:FormatMatches(entry.matches), nil, nil, nil, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(tostring(entry.message or ""), nil, nil, nil, true)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
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

    local scroll = CreateFrame("ScrollFrame", "AscensionSilencer_ReviewScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    scroll:SetWidth(REVIEW_VIEW_WIDTH)
    scroll:SetHeight(REVIEW_VIEW_HEIGHT)
    scroll:EnableMouseWheel(true)

    local child = CreateFrame("Frame", "AscensionSilencer_ReviewScrollChild", scroll)
    child:SetWidth(REVIEW_ROW_WIDTH)
    child:SetHeight(REVIEW_VIEW_HEIGHT)
    scroll:SetScrollChild(child)

    self.reviewScroll = scroll
    self.reviewScrollChild = child
    self.reviewRows = {}

    for index = 1, REVIEW_VISIBLE_ROWS do
        local row = CreateFrame("Button", "AscensionSilencer_ReviewRow" .. index, child)
        row:SetWidth(REVIEW_ROW_WIDTH)
        row:SetHeight(20)

        local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetAllPoints(row)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
        row.text = text

        BindReviewTooltip(row)
        self.reviewRows[index] = row
    end

    scroll:SetScript("OnVerticalScroll", function(self, offset)
        if self.asAdjusting then return end
        self:SetVerticalScroll(offset)
        AS:RefreshReviewPanel()
    end)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = self:GetVerticalScrollRange() or 0
        local nextValue = current - (delta * REVIEW_ROW_HEIGHT * 3)
        if nextValue < 0 then nextValue = 0 end
        if nextValue > maximum then nextValue = maximum end
        self:SetVerticalScroll(nextValue)
        AS:RefreshReviewPanel()
    end)

    self:RegisterSkinnable("scrollframes", scroll)
    self:SkinScrollFrame(scroll)

    y = y - REVIEW_VIEW_HEIGHT - 14
    self:CreateText(panel, "Test a message", 16, y, 560, "GameFontNormal")
    y = y - 26

    self.testBox = self:CreateEditBox(panel, "AscensionSilencer_TestBox", 16, y, 430)
    self:CreateButton(panel, "AscensionSilencer_TestButton", "Test", 460, y + 1, 96, function()
        local message = AS.testBox and AS.testBox:GetText() or ""
        local result, evaluations = AS:TestMessage(message)
        if result then
            AS.testResult:SetText("|cffff5555BLOCKED|r by " .. result.moduleName .. " - score " .. result.score .. "/" .. result.threshold .. "\nMatched: " .. AS:FormatMatches(result.matches))
        else
            local best = nil
            for _, evaluation in ipairs(evaluations or {}) do
                if not best or evaluation.score > best.score then best = evaluation end
            end
            if best then
                AS.testResult:SetText("|cff55ff55ALLOWED|r - closest match: " .. best.moduleName .. " " .. best.score .. "/" .. best.threshold .. "\nMatched: " .. AS:FormatMatches(best.matches))
            else
                AS.testResult:SetText("|cff55ff55ALLOWED|r - no enabled filters matched.")
            end
        end
    end)

    y = y - 38
    self.testResult = self:CreateText(panel, "", 16, y, 560, "GameFontHighlightSmall")
    self.testResult:SetHeight(52)
    self.testResult:SetJustifyV("TOP")

    panel:SetScript("OnShow", function() AS:RefreshReviewPanel() end)
end

function AS:RefreshReviewPanel()
    local count = self:GetHistoryCount()

    if self.reviewSummary then
        self.reviewSummary:SetText("Blocked this session: " .. tostring(self.sessionStats.total or 0) .. "   Stored for review: " .. tostring(count))
    end
    if not self.reviewRows then return end

    local contentHeight = math.max(REVIEW_VIEW_HEIGHT, count * REVIEW_ROW_HEIGHT)
    if self.reviewScrollChild then self.reviewScrollChild:SetHeight(contentHeight) end

    local scrollOffset = self.reviewScroll and (self.reviewScroll:GetVerticalScroll() or 0) or 0
    local maximum = self.reviewScroll and (self.reviewScroll:GetVerticalScrollRange() or 0) or 0
    if scrollOffset > maximum and self.reviewScroll then
        self.reviewScroll.asAdjusting = true
        self.reviewScroll:SetVerticalScroll(maximum)
        self.reviewScroll.asAdjusting = false
        scrollOffset = maximum
    end

    local firstIndex = math.floor(scrollOffset / REVIEW_ROW_HEIGHT) + 1
    for slot, row in ipairs(self.reviewRows) do
        local historyIndex = firstIndex + slot - 1
        local entry = self:GetHistoryEntry(historyIndex)
        row.reviewEntry = entry

        if entry then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.reviewScrollChild, "TOPLEFT", 0, -((historyIndex - 1) * REVIEW_ROW_HEIGHT))
            local message = tostring(entry.message or "")
            if string.len(message) > 68 then message = string.sub(message, 1, 65) .. "..." end
            row.text:SetText(string.format("%s  [%s] %s: %s", entry.time or "", entry.moduleName or "Filter", entry.sender or "Unknown", message))
            row:Show()
        else
            row.text:SetText("")
            row:Hide()
        end
    end

    if count == 0 and self.reviewScroll then
        self.reviewScroll.asAdjusting = true
        self.reviewScroll:SetVerticalScroll(0)
        self.reviewScroll.asAdjusting = false
    end
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

    self:RefreshHygienePanel()
    self:RefreshReviewPanel()
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

    local hygiene = self:CreateOptionsPanel("Channel Hygiene", "Ascension Silencer")
    self.hygienePanel = hygiene
    self:BuildHygienePanel(hygiene)

    local review = self:CreateOptionsPanel("Review", "Ascension Silencer")
    self.reviewPanel = review
    self:BuildReviewPanel(review)

    self:ApplyOptionsSkin()
    self:RefreshOptions()
end

function AS:OpenOptions()
    if not self.optionsPanel then return end
    InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
end
