local AS = AscensionSilencer

AS.version = "0.2.0"
AS.schemaVersion = 2
AS.hygieneHistory = AS.hygieneHistory or {}

local MODULE_KEY = "ChannelHygiene"
local MODULE_NAME = "Channel hygiene"

local STRONG_COMMERCIAL_TOKENS = {
    wts = true, wtb = true, wtt = true,
}

local NATURAL_COMMERCIAL_TOKENS = {
    sell = true, selling = true, sold = true,
    buy = true, buying = true,
}

local COMMERCIAL_PHRASES = {
    "want to sell", "want to buy", "for sale", "paying gold",
    "selling for", "buying for", "can craft", "crafting for tips",
    "looking for crafter", "looking for enchanter", "lf crafter", "lf enchanter",
    "offering crafting", "offering enchants", "crafting services", "enchanting services",
    "anyone selling", "anyone buying", "tips appreciated", "your mats", "my mats",
}

local LFG_PHRASES = {
    "looking for group", "looking for more", "forming group", "forming raid",
    "need tank", "need healer", "need dps", "need more", "group for",
}

local function ContainsAny(text, values)
    for _, value in ipairs(values) do
        if string.find(text, value, 1, true) then return value end
    end
    return nil
end

local function MakeResult(reason, matches)
    return {
        moduleKey = MODULE_KEY,
        moduleName = MODULE_NAME,
        score = 1,
        threshold = 1,
        priority = 100,
        blocked = true,
        reason = reason,
        matches = matches or {},
    }
end

function AS:IsTradeChannel(context, settings)
    local channelIndex = tonumber(context.channelIndex)
    if channelIndex and channelIndex == tonumber(settings.tradeChannel or 4) then
        return true
    end

    local channelName = context.channelBaseName
    if type(channelName) ~= "string" or channelName == "" then channelName = context.channel end
    channelName = string.lower(tostring(channelName or ""))
    return string.find(channelName, "trade", 1, true)
        or string.find(channelName, "commerce", 1, true)
        or string.find(channelName, "auction", 1, true)
end

function AS:IsCommercialMessage(context)
    local text = context.searchText or ""
    local tokenSet = context.tokenSet or {}

    for token in pairs(STRONG_COMMERCIAL_TOKENS) do
        if tokenSet[token] then return true, token end
    end

    local phrase = ContainsAny(text, COMMERCIAL_PHRASES)
    if phrase then return true, phrase end

    local hasItemLink = string.find(context.original or "", "|Hitem:", 1, true) ~= nil
    local hasPrice = string.find(text .. " ", "%d+%s*[gsc]%s")
        or string.find(text .. " ", "%d+%s*[kmg]%s*g%s")
        or string.find(text, "%d+%s*[:/]%s*%d+")
    local hasContact = tokenSet.pst or tokenSet.whisper or tokenSet.pm or tokenSet.offer

    if hasItemLink and hasPrice then
        return true, "item and price"
    end

    for token in pairs(NATURAL_COMMERCIAL_TOKENS) do
        if tokenSet[token] and (hasItemLink or hasPrice or hasContact) then
            return true, token
        end
    end

    if string.find(text, "^selling ") or string.find(text, "^buying ")
        or string.find(text, "^sell ") or string.find(text, "^buy ") then
        return true, "sale or purchase offer"
    end

    return false
end

function AS:IsLFGMessage(context)
    local tokenSet = context.tokenSet or {}
    if tokenSet.lfg or tokenSet.lfm then return true end
    return ContainsAny(context.searchText or "", LFG_PHRASES) and true or false
end

function AS:GetHygieneSignature(context)
    local signature = tostring(context.text or "")
    signature = string.gsub(signature, "%s+", " ")
    signature = self:Trim(signature)

    if string.len(signature) < 8 or (context.tokenCount or 0) < 2 then
        return nil
    end

    return signature
end

function AS:PruneHygieneHistory(senderHistory, now, settings)
    local maxAge = math.max(
        tonumber(settings.repeatCooldown) or 60,
        tonumber(settings.lfgCooldown) or 30,
        tonumber(settings.duplicateWindow) or 12
    ) + 30

    local count = 0
    for signature, entry in pairs(senderHistory) do
        if not entry.time or (now - entry.time) > maxAge then
            senderHistory[signature] = nil
        else
            count = count + 1
        end
    end

    if count <= 50 then return end

    while count > 50 do
        local oldestSignature = nil
        local oldestTime = nil
        for signature, entry in pairs(senderHistory) do
            local entryTime = tonumber(entry.time) or 0
            if not oldestTime or entryTime < oldestTime then
                oldestSignature = signature
                oldestTime = entryTime
            end
        end
        if not oldestSignature then break end
        senderHistory[oldestSignature] = nil
        count = count - 1
    end
end

function AS:EvaluateChannelHygiene(context)
    if context.event ~= "CHAT_MSG_CHANNEL" then return nil end

    local settings = self.db and self.db.hygiene
    if not settings or settings.enabled == false then return nil end

    local now = GetTime and GetTime() or 0
    local eventKey = tostring(context.sender) .. "\031" .. tostring(context.channel) .. "\031" .. tostring(context.original)
    if self.lastHygieneEventKey == eventKey and (now - (self.lastHygieneEventTime or 0)) < 0.25 then
        if self.lastHygieneEventResult == false then return nil end
        return self.lastHygieneEventResult
    end

    local function Finish(result)
        self.lastHygieneEventKey = eventKey
        self.lastHygieneEventTime = now
        self.lastHygieneEventResult = result or false
        return result
    end

    local isTrade = self:IsTradeChannel(context, settings)
    local isCommercial, commercialMatch = self:IsCommercialMessage(context)

    if settings.routeCommercial ~= false and isCommercial and not isTrade then
        return Finish(MakeResult("Commercial post outside Trade", { commercialMatch or "commercial content" }))
    end

    if settings.keepTradeClean ~= false and isTrade and not isCommercial then
        return Finish(MakeResult("Non-trade content posted in Trade", { "Trade channel routing" }))
    end

    local signature = self:GetHygieneSignature(context)
    if not signature then return Finish(nil) end

    local senderKey = self:CanonicalName(context.sender or "Unknown")
    self.hygieneHistory = self.hygieneHistory or {}
    local senderHistory = self.hygieneHistory[senderKey]
    if not senderHistory then
        senderHistory = {}
        self.hygieneHistory[senderKey] = senderHistory
    end

    self:PruneHygieneHistory(senderHistory, now, settings)

    local previous = senderHistory[signature]
    if previous then
        local elapsed = math.max(0, now - (previous.time or 0))
        local duplicateWindow = tonumber(settings.duplicateWindow) or 12

        if settings.suppressCrossChannel ~= false
            and previous.channel ~= context.channel
            and elapsed < duplicateWindow then
            return Finish(MakeResult("Duplicate of message in " .. tostring(previous.channel or "another channel"), {
                "cross-channel duplicate",
            }))
        end

        if settings.throttleRepeats ~= false then
            local cooldown = self:IsLFGMessage(context)
                and (tonumber(settings.lfgCooldown) or 30)
                or (tonumber(settings.repeatCooldown) or 60)

            if elapsed < cooldown then
                local remaining = math.max(1, math.ceil(cooldown - elapsed))
                return Finish(MakeResult("Repeated message throttled (" .. remaining .. "s remaining)", {
                    "repeat cooldown",
                }))
            end
        end
    end

    senderHistory[signature] = {
        time = now,
        channel = context.channel,
        trade = isTrade and true or false,
    }

    return Finish(nil)
end
