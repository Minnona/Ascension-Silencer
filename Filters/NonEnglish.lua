local AS = AscensionSilencer

local module = {
    name = "Non-English text",
    description = "Blocks clear non-English messages, including Balkan and Turkish text, without punishing short mixed messages.",
    baseThreshold = 6,
    priority = 10,
    defaults = {
        enabled = true,
        sensitivity = 2,
    },
}

local SCRIPT_LABELS = {
    cyrillic = "Cyrillic",
    greek = "Greek",
    hebrew = "Hebrew",
    arabic = "Arabic",
    indic = "Indic",
    thai = "Thai",
    hiragana = "Japanese",
    katakana = "Japanese",
    cjk = "Chinese/Japanese",
    hangul = "Korean",
}

local function AddMatch(matches, label)
    for _, existing in ipairs(matches) do
        if existing == label then return end
    end
    table.insert(matches, label)
end

local function CountEnglish(context, englishWords)
    local count = 0
    for _, token in ipairs(context.tokens) do
        if englishWords[token] then count = count + 1 end
    end
    return count
end

function module:Evaluate(context, moduleDB, addon)
    local scripts = context.scripts or {}
    local totalLetters = math.max(1, context.totalLetters or 0)
    local bestScript = nil
    local bestScriptCount = 0

    for script, label in pairs(SCRIPT_LABELS) do
        local count = scripts[script] or 0
        if count > bestScriptCount then
            bestScript = label
            bestScriptCount = count
        end
    end

    local score = 0
    local matches = {}
    local reason = nil

    local eastAsian = (scripts.hiragana or 0) + (scripts.katakana or 0) + (scripts.cjk or 0) + (scripts.hangul or 0)
    if eastAsian >= 2 then
        score = 12
        reason = "Non-English script: " .. tostring(bestScript or "East Asian")
        AddMatch(matches, tostring(bestScript or "East Asian") .. " characters")
    elseif bestScriptCount >= 3 then
        local ratio = bestScriptCount / totalLetters
        if ratio >= 0.25 or bestScriptCount >= 6 then
            score = 10
            reason = "Non-English script: " .. tostring(bestScript)
            AddMatch(matches, tostring(bestScript) .. " characters")
        end
    end

    local bestLanguage = nil
    local bestLanguageScore = 0
    local bestLanguageMatches = nil
    local wowTerms = addon.Data.wowTerms or {}
    local englishWords = addon.Data.englishWords or {}

    for languageName, language in pairs(addon.Data.languages or {}) do
        local languageScore = 0
        local languageMatches = {}
        local matchedWords = 0

        for _, token in ipairs(context.tokens) do
            if not wowTerms[token] then
                local weight = language.words and language.words[token]
                if weight then
                    languageScore = languageScore + weight
                    matchedWords = matchedWords + 1
                    AddMatch(languageMatches, token)
                end
            end
        end

        for _, phrase in ipairs(language.phrases or {}) do
            if string.find(context.searchText, phrase[1], 1, true) then
                languageScore = languageScore + (phrase[2] or 1)
                AddMatch(languageMatches, phrase[1])
            end
        end

        local charHits = 0
        for _, char in ipairs(language.chars or {}) do
            if string.find(context.searchText, char, 1, true) then
                charHits = charHits + 1
            end
        end
        if charHits > 0 then
            languageScore = languageScore + math.min(2, charHits)
        end

        if context.tokenCount <= 1 and matchedWords <= 1 then
            languageScore = math.min(languageScore, 3)
        elseif matchedWords >= 3 then
            languageScore = languageScore + 1
        end

        local englishCount = CountEnglish(context, englishWords)
        if englishCount >= 3 then
            languageScore = languageScore - 2
        elseif englishCount >= 1 then
            languageScore = languageScore - 1
        end

        if languageScore > bestLanguageScore then
            bestLanguage = language.label or languageName
            bestLanguageScore = languageScore
            bestLanguageMatches = languageMatches
        end
    end

    if bestLanguageScore > score then
        score = bestLanguageScore
        reason = "Likely " .. tostring(bestLanguage) .. " text"
        matches = bestLanguageMatches or {}
    end

    return {
        score = math.max(0, score),
        reason = reason or "Likely non-English text",
        matches = matches,
    }
end

AS:RegisterModule("NonEnglish", module)
