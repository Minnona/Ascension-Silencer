local AS = AscensionSilencer

function AS:GetModuleThreshold(module, moduleDB)
    local base = tonumber(module.baseThreshold) or 6
    local sensitivity = tonumber(moduleDB and moduleDB.sensitivity) or 2

    if sensitivity <= 1 then
        return base + 2
    elseif sensitivity >= 3 then
        return math.max(1, base - 2)
    end

    return base
end

function AS:EvaluateContext(context)
    local bestResult = nil
    local evaluations = {}

    for _, key in ipairs(self.moduleOrder) do
        local module = self.modules[key]
        local moduleDB = self:GetModuleDB(key)

        if module and moduleDB and moduleDB.enabled and module.Evaluate then
            local ok, result = pcall(module.Evaluate, module, context, moduleDB, self)
            if ok and type(result) == "table" then
                result.moduleKey = key
                result.moduleName = module.name or key
                result.score = tonumber(result.score) or 0
                result.threshold = self:GetModuleThreshold(module, moduleDB)
                result.priority = tonumber(module.priority) or 0
                result.blocked = result.score >= result.threshold
                table.insert(evaluations, result)

                if result.blocked then
                    local margin = result.score - result.threshold
                    local bestMargin = bestResult and (bestResult.score - bestResult.threshold) or -999
                    local bestPriority = bestResult and (bestResult.priority or 0) or -999
                    if not bestResult
                        or result.priority > bestPriority
                        or (result.priority == bestPriority and margin > bestMargin) then
                        bestResult = result
                    end
                end
            elseif not ok and not module.reportedError then
                module.reportedError = true
                self:Print((module.name or key) .. " filter error: " .. tostring(result))
            end
        end
    end

    context.evaluations = evaluations
    return bestResult, evaluations
end

function AS:EvaluateChatMessage(message, sender, event, ...)
    local excepted = self:IsSenderExcepted(sender, message)
    if excepted then return false end

    local context = self:NormalizeMessage(message)
    context.sender = sender or "Unknown"
    context.event = event
    context.channel = self:GetChannelLabel(event, ...)

    local channelIndex = select(6, ...)
    local channelBaseName = select(7, ...)
    context.channelIndex = tonumber(channelIndex)
    context.channelBaseName = channelBaseName

    local result = self:EvaluateContext(context)
    if not result and self.EvaluateChannelHygiene then
        result = self:EvaluateChannelHygiene(context)
    end
    if not result then return false end

    local now = GetTime and GetTime() or 0
    local blockKey = tostring(event) .. "\031" .. tostring(sender) .. "\031" .. tostring(message)
    local isDuplicate = self.lastBlockedKey == blockKey and (now - (self.lastBlockedTime or 0)) < 0.5

    if not isDuplicate then
        self.lastBlockedKey = blockKey
        self.lastBlockedTime = now
        self:AddBlockedMessage({
            channel = context.channel,
            sender = context.sender,
            message = context.original,
            moduleKey = result.moduleKey,
            moduleName = result.moduleName,
            reason = result.reason or result.moduleName,
            score = result.score,
            threshold = result.threshold,
            matches = result.matches or {},
        })
    end

    return true, result
end

function AS:TestMessage(message)
    local context = self:NormalizeMessage(message)
    context.sender = "Test"
    context.event = "TEST"
    context.channel = "Test"

    local result, evaluations = self:EvaluateContext(context)
    return result, evaluations
end
