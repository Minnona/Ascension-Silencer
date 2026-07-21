local AS = AscensionSilencer

function AS:GetElvUISkinModule()
    if not IsAddOnLoaded or not IsAddOnLoaded("ElvUI") then return nil end

    local E = nil
    if type(_G.ElvUI) == "table" then
        E = _G.ElvUI[1]
    end
    if not E and type(_G.E) == "table" then
        E = _G.E
    end
    if not E or not E.GetModule then return nil end

    local ok, skins = pcall(E.GetModule, E, "Skins")
    if ok then return skins end
    return nil
end

local function TryMethod(owner, method, target)
    if owner and owner[method] then
        return pcall(owner[method], owner, target)
    end
    return false
end

function AS:SkinPanel(panel)
    local skins = self:GetElvUISkinModule()
    if not skins or not panel then return end

    if panel.StripTextures then pcall(panel.StripTextures, panel) end
    if panel.CreateBackdrop then
        pcall(panel.CreateBackdrop, panel, "Transparent")
    end
end

function AS:SkinButton(button)
    TryMethod(self:GetElvUISkinModule(), "HandleButton", button)
end

function AS:SkinCheckBox(checkBox)
    TryMethod(self:GetElvUISkinModule(), "HandleCheckBox", checkBox)
end

function AS:SkinSlider(slider)
    local skins = self:GetElvUISkinModule()
    if not TryMethod(skins, "HandleSliderFrame", slider) then
        TryMethod(skins, "HandleSlider", slider)
    end
end

function AS:SkinEditBox(editBox)
    TryMethod(self:GetElvUISkinModule(), "HandleEditBox", editBox)
end

function AS:SkinScrollFrame(scrollFrame)
    if not scrollFrame or not scrollFrame.GetName then return end
    local name = scrollFrame:GetName()
    local scrollBar = name and _G[name .. "ScrollBar"]
    TryMethod(self:GetElvUISkinModule(), "HandleScrollBar", scrollBar)
end
