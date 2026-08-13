local AS = AscensionSilencer
AS.Data = AS.Data or {}
AS.Data.languages = AS.Data.languages or {}

AS.Data.languages.Swedish = {
    label = "Swedish",
    words = {
        -- Distinctive vocabulary.
        ["söker"] = 4, ["soker"] = 4,
        ["svenska"] = 4, ["svensk"] = 3,
        ["lirare"] = 3, ["spelare"] = 3,
        ["välkomna"] = 4, ["valkomna"] = 4,
        ["medlemmar"] = 3, ["framtida"] = 2,
        ["kravet"] = 2, ["glatt"] = 2,
        ["humör"] = 3, ["humor"] = 2,
        ["njuta"] = 3, ["spelet"] = 2,
        ["också"] = 2, ["ocksa"] = 2,
        ["över"] = 2, ["over"] = 1,
        ["både"] = 2, ["bade"] = 2,
        ["någon"] = 3, ["nagon"] = 3,
        ["köra"] = 3, ["kora"] = 3,
        ["behöver"] = 3, ["behover"] = 3,
        ["hjälp"] = 3, ["hjalp"] = 3,
        ["ikväll"] = 3, ["ikvall"] = 3,
        ["gärna"] = 2, ["garna"] = 2,
        ["tack"] = 2,

        -- Common structure. These are intentionally low weight; language
        -- density and several independent hits are required before they matter.
        ["och"] = 1, ["att"] = 1, ["med"] = 1,
        ["till"] = 1, ["för"] = 1, ["är"] = 1,
        ["ett"] = 1, ["en"] = 1, ["av"] = 1,
        ["nya"] = 1, ["folk"] = 2, ["har"] = 1,
        ["det"] = 1, ["som"] = 1, ["inte"] = 1,
        ["vill"] = 1, ["kan"] = 1, ["vi"] = 1,
        ["ni"] = 1, ["på"] = 1, ["pa"] = 1,
        ["från"] = 1, ["fran"] = 1, ["bra"] = 1,
    },
    phrases = {
        -- Phrases are only capped supporting evidence in NonEnglish.lua.
        { "söker folk", 6 }, { "soker folk", 6 },
        { "söker svenska lirare", 8 }, { "soker svenska lirare", 8 },
        { "socials välkomna", 5 }, { "socials valkomna", 5 },
        { "nya spelare", 4 },
        { "spelare är välkomna", 6 }, { "spelare ar valkomna", 6 },
        { "glatt humör", 5 }, { "glatt humor", 5 },
        { "njuta av spelet", 6 },
        { "för info", 3 },
    },
    chars = { "å", "ä", "ö" },
}
