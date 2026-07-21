local AS = AscensionSilencer

AS.history = AS.history or {}
AS.historyLimit = 100

function AS:AddBlockedMessage(entry)
    if type(entry) ~= "table" then return end

    entry.time = entry.time or (date and date("%H:%M:%S") or "")
    table.insert(self.history, 1, entry)

    while #self.history > self.historyLimit do
        table.remove(self.history)
    end

    self.sessionStats.total = (self.sessionStats.total or 0) + 1
    self.sessionStats.byModule[entry.moduleKey] = (self.sessionStats.byModule[entry.moduleKey] or 0) + 1

    local optionsVisible = self.optionsPanel and self.optionsPanel:IsVisible()
    local reviewVisible = self.reviewPanel and self.reviewPanel:IsVisible()
    if optionsVisible or reviewVisible then
        self:RefreshOptions()
    end
end

function AS:ClearHistory()
    self.history = {}
    self:RefreshOptions()
end

function AS:FormatMatches(matches)
    if type(matches) ~= "table" or #matches == 0 then return "None" end
    return table.concat(matches, ", ")
end
