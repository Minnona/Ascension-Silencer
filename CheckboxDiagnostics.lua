local AS = AscensionSilencer

local DIAGNOSTIC_VERSION = "checkbox-diag1"
local MAX_PARENT_DEPTH = 10
local MAX_CHAT_LENGTH = 230

local diagnostics = {
    version = DIAGNOSTIC_VERSION,
    records = {},
    byControl = setmetatable({}, { __mode = "k" }),
    announcedError = false,
}
AS.checkboxDiagnostics = diagnostics

local OriginalSkinCheckBox = AS.SkinCheckBox

local function SafeCall(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        return false, "missing"
    end
    return pcall(object[method], object, ...)
end

local function TrimForChat(value)
    value = tostring(value or "")
    value = string.gsub(value, "[\r\n]+", " ")
    if string.len(value) > MAX_CHAT_LENGTH then
        value = string.sub(value, 1, MAX_CHAT_LENGTH - 3) .. "..."
    end
    return value
end

local function BoolLabel(value)
    return value and "yes" or "no"
end

local function ObjectLabel(object)
    if not object then return "nil" end

    local _, name = SafeCall(object, "GetName")
    local _, objectType = SafeCall(object, "GetObjectType")
    name = name and tostring(name) or "<unnamed>"
    objectType = objectType and tostring(objectType) or "unknown"
    return name .. "[" .. objectType .. "]"
end

local function ParentChain(frame)
    local parts = {}
    local parent = frame and frame.GetParent and frame:GetParent()
    local depth = 0
    local insideScrollFrame = false

    while parent and depth < MAX_PARENT_DEPTH do
        local _, objectType = SafeCall(parent, "GetObjectType")
        if objectType == "ScrollFrame" then insideScrollFrame = true end
        parts[#parts + 1] = ObjectLabel(parent)
        parent = parent.GetParent and parent:GetParent() or nil
        depth = depth + 1
    end

    return table.concat(parts, " <- "), insideScrollFrame
end

local function TextureSummary(texture)
    if not texture then return "nil" end

    local _, path = SafeCall(texture, "GetTexture")
    local _, shown = SafeCall(texture, "IsShown")
    local _, alpha = SafeCall(texture, "GetAlpha")
    local colorOK, r, g, b, a = SafeCall(texture, "GetVertexColor")
    local layerOK, layer, subLevel = SafeCall(texture, "GetDrawLayer")
    local _, width = SafeCall(texture, "GetWidth")
    local _, height = SafeCall(texture, "GetHeight")

    local color = "n/a"
    if colorOK and r and g and b then
        color = string.format("%.2f,%.2f,%.2f,%.2f", r, g, b, a or 1)
    end

    local drawLayer = "n/a"
    if layerOK and layer then
        drawLayer = tostring(layer) .. ":" .. tostring(subLevel or 0)
    end

    return string.format(
        "path=%s shown=%s alpha=%s color=%s layer=%s size=%sx%s parent=%s",
        tostring(path),
        BoolLabel(shown),
        tostring(alpha),
        color,
        drawLayer,
        tostring(width),
        tostring(height),
        ObjectLabel(texture.GetParent and texture:GetParent() or nil)
    )
end

local function FrameSummary(frame)
    if not frame then return "nil" end

    local _, shown = SafeCall(frame, "IsShown")
    local _, level = SafeCall(frame, "GetFrameLevel")
    local _, strata = SafeCall(frame, "GetFrameStrata")
    local _, width = SafeCall(frame, "GetWidth")
    local _, height = SafeCall(frame, "GetHeight")

    return string.format(
        "%s shown=%s level=%s strata=%s size=%sx%s",
        ObjectLabel(frame),
        BoolLabel(shown),
        tostring(level),
        tostring(strata),
        tostring(width),
        tostring(height)
    )
end

local function Snapshot(checkBox)
    local _, checkedTexture = SafeCall(checkBox, "GetCheckedTexture")
    local _, disabledCheckedTexture = SafeCall(checkBox, "GetDisabledCheckedTexture")
    local _, checked = SafeCall(checkBox, "GetChecked")
    local _, level = SafeCall(checkBox, "GetFrameLevel")
    local _, strata = SafeCall(checkBox, "GetFrameStrata")
    local chain, insideScrollFrame = ParentChain(checkBox)

    return {
        checked = checked and true or false,
        frameLevel = level,
        frameStrata = strata,
        parentChain = chain,
        insideScrollFrame = insideScrollFrame,
        elvIsSkinned = checkBox.isSkinned and true or false,
        addonIsSkinned = checkBox.asElvUISkinned and true or false,
        backdrop = FrameSummary(checkBox.backdrop or checkBox.Backdrop),
        checkedTexture = TextureSummary(checkedTexture),
        disabledCheckedTexture = TextureSummary(disabledCheckedTexture),
        scrollIndicator = FrameSummary(checkBox.asScrollCheckedIndicator),
        scrollIndicatorFill = TextureSummary(checkBox.asScrollCheckedFill),
        hasStripTextures = type(checkBox.StripTextures) == "function",
        hasCreateBackdrop = type(checkBox.CreateBackdrop) == "function",
        hasSetInside = checkedTexture and type(checkedTexture.SetInside) == "function" or false,
    }
end

local function AddRecord(checkBox, ok, errorMessage, before, after)
    local record = {
        control = checkBox,
        name = ObjectLabel(checkBox),
        ok = ok and true or false,
        errorMessage = ok and nil or tostring(errorMessage or "unknown error"),
        before = before,
        after = after,
    }

    diagnostics.records[#diagnostics.records + 1] = record
    diagnostics.byControl[checkBox] = record
    return record
end

function AS:SkinCheckBox(checkBox)
    if not checkBox then return end
    if not self:IsElvUIAvailable() then
        return OriginalSkinCheckBox(self, checkBox)
    end
    if checkBox.asElvUISkinned then
        return OriginalSkinCheckBox(self, checkBox)
    end

    local before = Snapshot(checkBox)
    local skins = self:GetElvUISkinModule()
    local ok, errorMessage

    if skins and type(skins.HandleCheckBox) == "function" then
        ok, errorMessage = pcall(skins.HandleCheckBox, skins, checkBox)
    else
        ok = false
        errorMessage = "ElvUI Skins:HandleCheckBox is unavailable"
    end

    -- Preserve the production build's current behavior. The diagnostic branch
    -- records the failure but does not repeatedly reskin or add polling.
    checkBox.asElvUISkinned = true
    OriginalSkinCheckBox(self, checkBox)

    local record = AddRecord(checkBox, ok, errorMessage, before, Snapshot(checkBox))
    if not record.ok and not diagnostics.announcedError then
        diagnostics.announcedError = true
        self:Print("Checkbox diagnostic captured an ElvUI error. Run /asdiag full.")
    end
end

local function Chat(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00ASDiag:|r " .. TrimForChat(message))
    end
end

local function EngineSummary(addon)
    local E = addon:GetElvUIEngine()
    local skins = addon:GetElvUISkinModule()
    local version = E and (E.version or E.Version or E.ver) or "unavailable"
    local checkBoxSkin = E and E.private and E.private.skins and E.private.skins.checkBoxSkin
    local melli = E and E.Media and E.Media.Textures and E.Media.Textures.Melli

    return string.format(
        "build=%s ElvUI=%s HandleCheckBox=%s checkBoxSkin=%s Melli=%s",
        DIAGNOSTIC_VERSION,
        tostring(version),
        type(skins and skins.HandleCheckBox),
        tostring(checkBoxSkin),
        tostring(melli)
    )
end

function AS:PrintCheckboxDiagnostics(mode)
    mode = string.lower(self:Trim(mode or ""))
    local full = mode == "full"
    local errorsOnly = mode == "errors"

    if mode == "clear" then
        diagnostics.records = {}
        diagnostics.byControl = setmetatable({}, { __mode = "k" })
        diagnostics.announcedError = false
        Chat("diagnostic records cleared; reload the UI to capture initial skinning again")
        return
    end

    local failureCount = 0
    for _, record in ipairs(diagnostics.records) do
        if not record.ok then failureCount = failureCount + 1 end
    end

    Chat(EngineSummary(self))
    Chat(string.format("records=%d failures=%d", #diagnostics.records, failureCount))

    if #diagnostics.records == 0 then
        Chat("no checkbox skin attempts were captured; open the AddOns panels and run /asdiag full again")
        return
    end

    for index, record in ipairs(diagnostics.records) do
        if not errorsOnly or not record.ok then
            local current = Snapshot(record.control)
            Chat(string.format(
                "#%d %s handle=%s checked=%s scroll=%s ElvSkinned=%s backdrop=%s",
                index,
                record.name,
                record.ok and "OK" or "FAILED",
                BoolLabel(current.checked),
                BoolLabel(current.insideScrollFrame),
                BoolLabel(current.elvIsSkinned),
                current.backdrop
            ))

            if not record.ok then
                Chat("error: " .. tostring(record.errorMessage))
            end

            if full then
                Chat("before checked texture: " .. record.before.checkedTexture)
                Chat("after checked texture: " .. record.after.checkedTexture)
                Chat("current checked texture: " .. current.checkedTexture)
                Chat("current disabled texture: " .. current.disabledCheckedTexture)
                Chat("current indicator: " .. current.scrollIndicator)
                Chat("current indicator fill: " .. current.scrollIndicatorFill)
                Chat(string.format(
                    "methods StripTextures=%s CreateBackdrop=%s checked:SetInside=%s frame=%s/%s",
                    BoolLabel(current.hasStripTextures),
                    BoolLabel(current.hasCreateBackdrop),
                    BoolLabel(current.hasSetInside),
                    tostring(current.frameStrata),
                    tostring(current.frameLevel)
                ))
                Chat("parents: " .. current.parentChain)
            end
        end
    end

    if not full then
        Chat("use /asdiag full for texture/layer details or /asdiag errors for failures only")
    end
end

SLASH_ASCENSIONSILENCERCHECKBOXDIAG1 = "/asdiag"
SlashCmdList["ASCENSIONSILENCERCHECKBOXDIAG"] = function(message)
    AS:PrintCheckboxDiagnostics(message)
end

local notice = CreateFrame("Frame")
notice:RegisterEvent("PLAYER_LOGIN")
notice:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    AS:Print("Checkbox diagnostic build active. Open the affected panels, toggle one checkbox, then run /asdiag full.")
end)
