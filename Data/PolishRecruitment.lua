local AS = AscensionSilencer

local languages = AS.Data and AS.Data.languages
local Polish = languages and languages.Polish
if not Polish then return end

Polish.words = Polish.words or {}
Polish.phrases = Polish.phrases or {}

local words = {
    ["rekrutujemy"] = 5,
    ["rekrutuje"] = 4,
    ["rekrutacja"] = 4,
    ["guildia"] = 3,
    ["socjalna"] = 3,
    ["zaczyna"] = 2,
    ["nowa"] = 1,
    ["przygodę"] = 3,
    ["przygode"] = 3,
    ["twoje"] = 1,
    ["drugie"] = 1,
    ["imię"] = 2,
    ["imie"] = 2,
    ["genialnie"] = 3,
    ["idealne"] = 3,
    ["system"] = 1,
    ["ziemniaczki"] = 2,
}

for word, weight in pairs(words) do
    if (tonumber(Polish.words[word]) or 0) < weight then
        Polish.words[word] = weight
    end
end

local phrases = {
    { "rekrutujemy guildia", 7 },
    { "rekrutujemy gildia", 7 },
    { "guildia gurom polska", 6 },
    { "zaczyna nowa przygodę", 5 },
    { "zaczyna nowa przygode", 5 },
    { "socjalna guildia", 6 },
    { "socjalna gildia", 6 },
    { "dla ciebie", 3 },
    { "twoje drugie imię", 4 },
    { "twoje drugie imie", 4 },
    { "idealne miejsce", 5 },
    { "system dkp", 3 },
}

for _, phrase in ipairs(phrases) do
    Polish.phrases[#Polish.phrases + 1] = phrase
end
