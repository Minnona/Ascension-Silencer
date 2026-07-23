local AS = AscensionSilencer

AS.Data = AS.Data or {}
AS.Data.languages = AS.Data.languages or {}

local Dutch = AS.Data.languages.Dutch
if not Dutch then
    Dutch = {
        label = "Dutch / Flemish",
        words = {},
        phrases = {},
        chars = {},
    }
    AS.Data.languages.Dutch = Dutch
end

Dutch.words = Dutch.words or {}
Dutch.phrases = Dutch.phrases or {}

local words = {
    ["welkom"] = 3,
    ["nederlands"] = 4,
    ["nederlandse"] = 4,
    ["belgisch"] = 4,
    ["belgische"] = 4,
    ["gilde"] = 3,
    ["ook"] = 1,
    ["wel"] = 1,
    ["bekend"] = 2,
    ["maakt"] = 2,
    ["hier"] = 1,
    ["tweede"] = 2,
    ["thuis"] = 3,
    ["lekker"] = 2,
    ["levelen"] = 3,
    ["zijn"] = 1,
    ["bezig"] = 2,
    ["elke"] = 1,
    ["woensdag"] = 3,
    ["schuif"] = 3,
    ["aan"] = 1,
    ["drink"] = 2,
    ["biertje"] = 3,
    ["ons"] = 1,
}

for word, weight in pairs(words) do
    if (tonumber(Dutch.words[word]) or 0) < weight then
        Dutch.words[word] = weight
    end
end

local phrases = {
    { "welkom in de", 4 },
    { "nederlands belgische guild", 8 },
    { "nederlandse belgische guild", 8 },
    { "nederlands belgische gilde", 8 },
    { "nederlandse belgische gilde", 8 },
    { "een tweede thuis", 6 },
    { "lekker levelen", 5 },
    { "bezig met world bosses", 5 },
    { "elke woensdag", 4 },
    { "schuif aan", 5 },
    { "drink een biertje met ons", 6 },
}

for _, phrase in ipairs(phrases) do
    Dutch.phrases[#Dutch.phrases + 1] = phrase
end
