local AS = AscensionSilencer

SLASH_ASCENSIONSILENCERCHECK1 = "/ascheck"
SlashCmdList["ASCENSIONSILENCERCHECK"] = function(message)
    message = AS:Trim(message)
    if message == "" then
        AS:Print("Usage: /ascheck <message>")
        return
    end

    local bestResult, evaluations = AS:TestMessage(message)
    AS:Print("Score check: " .. message)

    for _, result in ipairs(evaluations or {}) do
        local state = result.blocked and "BLOCK" or "pass"
        AS:Print(string.format(
            "%s: %.1f/%.1f %s - %s",
            tostring(result.moduleName or result.moduleKey or "Filter"),
            tonumber(result.score) or 0,
            tonumber(result.threshold) or 0,
            state,
            tostring(result.reason or "")
        ))

        if result.matches and #result.matches > 0 then
            AS:Print("  matches: " .. table.concat(result.matches, ", "))
        end
    end

    if not bestResult then
        AS:Print("Result: allowed")
    else
        AS:Print("Result: blocked by " .. tostring(bestResult.moduleName or bestResult.moduleKey or "filter"))
    end
end
