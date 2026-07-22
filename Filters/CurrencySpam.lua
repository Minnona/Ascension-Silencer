local AS = AscensionSilencer

local module = {
    name = "DP and Bazaar trading",
    description = "Blocks buying and selling spam involving Donation Points and Bazaar Tokens.",
    baseThreshold = 6,
    priority = 40,
    defaults = {
        enabled = true,
        sensitivity = 2,
    },
}

local function AddMatch(matches, label)
    for _, existing in ipairs(matches) do
        if existing == label then return end
    end
    table.insert(matches, label)
end

local function HasToken(context, values)
    for _, value in ipairs(values) do
        if context.tokenSet[value] then return value end
    end
    return nil
end

local function HasAny(text, values)
    for _, value in ipairs(values) do
        if string.find(text, value, 1, true) then return value end
    end
    return nil
end

function module:Evaluate(context)
    local text = context.searchText
    local score = 0
    local matches = {}

    local transaction = HasToken(context, { "wts", "wtb", "wtt", "buying", "selling", "sell", "buy", "trade", "trading" })
    if not transaction then
        transaction = HasAny(text, { "want to sell", "want to buy", "for sale", "paying gold", "selling for gold", "buying for gold" })
    end
    if transaction then
        score = score + 4
        AddMatch(matches, transaction)
    end

    local hasDP = context.tokenSet.dp
        or string.find(text, "donation point", 1, true)
        or string.find(text, "%d+%s*dp")

    local hasBazaar = string.find(text, "bazaar token", 1, true)
        or string.find(text, "bazar token", 1, true)
        or string.find(text, "baz token", 1, true)
        or string.find(text, "%d+%s*bazaar")
        or string.find(text, "%d+%s*bazar")
        or (transaction and string.find(text, "%d+%s*baz[%s%p]"))
        or (transaction and (context.tokenSet.bazaar or context.tokenSet.bazar))
        or (transaction and context.tokenSet.baz and (context.tokenSet.token or context.tokenSet.tokens))

    if hasDP then
        score = score + 4
        AddMatch(matches, "Donation Points")
    end

    if hasBazaar then
        score = score + 4
        AddMatch(matches, "Bazaar Tokens")
    end

    local rate = HasAny(text, { "good rate", "best rate", "cheap rate", "rate is", "per dp", "per token", "each dp", "each token" })
    if rate or string.find(text, "%d+%s*[:/]%s*%d+") then
        score = score + 2
        AddMatch(matches, rate or "exchange rate")
    end

    if string.find(text, "%d+%s*[kmg]?%s*g[%s%p]") or string.find(text .. " ", "%d+%s*[kmg]?%s*g%s") then
        score = score + 1
        AddMatch(matches, "gold amount")
    end

    local contact = HasAny(text, { "whisper me", "pst", "pm me", "dm me", "fast trade", "safe trade" })
    if contact then
        score = score + 1
        AddMatch(matches, contact)
    end

    if string.find(text, "?", 1, true) and not transaction then
        score = score - 2
    end

    return {
        score = math.max(0, score),
        reason = "DP or Bazaar Token trading advertisement",
        matches = matches,
    }
end

AS:RegisterModule("CurrencySpam", module)
