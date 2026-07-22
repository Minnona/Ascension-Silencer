local AS = AscensionSilencer

local languages = AS.Data and AS.Data.languages
local German = languages and languages.German
if not German then return end

German.words = German.words or {}
German.phrases = German.phrases or {}

local words = {
    ["deutsche"] = 3,
    ["deutscher"] = 3,
    ["raidgilde"] = 4,
    ["raidmember"] = 4,
    ["kommenden"] = 2,
    ["meldet"] = 3,
    ["euch"] = 1,
    ["bock"] = 2,
    ["entspanntes"] = 3,
    ["erfolgreiches"] = 3,
    ["raiden"] = 3,
    ["willkommen"] = 3,
    ["newcomer"] = 3,
    ["newcommer"] = 3,
}

for word, weight in pairs(words) do
    if (tonumber(German.words[word]) or 0) < weight then
        German.words[word] = weight
    end
end

local phrases = {
    { "deutsche raidgilde", 6 },
    { "raidgilde sucht", 5 },
    { "sucht raidmember", 6 },
    { "kommenden ascended content", 5 },
    { "alle raids auf", 4 },
    { "ascended clear", 4 },
    { "meldet euch", 5 },
    { "bock auf entspanntes", 4 },
    { "erfolgreiches raiden", 5 },
    { "newcomer willkommen", 5 },
    { "newcommer willkommen", 5 },
}

for _, phrase in ipairs(phrases) do
    German.phrases[#German.phrases + 1] = phrase
end
