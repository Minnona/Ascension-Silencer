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

local function AddMatch(matches, label)
    for _, existing in ipairs(matches) do
        if existing == label then return end
    end
    table.insert(matches, label)
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

    local recruit = HasAny(text, { "recruiting", "recruitment", "now recruiting", "is recruiting", "are recruiting" })
    if recruit then
        score = score + 4
        AddMatch(matches, recruit)
    end

    local join = HasAny(text, { "join us", "join our", "come join", "apply now", "whisper for invite", "pm for invite", "message for invite" })
    if join then
        score = score + 3
        AddMatch(matches, join)
    end

    local guild = HasAny(text, { "guild", "community", "family" })
    if guild then
        score = score + 1
        AddMatch(matches, guild)
    end

    local activity = HasAny(text, { "active members", "active guild", "weekly raids", "raid team", "pve and pvp", "pvp and pve", "social guild", "leveling guild", "fresh guild", "new guild" })
    if activity then
        score = score + 2
        AddMatch(matches, activity)
    end

    local promotion = HasAny(text, { "discord", "events", "giveaways", "all are welcome", "everyone welcome", "accepting all", "spots available" })
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
