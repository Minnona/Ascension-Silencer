local ADDON_NAME = ...

local AS = CreateFrame("Frame")
_G.AscensionSilencer = AS

AS.addonName = ADDON_NAME or "AscensionSilencer"
AS.displayName = "Ascension Silencer"
AS.version = "0.2.3"
AS.schemaVersion = 2
AS.modules = {}
AS.moduleOrder = {}
AS.ready = false
AS.chatFiltersRegistered = false
AS.cache = {
    friends = {},
    guild = {},
    group = {},
}
AS.sessionStats = {
    total = 0,
    byModule = {},
}

function AS:Print(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff6fdcffAscension Silencer:|r " .. tostring(message))
    end
end

function AS:Trim(text)
    text = tostring(text or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function AS:CanonicalName(name)
    name = self:Trim(name)
    name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
    name = string.gsub(name, "|r", "")
    name = string.match(name, "^([^%-]+)") or name
    return string.lower(name)
end

function AS:RegisterModule(key, module)
    if not key or type(module) ~= "table" or self.modules[key] then return end
    module.key = key
    self.modules[key] = module
    table.insert(self.moduleOrder, key)
end

function AS:GetModuleDB(key)
    if not self.db then return nil end
    self.db.filters = self.db.filters or {}
    self.db.filters[key] = self.db.filters[key] or {}
    return self.db.filters[key]
end

function AS:IsModuleEnabled(key)
    local moduleDB = self:GetModuleDB(key)
    return moduleDB and moduleDB.enabled and true or false
end

function AS:SetModuleEnabled(key, enabled)
    local moduleDB = self:GetModuleDB(key)
    if not moduleDB then return end
    moduleDB.enabled = enabled and true or false
    self:RefreshOptions()
end

function AS:SetMasterEnabled(enabled)
    if not self.db then return end
    self.db.enabled = enabled and true or false
    self:RefreshOptions()
end

function AS:RefreshFriendCache()
    self.cache.friends = {}
    if not GetNumFriends or not GetFriendInfo then return end

    for index = 1, (GetNumFriends() or 0) do
        local name = GetFriendInfo(index)
        if name then
            self.cache.friends[self:CanonicalName(name)] = true
        end
    end
end

function AS:RefreshGuildCache()
    self.cache.guild = {}
    if not IsInGuild or not IsInGuild() then return end
    if GuildRoster then pcall(GuildRoster) end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return end

    local count = GetNumGuildMembers(true) or 0
    for index = 1, count do
        local name = GetGuildRosterInfo(index)
        if name then
            self.cache.guild[self:CanonicalName(name)] = true
        end
    end
end

function AS:RefreshGroupCache()
    self.cache.group = {}

    local function AddUnit(unit)
        if UnitExists and UnitExists(unit) and UnitName then
            local name = UnitName(unit)
            if name then
                AS.cache.group[AS:CanonicalName(name)] = true
            end
        end
    end

    if GetNumRaidMembers and (GetNumRaidMembers() or 0) > 0 then
        for index = 1, GetNumRaidMembers() do
            AddUnit("raid" .. index)
        end
    elseif GetNumPartyMembers then
        for index = 1, (GetNumPartyMembers() or 0) do
            AddUnit("party" .. index)
        end
    end
end

function AS:RefreshSocialCaches()
    self:RefreshFriendCache()
    self:RefreshGuildCache()
    self:RefreshGroupCache()
end

function AS:IsChannelEnabled(event)
    if not self.db or not self.db.enabled then return false end
    local channels = self.db.channels or {}

    if event == "CHAT_MSG_CHANNEL" then
        return channels.public ~= false
    elseif event == "CHAT_MSG_SAY" then
        return channels.say and true or false
    elseif event == "CHAT_MSG_YELL" then
        return channels.yell and true or false
    end

    return false
end

function AS:IsSenderExcepted(sender, message)
    if not self.db then return false end
    local exceptions = self.db.exceptions or {}
    local senderKey = self:CanonicalName(sender)

    if exceptions.allowSelf ~= false and UnitName then
        local playerName = UnitName("player")
        if playerName and senderKey == self:CanonicalName(playerName) then
            return true, "own message"
        end
    end

    if exceptions.allowFriends ~= false and self.cache.friends[senderKey] then
        return true, "friend"
    end

    if exceptions.allowGuild ~= false and self.cache.guild[senderKey] then
        return true, "guild member"
    end

    if exceptions.allowGroup ~= false and self.cache.group[senderKey] then
        return true, "group member"
    end

    local players = exceptions.players or {}
    for _, name in ipairs(players) do
        if senderKey == self:CanonicalName(name) then
            return true, "player whitelist"
        end
    end

    local lowerMessage = string.lower(tostring(message or ""))
    local phrases = exceptions.phrases or {}
    for _, phrase in ipairs(phrases) do
        phrase = string.lower(self:Trim(phrase))
        if phrase ~= "" and string.find(lowerMessage, phrase, 1, true) then
            return true, "phrase whitelist"
        end
    end

    return false
end

function AS:GetChannelLabel(event, ...)
    if event == "CHAT_MSG_SAY" then return "Say" end
    if event == "CHAT_MSG_YELL" then return "Yell" end

    local channelString = select(2, ...)
    if channelString and channelString ~= "" then
        return tostring(channelString)
    end

    return "Public channel"
end

function AS:ChatFilter(frame, event, message, sender, ...)
    if not self.ready or not self:IsChannelEnabled(event) then
        return false
    end

    local blocked = self:EvaluateChatMessage(message, sender, event, ...)
    if blocked then
        return true
    end

    return false
end

function AS:RegisterChatFilters()
    if self.chatFiltersRegistered or not ChatFrame_AddMessageEventFilter then return end

    self.chatFilter = self.chatFilter or function(...)
        return AS:ChatFilter(...)
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", self.chatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", self.chatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", self.chatFilter)
    self.chatFiltersRegistered = true
end

function AS:Initialize()
    if self.ready then return end

    self:InitDatabase()
    self:RefreshSocialCaches()
    self:RegisterChatFilters()
    self:BuildOptions()
    self.ready = true
end

AS:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == self.addonName then
            self:Initialize()
        elseif loadedAddon == "ElvUI" and self.ready and self.ApplyOptionsSkin then
            self:ApplyOptionsSkin()
        end
    elseif event == "PLAYER_LOGIN" then
        self:RefreshSocialCaches()
        if self.ApplyOptionsSkin then self:ApplyOptionsSkin() end
    elseif event == "FRIENDLIST_UPDATE" then
        self:RefreshFriendCache()
    elseif event == "GUILD_ROSTER_UPDATE" then
        self:RefreshGuildCache()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        self:RefreshGroupCache()
    end
end)

AS:RegisterEvent("ADDON_LOADED")
AS:RegisterEvent("PLAYER_LOGIN")
AS:RegisterEvent("FRIENDLIST_UPDATE")
AS:RegisterEvent("GUILD_ROSTER_UPDATE")
AS:RegisterEvent("RAID_ROSTER_UPDATE")
AS:RegisterEvent("PARTY_MEMBERS_CHANGED")
pcall(AS.RegisterEvent, AS, "GROUP_ROSTER_UPDATE")

SLASH_ASCENSIONSILENCER1 = "/as"
SlashCmdList["ASCENSIONSILENCER"] = function()
    if AS.OpenOptions then
        AS:OpenOptions()
    end
end
