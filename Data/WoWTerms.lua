local AS = AscensionSilencer
AS.Data = AS.Data or {}

local terms = {
    "lfg", "lfm", "lf", "wts", "wtb", "wtt", "dps", "tank", "tanks", "heal", "heals", "healer", "healers",
    "raid", "raids", "dungeon", "dungeons", "group", "groups", "party", "quest", "quests", "guild", "guilds",
    "bg", "bgs", "arena", "arenas", "pvp", "pve", "rdf", "hc", "heroic", "normal", "mythic", "world", "boss",
    "brd", "ubrs", "lbrs", "strat", "scholo", "zg", "aq", "aq20", "aq40", "mc", "bwl", "ony", "naxx",
    "kara", "mag", "gruul", "ssc", "tk", "bt", "swp", "toc", "icc", "voa", "ulduar", "nexus", "naxxramas",
    "need", "needall", "roll", "loot", "summon", "summons", "portal", "port", "layer", "inv", "invite", "pst",
    "spec", "build", "class", "classes", "level", "lvl", "gear", "geared", "bis", "prebis", "farm", "farming",
    "ascension", "area52", "elune", "season", "draft", "prestige", "mystic", "enchant", "enchants", "manastorm",
    "gold", "silver", "copper", "g", "dp", "token", "tokens", "bazaar",
}

AS.Data.wowTerms = {}
for _, term in ipairs(terms) do
    AS.Data.wowTerms[term] = true
end

local english = {
    "a", "an", "and", "are", "any", "anyone", "be", "can", "come", "do", "does", "for", "from", "good", "got",
    "have", "hello", "hey", "how", "i", "if", "in", "is", "it", "join", "just", "know", "looking", "me", "more",
    "my", "need", "new", "no", "not", "of", "on", "one", "or", "please", "run", "some", "someone", "thanks",
    "that", "the", "their", "there", "they", "this", "to", "up", "want", "we", "what", "when", "where", "who",
    "why", "with", "yes", "you", "your", "fun", "lol", "lmao", "bro", "guys", "people", "today", "tonight",
}

AS.Data.englishWords = {}
for _, word in ipairs(english) do
    AS.Data.englishWords[word] = true
end
