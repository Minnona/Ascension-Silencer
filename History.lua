local AS = AscensionSilencer

AS.history = {}
AS.historyLimit = 100
AS.historyCount = 0
AS.historyNext = 1

function AS:GetHistoryCount()
    return tonumber(self.historyCount) or 0
end

function AS:GetHistoryEntry(displayIndex)
    displayIndex = tonumber(displayIndex)
    local count = self:GetHistoryCount()
    local limit = tonumber(self.historyLimit) or 100
    if not displayIndex or displayIndex < 1 or displayIndex > count then return nil end

    local slot = ((self.historyNext - displayIndex - 1) % limit) + 1
    return self.history[slot]
end

function AS:RefreshVisibleHistoryUI()
    if self.optionsPanel and self.optionsPanel:IsVisible() and self.statusText then
        local state = self.db and self.db.enabled and "|cff55ff55Enabled|r" or "|cffff5555Disabled|r"
        self.statusText:SetText("Status: " .. state .. "   Blocked this session: " .. tostring(self.sessionStats.total or 0))
    end

    if self.reviewPanel and self.reviewPanel:IsVisible() and self.RefreshReviewPanel then
        self:RefreshReviewPanel()
    end
end

function AS:AddBlockedMessage(entry)
    if type(entry) ~= "table" then return end

    entry.time = entry.time or (date and date("%H:%M:%S") or "")

    local limit = tonumber(self.historyLimit) or 100
    self.history[self.historyNext] = entry
    self.historyNext = (self.historyNext % limit) + 1
    self.historyCount = math.min(limit, self:GetHistoryCount() + 1)

    self.sessionStats.total = (self.sessionStats.total or 0) + 1
    self.sessionStats.byModule[entry.moduleKey] = (self.sessionStats.byModule[entry.moduleKey] or 0) + 1
    self:RefreshVisibleHistoryUI()
end

function AS:ClearHistory()
    self.history = {}
    self.historyCount = 0
    self.historyNext = 1
    if self.RefreshReviewPanel then self:RefreshReviewPanel() end
end

function AS:FormatMatches(matches)
    if type(matches) ~= "table" or #matches == 0 then return "None" end
    return table.concat(matches, ", ")
end
