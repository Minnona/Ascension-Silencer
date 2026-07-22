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

function AS:GetFilterEvaluationOrder()
    if self.filterEvaluationOrder then return self.filterEvaluationOrder end

    local order = {}
    for index, key in ipairs(self.moduleOrder) do
        local module = self.modules[key]
        order[#order + 1] = {
            key = key,
            index = index,
            priority = tonumber(module and module.priority) or 0,
        }
    end

    table.sort(order, function(left, right)
        if left.priority == right.priority then return left.index < right.index end
        return left.priority > right.priority
    end)

    self.filterEvaluationOrder = order
    return order
end

function AS:EvaluateContext(context, collectEvaluations)
    local bestResult = nil
    local evaluations = collectEvaluations and {} or nil

    for _, ordered in ipairs(self:GetFilterEvaluationOrder()) do
        local key = ordered.key
        local module = self.modules[key]
        local moduleDB = self:GetModuleDB(key)

        if bestResult and not collectEvaluations and ordered.priority < (bestResult.priority or 0) then
            break
        end

        if module and not module.runtimeDisabled and moduleDB and moduleDB.enabled and module.Evaluate then
            local ok, result = pcall(module.Evaluate, module, context, moduleDB, self)
            if ok and type(result) == "table" then
                result.moduleKey = key
                result.moduleName = module.name or key
                result.score = tonumber(result.score) or 0
                result.threshold = self:GetModuleThreshold(module, moduleDB)
                result.priority = ordered.priority
                result.blocked = result.score >= result.threshold

                if evaluations then evaluations[#evaluations + 1] = result end

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
            elseif not ok then
                module.runtimeDisabled = true
                if not module.reportedError then
                    module.reportedError = true
                    self:Print((module.name or key) .. " filter disabled after error: " .. tostring(result))
                end
            end
        end
    end

    if collectEvaluations then context.evaluations = evaluations end
    return bestResult, evaluations
end

local function MakeMessageCacheKey(event, message, sender, channelIndex, lineID)
    local numericLineID = tonumber(lineID)
    if numericLineID and numericLineID > 0 then
        return tostring(event) .. "\031line\031" .. tostring(numericLineID), 2
    end

    return tostring(event)
        .. "\031" .. tostring(sender)
        .. "\031" .. tostring(channelIndex)
        .. "\031" .. tostring(message), 0.10
end

local function FinishMessageEvaluation(addon, cacheKey, now, blocked, result)
    addon.lastMessageEvaluation = {
        key = cacheKey,
        time = now,
        blocked = blocked and true or false,
        result = result,
    }
    return blocked and true or false, result
end

function AS:EvaluateChatMessage(message, sender, event, ...)
    local channelIndex = select(6, ...)
    local channelBaseName = select(7, ...)
    local lineID = select(9, ...)
    local now = GetTime and GetTime() or 0
    local cacheKey, cacheLifetime = MakeMessageCacheKey(event, message, sender, channelIndex, lineID)
    local cached = self.lastMessageEvaluation

    if cached and cached.key == cacheKey and (now - cached.time) < cacheLifetime then
        return cached.blocked, cached.result
    end

    local senderKey = self:CanonicalName(sender)
    local excepted = self:IsSenderExcepted(sender, message, senderKey)
    if excepted then return FinishMessageEvaluation(self, cacheKey, now, false, nil) end

    local context = self:NormalizeMessage(message)
    context.sender = sender or "Unknown"
    context.senderKey = senderKey
    context.event = event
    context.channel = self:GetChannelLabel(event, ...)
    context.channelIndex = tonumber(channelIndex)
    context.channelBaseName = channelBaseName
    context.lineID = lineID

    local result = self:EvaluateContext(context, false)
    if not result and self.EvaluateChannelHygiene then
        result = self:EvaluateChannelHygiene(context)
    end
    if not result then return FinishMessageEvaluation(self, cacheKey, now, false, nil) end

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

    return FinishMessageEvaluation(self, cacheKey, now, true, result)
end

function AS:TestMessage(message)
    local context = self:NormalizeMessage(message)
    context.sender = "Test"
    context.senderKey = "test"
    context.event = "TEST"
    context.channel = "Test"

    local result, evaluations = self:EvaluateContext(context, true)
    return result, evaluations
end
