local AS = AscensionSilencer

AS.version = "0.3.2"
AS.schemaVersion = 2
AS.hygieneHistory = AS.hygieneHistory or {}
AS.hygieneMessageCounter = 0

local MODULE_KEY = "ChannelHygiene"
local MODULE_NAME = "Channel hygiene"
local MAX_SENDERS = 500
local MAX_SIGNATURES_PER_SENDER = 25
local GLOBAL_PRUNE_INTERVAL = 100

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

local function GetMaximumAge(settings)
    return math.max(
        tonumber(settings.repeatCooldown) or 60,
        tonumber(settings.lfgCooldown) or 30,
        tonumber(settings.duplicateWindow) or 12
    ) + 30
end

local function PruneSenderSignatures(senderRecord, now, maxAge)
    local signatures = senderRecord.signatures or {}
    senderRecord.signatures = signatures
    local count = 0

    for signature, entry in pairs(signatures) do
        if not entry.time or (now - entry.time) > maxAge then
            signatures[signature] = nil
        else
            count = count + 1
        end
    end

    while count > MAX_SIGNATURES_PER_SENDER do
        local oldestSignature = nil
        local oldestTime = nil
        for signature, entry in pairs(signatures) do
            local entryTime = tonumber(entry.time) or 0
            if not oldestTime or entryTime < oldestTime then
                oldestSignature = signature
                oldestTime = entryTime
            end
        end
        if not oldestSignature then break end
        signatures[oldestSignature] = nil
        count = count - 1
    end

    return count
end

function AS:PruneHygieneHistory(now, settings)
    local maxAge = GetMaximumAge(settings)
    local activeSenders = {}

    for senderKey, senderRecord in pairs(self.hygieneHistory) do
        local signatureCount = PruneSenderSignatures(senderRecord, now, maxAge)
        local lastSeen = tonumber(senderRecord.lastSeen) or 0
        if signatureCount == 0 and (now - lastSeen) > maxAge then
            self.hygieneHistory[senderKey] = nil
        else
            activeSenders[#activeSenders + 1] = { senderKey, lastSeen }
        end
    end

    local excess = #activeSenders - MAX_SENDERS
    if excess <= 0 then return end

    table.sort(activeSenders, function(left, right)
        return left[2] < right[2]
    end)

    for index = 1, excess do
        self.hygieneHistory[activeSenders[index][1]] = nil
    end
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

    local naturalToken = nil
    for token in pairs(NATURAL_COMMERCIAL_TOKENS) do
        if tokenSet[token] then
            naturalToken = token
            break
        end
    end

    local hasItemLink = string.find(context.original or "", "|Hitem:", 1, true) ~= nil
    local hasContact = tokenSet.pst or tokenSet.whisper or tokenSet.pm or tokenSet.offer
    if not hasItemLink and not naturalToken and not hasContact then return false end

    local hasPrice = string.find(text .. " ", "%d+%s*[gsc]%s")
        or string.find(text .. " ", "%d+%s*[kmg]%s*g%s")
        or string.find(text, "%d+%s*[:/]%s*%d+")

    if hasItemLink and hasPrice then return true, "item and price" end
    if naturalToken and (hasItemLink or hasPrice or hasContact) then return true, naturalToken end

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
    if string.len(signature) < 8 or (context.tokenCount or 0) < 2 then return nil end
    return signature
end

function AS:EvaluateChannelHygiene(context)
    if context.event ~= "CHAT_MSG_CHANNEL" then return nil end

    local settings = self.db and self.db.hygiene
    if not settings or settings.enabled == false then return nil end

    local now = GetTime and GetTime() or 0
    self.hygieneMessageCounter = (self.hygieneMessageCounter or 0) + 1
    if self.hygieneMessageCounter >= GLOBAL_PRUNE_INTERVAL then
        self.hygieneMessageCounter = 0
        self:PruneHygieneHistory(now, settings)
    end

    local isTrade = self:IsTradeChannel(context, settings)
    local isCommercial, commercialMatch = self:IsCommercialMessage(context)

    if settings.routeCommercial ~= false and isCommercial and not isTrade then
        return MakeResult("Commercial post outside Trade", { commercialMatch or "commercial content" })
    end

    if settings.keepTradeClean ~= false and isTrade and not isCommercial then
        return MakeResult("Non-trade content posted in Trade", { "Trade channel routing" })
    end

    local signature = self:GetHygieneSignature(context)
    if not signature then return nil end

    local senderKey = context.senderKey or self:CanonicalName(context.sender or "Unknown")
    local senderRecord = self.hygieneHistory[senderKey]
    if not senderRecord then
        senderRecord = { lastSeen = now, signatures = {} }
        self.hygieneHistory[senderKey] = senderRecord
    end

    senderRecord.lastSeen = now
    PruneSenderSignatures(senderRecord, now, GetMaximumAge(settings))

    local previous = senderRecord.signatures[signature]
    if previous then
        local elapsed = math.max(0, now - (previous.time or 0))
        local duplicateWindow = tonumber(settings.duplicateWindow) or 12

        if settings.suppressCrossChannel ~= false
            and previous.channel ~= context.channel
            and elapsed < duplicateWindow then
            return MakeResult("Duplicate of message in " .. tostring(previous.channel or "another channel"), {
                "cross-channel duplicate",
            })
        end

        if settings.throttleRepeats ~= false then
            local cooldown = self:IsLFGMessage(context)
                and (tonumber(settings.lfgCooldown) or 30)
                or (tonumber(settings.repeatCooldown) or 60)

            if elapsed < cooldown then
                local remaining = math.max(1, math.ceil(cooldown - elapsed))
                return MakeResult("Repeated message throttled (" .. remaining .. "s remaining)", {
                    "repeat cooldown",
                })
            end
        end
    end

    senderRecord.signatures[signature] = {
        time = now,
        channel = context.channel,
        trade = isTrade and true or false,
    }

    return nil
end
