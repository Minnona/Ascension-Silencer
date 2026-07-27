local AS = AscensionSilencer

local languages = AS.Data and AS.Data.languages
local French = languages and languages.French
if not French then return end

French.words = French.words or {}
French.phrases = French.phrases or {}

local words = {
    ["guilde"] = 4,
    ["québécoise"] = 4,
    ["quebecoise"] = 4,
    ["québécois"] = 4,
    ["quebecois"] = 4,
    ["entraide"] = 3,
    ["invite"] = 1,
    ["recrutent"] = 4,
    ["construction"] = 2,
    ["mythique"] = 3,
    ["humeur"] = 2,
    ["rôles"] = 3,
    ["roles"] = 3,
    ["niveaux"] = 2,
    ["bienvenus"] = 3,
    ["respectueuse"] = 3,
    ["rejoins"] = 4,
    ["meute"] = 3,
}

for word, weight in pairs(words) do
    if (tonumber(French.words[word]) or 0) < weight then
        French.words[word] = weight
    end
end

local phrases = {
    { "guilde 100 québécoise", 7 },
    { "guilde 100 quebecoise", 7 },
    { "guilde québécoise", 6 },
    { "guilde quebecoise", 6 },
    { "chill entraide et fun", 5 },
    { "pm pour invite", 5 },
    { "pour invite", 4 },
    { "guilde pve en construction", 7 },
    { "entraide et bonne humeur", 5 },
    { "tous les rôles", 4 },
    { "tous les roles", 4 },
    { "tous les niveaux", 4 },
    { "sont les bienvenus", 5 },
    { "guilde active respectueuse", 5 },
    { "sans drama", 3 },
    { "rejoins la meute", 6 },
}

for _, phrase in ipairs(phrases) do
    French.phrases[#French.phrases + 1] = phrase
end