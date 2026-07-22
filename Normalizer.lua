local AS = AscensionSilencer

local UTF8_LOWER = {
    ["İ"] = "i", ["Ş"] = "ş", ["Ğ"] = "ğ", ["Ü"] = "ü", ["Ö"] = "ö", ["Ç"] = "ç",
    ["Č"] = "č", ["Ć"] = "ć", ["Š"] = "š", ["Ž"] = "ž", ["Đ"] = "đ",
    ["Ä"] = "ä", ["Ë"] = "ë", ["Ï"] = "ï", ["À"] = "à", ["Á"] = "á", ["Â"] = "â",
    ["Ã"] = "ã", ["É"] = "é", ["È"] = "è", ["Ê"] = "ê", ["Í"] = "í", ["Ì"] = "ì",
    ["Ó"] = "ó", ["Ò"] = "ò", ["Ô"] = "ô", ["Õ"] = "õ", ["Ú"] = "ú", ["Ù"] = "ù",
    ["Ñ"] = "ñ", ["Ț"] = "ț", ["Ţ"] = "ţ", ["Ș"] = "ș", ["Ă"] = "ă", ["Î"] = "î",
}

local function DecodeUTF8(text, position)
    local first = string.byte(text, position)
    if not first then return nil, position + 1 end

    if first < 0x80 then return first, position + 1 end

    local second = string.byte(text, position + 1)
    if first < 0xE0 and second then
        return (first - 0xC0) * 0x40 + (second - 0x80), position + 2
    end

    local third = string.byte(text, position + 2)
    if first < 0xF0 and second and third then
        return (first - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80), position + 3
    end

    local fourth = string.byte(text, position + 3)
    if second and third and fourth then
        return (first - 0xF0) * 0x40000 + (second - 0x80) * 0x1000 + (third - 0x80) * 0x40 + (fourth - 0x80), position + 4
    end

    return first, position + 1
end

local function LowerUTF8(text)
    text = string.lower(tostring(text or ""))
    if not string.find(text, "[\128-\255]") then return text end

    local output = {}
    local position = 1
    local length = string.len(text)

    while position <= length do
        local _, nextPosition = DecodeUTF8(text, position)
        if not nextPosition or nextPosition <= position then nextPosition = position + 1 end
        local char = string.sub(text, position, nextPosition - 1)
        output[#output + 1] = UTF8_LOWER[char] or char
        position = nextPosition
    end

    return table.concat(output)
end

local function ClassifyCodepoint(codepoint)
    if (codepoint >= 0x41 and codepoint <= 0x5A) or (codepoint >= 0x61 and codepoint <= 0x7A) then
        return "latin"
    elseif codepoint >= 0x00C0 and codepoint <= 0x024F then
        return "latin"
    elseif codepoint >= 0x0370 and codepoint <= 0x03FF then
        return "greek"
    elseif codepoint >= 0x0400 and codepoint <= 0x052F then
        return "cyrillic"
    elseif codepoint >= 0x0590 and codepoint <= 0x05FF then
        return "hebrew"
    elseif (codepoint >= 0x0600 and codepoint <= 0x06FF) or (codepoint >= 0x0750 and codepoint <= 0x077F) or (codepoint >= 0x08A0 and codepoint <= 0x08FF) then
        return "arabic"
    elseif codepoint >= 0x0900 and codepoint <= 0x0DFF then
        return "indic"
    elseif codepoint >= 0x0E00 and codepoint <= 0x0E7F then
        return "thai"
    elseif codepoint >= 0x3040 and codepoint <= 0x309F then
        return "hiragana"
    elseif codepoint >= 0x30A0 and codepoint <= 0x30FF then
        return "katakana"
    elseif (codepoint >= 0x3400 and codepoint <= 0x4DBF) or (codepoint >= 0x4E00 and codepoint <= 0x9FFF) then
        return "cjk"
    elseif (codepoint >= 0x1100 and codepoint <= 0x11FF) or (codepoint >= 0xAC00 and codepoint <= 0xD7AF) then
        return "hangul"
    end

    return nil
end

function AS:EnsureScriptAnalysis(context)
    if context.scripts then return context.scripts, context.totalLetters or 0 end

    local scripts = {
        latin = 0,
        greek = 0,
        cyrillic = 0,
        hebrew = 0,
        arabic = 0,
        indic = 0,
        thai = 0,
        hiragana = 0,
        katakana = 0,
        cjk = 0,
        hangul = 0,
    }
    local nonAsciiChars = {}
    local totalLetters = 0
    local text = context.searchText or ""
    local position = 1
    local length = string.len(text)

    while position <= length do
        local startPosition = position
        local codepoint
        codepoint, position = DecodeUTF8(text, position)
        if codepoint then
            if codepoint >= 0x80 then
                nonAsciiChars[string.sub(text, startPosition, position - 1)] = true
            end

            local script = ClassifyCodepoint(codepoint)
            if script then
                scripts[script] = scripts[script] + 1
                totalLetters = totalLetters + 1
            end
        end
    end

    context.scripts = scripts
    context.totalLetters = totalLetters
    context.nonAsciiChars = nonAsciiChars
    return scripts, totalLetters
end

function AS:NormalizeMessage(message)
    local original = tostring(message or "")
    local searchText = string.gsub(original, "|c%x%x%x%x%x%x%x%x", "")
    searchText = string.gsub(searchText, "|r", "")
    searchText = string.gsub(searchText, "|H.-|h(.-)|h", " %1 ")
    searchText = string.gsub(searchText, "|T.-|t", " ")
    searchText = string.gsub(searchText, "{.-}", " ")
    searchText = LowerUTF8(searchText)
    searchText = string.gsub(searchText, "%s+", " ")

    local tokenText = string.gsub(searchText, "[%c%p]+", " ")
    tokenText = string.gsub(tokenText, "%s+", " ")
    tokenText = self:Trim(tokenText)

    local tokens = {}
    local tokenSet = {}
    for token in string.gmatch(tokenText, "%S+") do
        tokens[#tokens + 1] = token
        tokenSet[token] = true
    end

    return {
        original = original,
        searchText = searchText,
        text = tokenText,
        tokens = tokens,
        tokenSet = tokenSet,
        tokenCount = #tokens,
    }
end
