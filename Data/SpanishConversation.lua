local AS = AscensionSilencer

local languages = AS.Data and AS.Data.languages
local Spanish = languages and languages.Spanish
if not Spanish then return end

Spanish.words = Spanish.words or {}
Spanish.phrases = Spanish.phrases or {}

local words = {
    ["recluta"] = 4,
    ["aceptamos"] = 4,
    ["nuevos"] = 2,
    ["importa"] = 2,
    ["siempre"] = 2,
    ["estamos"] = 2,
    ["alguien"] = 3,
    ["sabe"] = 2,
    ["donde"] = 2,
    ["dónde"] = 2,
    ["veo"] = 2,
    ["cuantos"] = 3,
    ["cuántos"] = 3,
    ["juramentos"] = 3,
    ["tengo"] = 2,
    ["acumulados"] = 3,
    ["tanto"] = 1,
    ["tiempo"] = 2,
    ["jugar"] = 2,
    ["quiero"] = 3,
    ["saber"] = 2,
    ["vale"] = 2,
    ["pena"] = 3,
    ["subir"] = 2,
}

for word, weight in pairs(words) do
    if (tonumber(Spanish.words[word]) or 0) < weight then
        Spanish.words[word] = weight
    end
end

local phrases = {
    { "se recluta gente", 7 },
    { "gente de habla hispana", 7 },
    { "aceptamos nuevos", 6 },
    { "no importa tu lvl", 5 },
    { "siempre estamos en discord", 5 },
    { "alguien sabe donde", 6 },
    { "alguien sabe dónde", 6 },
    { "donde veo cuantos", 5 },
    { "dónde veo cuántos", 5 },
    { "cuantos juramentos", 5 },
    { "cuántos juramentos", 5 },
    { "tengo acumulados", 4 },
    { "no tengo tanto tiempo", 5 },
    { "tengo tanto tiempo", 4 },
    { "para jugar wow", 4 },
    { "quiero saber si", 5 },
    { "vale la pena", 5 },
}

for _, phrase in ipairs(phrases) do
    Spanish.phrases[#Spanish.phrases + 1] = phrase
end
