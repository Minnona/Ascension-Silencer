local AS = AscensionSilencer

local module = {
    name = "Stream advertisements",
    description = "Blocks Twitch, Kick and livestream promotion while allowing ordinary streamer discussion.",
    baseThreshold = 6,
    priority = 40,
    defaults = {
        enabled = true,
        sensitivity = 2,
        allowClips = true,
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

function module:Evaluate(context, moduleDB)
    local text = context.searchText
    local score = 0
    local matches = {}

    local isClip = string.find(text, "clips.twitch.tv/", 1, true)
        or string.find(text, "/clip/", 1, true)
        or string.find(text, "twitch.tv/clip", 1, true)

    local directLink = HasAny(text, {
        "twitch.tv/", "www.twitch.tv/", "kick.com/", "youtube.com/live/",
    })

    if directLink and not (isClip and moduleDB.allowClips) then
        score = score + 6
        AddMatch(matches, directLink)
    elseif isClip and moduleDB.allowClips then
        AddMatch(matches, "allowed Twitch clip")
    end

    local live = HasAny(text, { "live now", "going live", "currently live", "streaming now", "i am live", "i'm live" })
    if live then
        score = score + 3
        AddMatch(matches, live)
    end

    local callToAction = HasAny(text, { "come watch", "come hang out", "watch me", "follow my stream", "drop a follow", "check out my stream", "join the stream" })
    if callToAction then
        score = score + 3
        AddMatch(matches, callToAction)
    end

    local promotion = HasAny(text, { "drops enabled", "road to affiliate", "road to partner", "viewer games", "stream giveaway", "giveaway on stream" })
    if promotion then
        score = score + 2
        AddMatch(matches, promotion)
    end

    if context.tokenSet.stream or context.tokenSet.streaming or context.tokenSet.twitch or context.tokenSet.kick then
        score = score + 1
    end

    if isClip and moduleDB.allowClips and not live and not callToAction and not promotion then
        score = 0
    end

    return {
        score = math.max(0, score),
        reason = "Livestream advertisement",
        matches = matches,
    }
end

AS:RegisterModule("StreamAdvertising", module)
