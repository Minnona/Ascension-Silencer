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
    -- Common chat misspellings. Keep these explicit instead of using fuzzy matching
    -- in the live chat path.
    "recruting", "recruitng", "recuiting", "recrutiting",
}

local MEMBER_SEARCH_PHRASES = {
    "looking for more members", "looking for members", "seeking more members", "seeking members",
    "searching for more members", "searching for members", "welcoming new members",
    "looking for more social", "looking for social players", "social adds", "social recruits",
    "seeking players", "seeking active players", "looking for players", "searching for players",
}

local JOIN_PHRASES = {
    "join us", "join our", "come join", "apply now", "whisper for invite", "pm for invite", "message for invite",
    "come be part", "come be a part", "be part of the journey", "become part of",
    "come chill with", "come hang with", "come hangout", "come hang out", "come play with",
    "whisper for an invite", "whisper for info", "whisper for more info",
    "whisper for more info or an invite", "pm for more info or an invite",
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
    "end game raids", "endgame raids", "structured pvp",
    "active leadership", "experienced leadership", "mature leadership",
    "previous bb realm first", "realm first", "for main raid", "main raid",
    "building groups for", "building groups", "groups for dungeons", "raids and pvp",
}

local PROMOTION_PHRASES = {
    "discord", "events", "giveaways", "all are welcome", "everyone welcome", "everyone is welcome",
    "accepting all", "spots available", "new players and veterans", "new players welcome",
    "veterans welcome", "veterans alike are welcome", "all experience levels", "players of all experience",
    "active discord", "active discord and chat", "active chat", "leave the drama", "no drama",
    "highly encouraged", "dwarves highly encouraged", "pm for more info", "whisper for more info",
    "more info or an invite", "info or an invite", "welcomes everyone", "fresh newbies",
    "experienced sweats", "help your mates", "have a crack",
}

local ROLE_RECRUIT_TERMS = {
    "inspiration", "ancestry", "godblade", "runemaster", "pyro", "inventor",
    "chronomancer", "tinker", "support spec", "witch hunter",
}

local MEMBER_SEARCH_TARGETS = {
    member = true,
    members = true,
}

local RECRUIT_INTENT_STARTERS = {
    aim = true, aiming = true, aims = true,
    hope = true, hoping = true, hopes = true,
    look = true, looking = true,
    plan = true, planning = true, plans = true,
    seek = true, seeking = true, seeks = true,
    try = true, trying = true, tries = true,
    want = true, wanting = true, wants = true,
}

local function HasRecentNegation(tokens, index)
    for tokenIndex = math.max(1, index - 3), index - 1 do
        local token = tokens[tokenIndex]
        if token == "no" or token == "not" or token == "never" then
            return true
        end
    end
    return false
end

local function FindRecruitIntent(tokens)
    for index, token in ipairs(tokens) do
        if RECRUIT_INTENT_STARTERS[token]
            and not HasRecentNegation(tokens, index)
            and tokens[index + 1] == "to" then
            -- Permit one adverb in constructions such as "plans to actively
            -- recruit", while keeping the live-chat scan tightly bounded.
            local targetEnd = math.min(#tokens, index + 3)
            for targetIndex = index + 2, targetEnd do
                if tokens[targetIndex] == "recruit" then
                    return "recruitment intent"
                end
            end
        end
    end

    return nil
end

local function FindMemberSearchIntent(tokens)
    for index, token in ipairs(tokens) do
        local targetStart
        if (token == "looking" or token == "searching") and tokens[index + 1] == "for" then
            targetStart = index + 2
        elseif token == "seeking" or token == "welcoming" then
            targetStart = index + 1
        end

        if targetStart then
            -- Allow a few descriptive words, such as "new active members",
            -- without doing fuzzy or unbounded matching in the chat path.
            local targetEnd = math.min(#tokens, targetStart + 3)
            for targetIndex = targetStart, targetEnd do
                if MEMBER_SEARCH_TARGETS[tokens[targetIndex]] then
                    return "member-seeking intent"
                end
            end
        end
    end

    return nil
end

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

local function CountTerms(text, values)
    local count = 0
    for _, value in ipairs(values) do
        if string.find(text, value, 1, true) then
            count = count + 1
        end
    end
    return count
end

function module:Evaluate(context)
    local text = context.searchText
    local score = 0
    local matches = {}
    local hasGuildTag = string.find(text, "<[^>]+>") ~= nil

    if hasGuildTag then
        score = score + 2
        AddMatch(matches, "guild tag")
    end

    local guild = HasAny(text, GUILD_TERMS)
    local recruit = HasAny(text, RECRUIT_PHRASES)
    local recruitScore = 4
    if not recruit and (hasGuildTag or guild) then
        recruit = FindRecruitIntent(context.tokens or {})
        if recruit then recruitScore = 5 end
    end
    if recruit then
        score = score + recruitScore
        AddMatch(matches, recruit)
    end

    local memberSearch = HasAny(text, MEMBER_SEARCH_PHRASES)
    if not memberSearch and (hasGuildTag or guild) then
        memberSearch = FindMemberSearchIntent(context.tokens or {})
    end
    if memberSearch then
        score = score + 5
        AddMatch(matches, memberSearch)
    end

    local join = HasAny(text, JOIN_PHRASES)
    if join then
        score = score + 3
        AddMatch(matches, join)
    end

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

    local tokenSet = context.tokenSet or {}
    local roleCount = CountTerms(text, ROLE_RECRUIT_TERMS)
    local raidRecruitContext = string.find(text, "main raid", 1, true)
        or string.find(text, "realm first", 1, true)
        or string.find(text, "discord", 1, true)
        or string.find(text, "na raid", 1, true)
        or string.find(text, "eu raid", 1, true)

    if tokenSet.lf and roleCount >= 2 and raidRecruitContext then
        score = score + 5
        AddMatch(matches, "raid role recruitment")
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
    elseif string.find(text, "?", 1, true)
        and (string.find(text, "is ", 1, true) or string.find(text, "any ", 1, true)) then
        -- Questions about a guild recruiting are not advertisements.
        score = score - 2
    end

    return {
        score = math.max(0, score),
        reason = "Guild recruitment advertisement",
        matches = matches,
    }
end

AS:RegisterModule("GuildRecruitment", module)
