local AS = AscensionSilencer

local languages = AS.Data and AS.Data.languages
local Portuguese = languages and languages.Portuguese
if not Portuguese then return end

Portuguese.words = Portuguese.words or {}
Portuguese.phrases = Portuguese.phrases or {}

local words = {
    ["procura"] = 4,
    ["membros"] = 3,
    ["formar"] = 2,
    ["comunidade"] = 3,
    ["portuguesa"] = 4,
    ["português"] = 4,
    ["portugues"] = 4,
    ["servidor"] = 2,
}

for word, weight in pairs(words) do
    if (tonumber(Portuguese.words[word]) or 0) < weight then
        Portuguese.words[word] = weight
    end
end

local phrases = {
    { "guild pt procura membros", 7 },
    { "procura membros", 5 },
    { "formar a comunidade portuguesa", 7 },
    { "comunidade portuguesa", 6 },
    { "w para invite", 4 },
    { "para invite", 3 },
}

for _, phrase in ipairs(phrases) do
    Portuguese.phrases[#Portuguese.phrases + 1] = phrase
end
