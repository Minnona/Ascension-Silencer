local AS = AscensionSilencer

local module = {
    name = "Guild recruitment",
    description = "Blocks guild recruitment advertisements while allowing players who are looking for a guild.",
    baseThreshold = 6,
    priority = 30,
    defaults = {
        enabled = true,
        sensitivity = 2,
    },
}

local RECRUIT_PHRASES = {
    "recruiting", "recruitment", "now recruiting", "is recruiting", "are recruiting",
}

local MEMBER_SEARCH_PHRASES = {
    "looking for more members", "looking for members", "seeking more members", "seeking members",
    "searching for more members", "searching for members", "welcoming new members",
    "looking for more social", "looking for social players", "social adds", "social recruits",
}

local JOIN_PHRASES = {
    "join us", "join our", "come join", "apply now", "whisper for invite", "pm for invite", "message for invite",
    "come be part", "come be a part", "be part of the journey", "become part of",
    "come chill with", "come hang with", "come hangout", "come hang out", "come play with",
}

local GUILD_TERMS = { "guild", "community", "family" }

local ACTIVITY_PHRASES = {
    "active members", "active guild", "weekly raids", "raid team", "pve and pvp", "pvp and pve",
    "social guild", "leveling guild", "fresh guild", "new guild", "independent guild",
    "progress through pve", "progress through pvp", "high risk", "mythics",
    "ascended bb raiding", "raiding 2x/wk", "raiding 2x week", "raid twice a week",
    "chill dad guild", "dad guild", "still raiding",
    "pvp leveling focused guild", "pvp leveling guild", "leveling focused guild",
    "share the experience", "make some new homies",
    "newly formed guild", "eu based guild", "chill community", "community of players",
    "explore end game content", "explore endgame content", "dungeons and raids",
}

local PROMOTION_PHRASES = {
    "discord", "events", "giveaways", "all are welcome", "everyone welcome", "everyone is welcome",
    "accepting all", "spots available", "new players and veterans", "new players welcome",
    "veterans welcome", "veterans alike are welcome", "all experience levels", "players of all experience",
    "active discord", "active discord and chat", "active chat", "leave the drama", "no drama",
    "highly encouraged", "dwarves highly encouraged", "pm for more info", "whisper for more info",
}

local function AddMatch(matches, label)
    for _, existing in ipairs(matches) do
        if existing == label then return end
    end
    matches[#matches + 1] = label
end

local function HasAny(text, values)
    for _, value in ipairs(values) do
        if string.find(text, value, 1, true) then return value end
    end
    return nil
end

function module:Evaluate(context)
    local text = context.searchText
    local score = 0
    local matches = {}

    if string.find(text, "<[^>]+>") then
        score = score + 2
        AddMatch(matches, "guild tag")
    end

    local recruit = HasAny(text, RECRUIT_PHRASES)
    if recruit then
        score = score + 4
        AddMatch(matches, recruit)
    end

    local memberSearch = HasAny(text, MEMBER_SEARCH_PHRASES)
    if memberSearch then
        score = score + 5
        AddMatch(matches, memberSearch)
    end

    local join = HasAny(text, JOIN_PHRASES)
    if join then
        score = score + 3
        AddMatch(matches, join)
    end

    local guild = HasAny(text, GUILD_TERMS)
    if guild then
        score = score + 1
        AddMatch(matches, guild)
    end

    local activity = HasAny(text, ACTIVITY_PHRASES)
    if activity then
        score = score + 2
        AddMatch(matches, activity)
    end

    local promotion = HasAny(text, PROMOTION_PHRASES)
    if promotion then
        score = score + 2
        AddMatch(matches, promotion)
    end

    if string.find(text, "looking for a guild", 1, true)
        or string.find(text, "looking for guild", 1, true)
        or string.find(text, "lf guild", 1, true)
        or string.find(text, "any guild", 1, true) then
        score = score - 7
        AddMatch(matches, "player looking for guild")
    end

    if string.find(text, "?", 1, true) and not recruit then
        score = score - 2
    end

    return {
        score = math.max(0, score),
        reason = "Guild recruitment advertisement",
        matches = matches,
    }
end

AS:RegisterModule("GuildRecruitment", module)
