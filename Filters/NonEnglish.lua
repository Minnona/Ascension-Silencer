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

local languageNames = nil
local tokenIndex = nil
local phraseEntries = nil
local charIndex = nil

local function AddMatch(matches, label)
    for _, existing in ipairs(matches) do
        if existing == label then return end
    end
    matches[#matches + 1] = label
end

local function AddLanguageMatch(allMatches, languageName, label)
    local matches = allMatches[languageName]
    if not matches then
        matches = {}
        allMatches[languageName] = matches
    end
    AddMatch(matches, label)
end

local function PrepareIndexes(addon)
    if tokenIndex then return end

    languageNames = {}
    tokenIndex = {}
    phraseEntries = {}
    charIndex = {}

    for languageName, language in pairs(addon.Data.languages or {}) do
        languageNames[#languageNames + 1] = languageName

        for token, weight in pairs(language.words or {}) do
            local entries = tokenIndex[token]
            if not entries then
                entries = {}
                tokenIndex[token] = entries
            end
            entries[#entries + 1] = { languageName, weight }
        end

        for _, phrase in ipairs(language.phrases or {}) do
            phraseEntries[#phraseEntries + 1] = {
                languageName,
                phrase[1],
                phrase[2] or 1,
            }
        end

        for _, char in ipairs(language.chars or {}) do
            local languages = charIndex[char]
            if not languages then
                languages = {}
                charIndex[char] = languages
            end
            languages[#languages + 1] = languageName
        end
    end
end

local function CountEnglish(context, englishWords)
    local count = 0
    for _, token in ipairs(context.tokens) do
        if englishWords[token] then count = count + 1 end
    end
    return count
end

function module:Evaluate(context, moduleDB, addon)
    PrepareIndexes(addon)

    local scripts, totalLetterCount = addon:EnsureScriptAnalysis(context)
    local totalLetters = math.max(1, totalLetterCount or 0)
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

    local languageScores = {}
    local languageMatches = {}
    local matchedWords = {}
    local charHits = {}
    local wowTerms = addon.Data.wowTerms or {}
    local englishWords = addon.Data.englishWords or {}
    local englishCount = CountEnglish(context, englishWords)

    for _, token in ipairs(context.tokens) do
        if not wowTerms[token] then
            local entries = tokenIndex[token]
            if entries then
                for _, entry in ipairs(entries) do
                    local languageName = entry[1]
                    languageScores[languageName] = (languageScores[languageName] or 0) + (entry[2] or 1)
                    matchedWords[languageName] = (matchedWords[languageName] or 0) + 1
                    AddLanguageMatch(languageMatches, languageName, token)
                end
            end
        end
    end

    for _, entry in ipairs(phraseEntries) do
        if string.find(context.searchText, entry[2], 1, true) then
            local languageName = entry[1]
            languageScores[languageName] = (languageScores[languageName] or 0) + entry[3]
            AddLanguageMatch(languageMatches, languageName, entry[2])
        end
    end

    if string.find(context.searchText, "[\128-\255]") then
        for char, languages in pairs(charIndex) do
            if string.find(context.searchText, char, 1, true) then
                for _, languageName in ipairs(languages) do
                    charHits[languageName] = (charHits[languageName] or 0) + 1
                end
            end
        end
    end

    local bestLanguage = nil
    local bestLanguageScore = 0
    local bestLanguageMatches = nil

    for _, languageName in ipairs(languageNames) do
        local language = addon.Data.languages[languageName]
        local languageScore = languageScores[languageName] or 0
        local languageMatchedWords = matchedWords[languageName] or 0
        local languageCharHits = charHits[languageName] or 0

        if languageCharHits > 0 then
            languageScore = languageScore + math.min(2, languageCharHits)
        end

        if context.tokenCount <= 1 and languageMatchedWords <= 1 then
            languageScore = math.min(languageScore, 3)
        elseif languageMatchedWords >= 3 then
            languageScore = languageScore + 1
        end

        if englishCount >= 3 then
            languageScore = languageScore - 2
        elseif englishCount >= 1 then
            languageScore = languageScore - 1
        end

        if languageScore > bestLanguageScore then
            bestLanguage = language.label or languageName
            bestLanguageScore = languageScore
            bestLanguageMatches = languageMatches[languageName]
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
