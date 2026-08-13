local AS = AscensionSilencer

local module = {
    name = "Non-English text",
    description = "Blocks clear non-English messages using weighted vocabulary, language density and script evidence.",
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

local MAX_WORD_SCORE = 12
local MAX_PHRASE_BONUS = 4
local MAX_MATCH_DETAILS = 6

local languageNames = nil
local tokenIndex = nil
local tokenLanguageCounts = nil
local phraseIndex = nil
local charIndex = nil

local function AddMatch(matches, label)
    if not label or label == "" then return end
    for _, existing in ipairs(matches) do
        if existing == label then return end
    end
    if #matches < MAX_MATCH_DETAILS then
        matches[#matches + 1] = label
    end
end

local function PrepareIndexes(addon)
    if tokenIndex then return end

    languageNames = {}
    tokenIndex = {}
    tokenLanguageCounts = {}
    phraseIndex = {}
    charIndex = {}

    for languageName, language in pairs(addon.Data.languages or {}) do
        languageNames[#languageNames + 1] = languageName

        for token, weight in pairs(language.words or {}) do
            local entries = tokenIndex[token]
            if not entries then
                entries = {}
                tokenIndex[token] = entries
            end
            entries[#entries + 1] = { languageName, tonumber(weight) or 1 }
            tokenLanguageCounts[token] = (tokenLanguageCounts[token] or 0) + 1
        end

        for _, phrase in ipairs(language.phrases or {}) do
            local phraseText = phrase[1] or ""
            local firstToken = string.match(phraseText, "^(%S+)")
            if firstToken then
                local entries = phraseIndex[firstToken]
                if not entries then
                    entries = {}
                    phraseIndex[firstToken] = entries
                end
                entries[#entries + 1] = { languageName, phraseText, tonumber(phrase[2]) or 1 }
            end
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

    table.sort(languageNames)
end

local function IsMeaningfulToken(token, wowTerms)
    if not token or token == "" or wowTerms[token] then return false end
    if string.len(token) <= 1 then return false end
    if string.match(token, "^%d+$") then return false end
    return true
end

local function AdjustTokenWeight(weight, languageCount)
    weight = math.max(0.5, math.min(4, tonumber(weight) or 1))
    languageCount = tonumber(languageCount) or 1

    -- Common words shared by several supported languages are weak evidence by
    -- themselves. Distinctive words keep their configured weight.
    if languageCount >= 3 and weight <= 2 then
        return 0.5
    elseif languageCount == 2 and weight <= 1 then
        return 0.5
    end

    return weight
end

local function GetDensityBonus(distinctMatches, density)
    if distinctMatches >= 5 and density >= 0.50 then return 3 end
    if distinctMatches >= 4 and density >= 0.35 then return 2 end
    if distinctMatches >= 3 and density >= 0.20 then return 1 end
    return 0
end

local function GetDiversityBonus(distinctMatches)
    if distinctMatches >= 6 then return 3 end
    if distinctMatches >= 4 then return 2 end
    if distinctMatches >= 3 then return 1 end
    return 0
end

local function GetEnglishPenalty(englishCount, meaningfulTokenCount, distinctMatches)
    if meaningfulTokenCount <= 0 or englishCount <= 0 then return 0 end

    local density = englishCount / meaningfulTokenCount
    if englishCount >= 4 and density >= 0.50 and distinctMatches <= 3 then
        return 3
    elseif englishCount >= 3 and density >= 0.35 then
        return 2
    elseif englishCount >= 2 and density >= 0.25 then
        return 1
    end

    return 0
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

    local wowTerms = addon.Data.wowTerms or {}
    local englishWords = addon.Data.englishWords or {}
    local meaningfulTokenCount = 0
    local englishCount = 0

    local wordScores = {}
    local matchedOccurrences = {}
    local distinctMatches = {}
    local matchedTokens = {}
    local phraseScores = {}
    local phraseMatches = {}
    local charHits = {}

    for _, token in ipairs(context.tokens) do
        if IsMeaningfulToken(token, wowTerms) then
            meaningfulTokenCount = meaningfulTokenCount + 1
            if englishWords[token] then englishCount = englishCount + 1 end

            local entries = tokenIndex[token]
            if entries then
                for _, entry in ipairs(entries) do
                    local languageName = entry[1]
                    matchedOccurrences[languageName] = (matchedOccurrences[languageName] or 0) + 1

                    local seen = matchedTokens[languageName]
                    if not seen then
                        seen = {}
                        matchedTokens[languageName] = seen
                    end

                    if not seen[token] then
                        seen[token] = true
                        local adjustedWeight = AdjustTokenWeight(entry[2], tokenLanguageCounts[token])
                        wordScores[languageName] = (wordScores[languageName] or 0) + adjustedWeight
                        distinctMatches[languageName] = (distinctMatches[languageName] or 0) + 1
                    end
                end
            end
        end
    end

    -- Phrases are supporting evidence only. Keep the strongest phrase for each
    -- language instead of allowing a long known advertisement to stack many
    -- phrase bonuses and become the detection mechanism by itself.
    for token in pairs(context.tokenSet) do
        local entries = phraseIndex[token]
        if entries then
            for _, entry in ipairs(entries) do
                if string.find(context.searchText, entry[2], 1, true) then
                    local languageName = entry[1]
                    local weight = tonumber(entry[3]) or 1
                    if weight > (phraseScores[languageName] or 0) then
                        phraseScores[languageName] = weight
                        phraseMatches[languageName] = entry[2]
                    end
                end
            end
        end
    end

    for char in pairs(context.nonAsciiChars or {}) do
        local languages = charIndex[char]
        if languages then
            for _, languageName in ipairs(languages) do
                charHits[languageName] = (charHits[languageName] or 0) + 1
            end
        end
    end

    local bestLanguage = nil
    local bestLanguageScore = 0
    local bestLanguageMatches = nil

    for _, languageName in ipairs(languageNames) do
        local language = addon.Data.languages[languageName]
        local wordScore = math.min(MAX_WORD_SCORE, wordScores[languageName] or 0)
        local distinct = distinctMatches[languageName] or 0
        local occurrences = matchedOccurrences[languageName] or 0
        local density = meaningfulTokenCount > 0 and (occurrences / meaningfulTokenCount) or 0
        local phraseBonus = math.min(MAX_PHRASE_BONUS, phraseScores[languageName] or 0)
        local diversityBonus = GetDiversityBonus(distinct)
        local densityBonus = GetDensityBonus(distinct, density)
        local englishPenalty = GetEnglishPenalty(englishCount, meaningfulTokenCount, distinct)
        local languageCharHits = charHits[languageName] or 0
        local charBonus = 0

        if distinct >= 1 then
            charBonus = math.min(2, languageCharHits)
        elseif meaningfulTokenCount >= 3 and languageCharHits >= 2 then
            -- Character evidence alone is deliberately too weak to block Latin
            -- text, but it can break ties when vocabulary coverage is sparse.
            charBonus = 1
        end

        local languageScore = wordScore + phraseBonus + diversityBonus + densityBonus + charBonus - englishPenalty

        -- One-word messages and isolated vocabulary remain safe at Balanced.
        if meaningfulTokenCount <= 1 and distinct <= 1 then
            languageScore = math.min(languageScore, 3)
        elseif meaningfulTokenCount <= 2 and distinct <= 1 and phraseBonus == 0 then
            languageScore = math.min(languageScore, 3)
        end

        if languageScore > bestLanguageScore then
            bestLanguage = language.label or languageName
            bestLanguageScore = languageScore

            local details = {}
            local tokenDetails = matchedTokens[languageName]
            if tokenDetails then
                for token in pairs(tokenDetails) do
                    AddMatch(details, token)
                end
            end
            if phraseMatches[languageName] then AddMatch(details, phraseMatches[languageName]) end
            if distinct >= 3 then AddMatch(details, tostring(distinct) .. " vocabulary hits") end
            if densityBonus > 0 then
                AddMatch(details, tostring(math.floor(density * 100 + 0.5)) .. "% language coverage")
            end
            bestLanguageMatches = details
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
