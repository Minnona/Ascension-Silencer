local AS = AscensionSilencer

local BASE_DEFAULTS = {
    schema = 1,
    enabled = true,
    channels = {
        public = true,
        say = false,
        yell = false,
    },
    filters = {},
    hygiene = {
        enabled = true,
        routeCommercial = true,
        keepTradeClean = true,
        suppressCrossChannel = true,
        duplicateWindow = 12,
        throttleRepeats = true,
        repeatCooldown = 60,
        lfgCooldown = 30,
        tradeChannel = 4,
    },
    exceptions = {
        allowSelf = true,
        allowFriends = true,
        allowGuild = true,
        allowGroup = true,
        players = {},
        phrases = {},
    },
}

local function CopyDefaults(destination, defaults)
    if type(destination) ~= "table" then destination = {} end
    if type(defaults) ~= "table" then return destination end

    for key, value in pairs(defaults) do
        if type(value) == "table" then
            destination[key] = CopyDefaults(destination[key], value)
        elseif destination[key] == nil then
            destination[key] = value
        end
    end

    return destination
end

function AS:InitDatabase()
    if type(_G.AscensionSilencerDB) ~= "table" then
        _G.AscensionSilencerDB = {}
    end

    _G.AscensionSilencerDB = CopyDefaults(_G.AscensionSilencerDB, BASE_DEFAULTS)

    for _, key in ipairs(self.moduleOrder) do
        local module = self.modules[key]
        local defaults = module and module.defaults or { enabled = true, sensitivity = 2 }
        _G.AscensionSilencerDB.filters[key] = CopyDefaults(_G.AscensionSilencerDB.filters[key], defaults)
    end

    _G.AscensionSilencerDB.schema = self.schemaVersion
    _G.AscensionSilencerDB.version = self.version
    self.db = _G.AscensionSilencerDB
end

function AS:ListToText(list)
    if type(list) ~= "table" then return "" end
    return table.concat(list, "\n")
end

function AS:TextToList(text)
    local list = {}
    local seen = {}

    text = tostring(text or "")
    text = string.gsub(text, "\r", "")

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        line = self:Trim(line)
        local key = string.lower(line)
        if line ~= "" and not seen[key] then
            seen[key] = true
            table.insert(list, line)
        end
    end

    return list
end
