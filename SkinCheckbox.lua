local AS = AscensionSilencer

-- Preserve the checkbox behavior and appearance used before the performance refactor.
-- ElvUI owns the checked texture, color and state updates.
function AS:SkinCheckBox(checkBox)
    if not checkBox or not self:IsElvUIAvailable() then return end

    if not checkBox.asElvUISkinned then
        local skins = self:GetElvUISkinModule()
        local handled = false
        if skins and type(skins.HandleCheckBox) == "function" then
            handled = pcall(skins.HandleCheckBox, skins, checkBox)
        end

        -- Do not lock in a failed early attempt. ApplyOptionsSkin can retry after ElvUI finishes loading.
        if handled then checkBox.asElvUISkinned = true end
    end

    local name = checkBox.GetName and checkBox:GetName()
    local text = name and _G[name .. "Text"]
    if text then
        text:ClearAllPoints()
        text:SetPoint("LEFT", checkBox, "RIGHT", 5, 1)
    end
end
