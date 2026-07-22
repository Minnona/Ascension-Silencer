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

local REVIEW_ROW_HEIGHT = 22
local REVIEW_VIEW_HEIGHT = 220
local REVIEW_VIEW_WIDTH = 540
local REVIEW_ROW_WIDTH = 508

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
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = self:GetVerticalScrollRange() or 0
        local nextValue = current - (delta * REVIEW_ROW_HEIGHT * 3)
        if nextValue < 0 then nextValue = 0 end
        if nextValue > maximum then nextValue = maximum end
        self:SetVerticalScroll(nextValue)
    end)

    local child = CreateFrame("Frame", "AscensionSilencer_ReviewScrollChild", scroll)
    child:SetWidth(REVIEW_ROW_WIDTH)
    child:SetHeight(REVIEW_VIEW_HEIGHT)
    scroll:SetScrollChild(child)

    self.reviewScroll = scroll
    self.reviewScrollChild = child
    self.reviewRows = {}

    local rowLimit = tonumber(self.historyLimit) or 100
    for index = 1, rowLimit do
        local row = CreateFrame("Button", "AscensionSilencer_ReviewRow" .. index, child)
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -((index - 1) * REVIEW_ROW_HEIGHT))
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

    panel:SetScript("OnShow", function()
        AS:RefreshReviewPanel()
    end)
end

function AS:RefreshReviewPanel()
    local history = self.history or {}

    if self.reviewSummary then
        self.reviewSummary:SetText("Blocked this session: " .. tostring(self.sessionStats.total or 0) .. "   Stored for review: " .. tostring(#history))
    end

    if not self.reviewRows then return end

    local contentHeight = math.max(REVIEW_VIEW_HEIGHT, #history * REVIEW_ROW_HEIGHT)
    if self.reviewScrollChild then self.reviewScrollChild:SetHeight(contentHeight) end

    for index, row in ipairs(self.reviewRows) do
        local entry = history[index]
        row.reviewEntry = entry

        if entry then
            local message = tostring(entry.message or "")
            if string.len(message) > 68 then message = string.sub(message, 1, 65) .. "..." end
            row.text:SetText(string.format("%s  [%s] %s: %s", entry.time or "", entry.moduleName or "Filter", entry.sender or "Unknown", message))
            row:Show()
        else
            row.text:SetText("")
            row:Hide()
        end
    end

    if self.reviewScroll then
        local maximum = self.reviewScroll:GetVerticalScrollRange() or 0
        local current = self.reviewScroll:GetVerticalScroll() or 0
        if current > maximum then self.reviewScroll:SetVerticalScroll(maximum) end
        if #history == 0 then self.reviewScroll:SetVerticalScroll(0) end
    end
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
    self:RefreshHygienePanel()
end
