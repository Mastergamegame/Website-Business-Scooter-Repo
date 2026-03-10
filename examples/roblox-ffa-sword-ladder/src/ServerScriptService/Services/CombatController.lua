local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(gameConfig, roundService, progressionService, remotes, loadCharacterFn, antiExploitService)
    local self = setmetatable({}, CombatController)
    self.gameConfig = gameConfig or {}
    self.roundService = roundService
    self.progressionService = progressionService
    self.remotes = remotes
    self.loadCharacterFn = loadCharacterFn
    self.antiExploitService = antiExploitService
    self.connections = {}
    return self
end

function CombatController:_extractKillerFromHumanoid(humanoid)
    local creator = humanoid:FindFirstChild("creator") or humanoid:FindFirstChild("Creator")
    local killer = creator and creator.Value
    if killer and killer:IsA("Player") then
        return killer, creator
    end
    return nil, creator
end

function CombatController:_validateReach(attacker, victimPlayer, victimCharacter)
    if not attacker or not victimCharacter then
        return true, nil, nil
    end

    local attackerCharacter = attacker.Character
    local attackerRoot = attackerCharacter and attackerCharacter:FindFirstChild("HumanoidRootPart")
    local victimRoot = victimCharacter:FindFirstChild("HumanoidRootPart")
    if not attackerRoot or not victimRoot then
        return true, nil, nil
    end

    local dist = (attackerRoot.Position - victimRoot.Position).Magnitude
    local yDiff = math.abs(attackerRoot.Position.Y - victimRoot.Position.Y)

    local maxReach = (self.gameConfig.ANTI_EXPLOIT_REACH_MAX_STUDS or 16) + (self.gameConfig.ANTI_EXPLOIT_REACH_BUFFER_STUDS or 2.5)
    local maxVertical = self.gameConfig.ANTI_EXPLOIT_REACH_VERTICAL_MAX_STUDS or 18

    local ok = (dist <= maxReach) and (yDiff <= maxVertical)
    return ok, dist, maxReach, yDiff, maxVertical
end

function CombatController:_handleReachViolation(attacker, victim, dist, maxReach, yDiff, maxVertical)
    if not attacker then
        return
    end

    warn(string.format(
        "[AntiExploit] Reach violation attacker=%s(%d) victim=%s(%d) dist=%.2f allowed=%.2f yDiff=%.2f yAllowed=%.2f",
        attacker.Name,
        attacker.UserId,
        victim and victim.Name or "unknown",
        victim and victim.UserId or -1,
        tonumber(dist) or -1,
        tonumber(maxReach) or -1,
        tonumber(yDiff) or -1,
        tonumber(maxVertical) or -1
    ))

    if self.antiExploitService and self.antiExploitService.ReportReachViolation then
        self.antiExploitService:ReportReachViolation(attacker, victim, dist, maxReach)
        return
    end

    pcall(function()
        attacker:Kick("Anti-cheat triggered (ReachViolation)")
    end)
end

function CombatController:_hookCharacter(player, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    local deathHandled = false
    local lastHealth = humanoid.Health

    local healthConn = humanoid.HealthChanged:Connect(function(newHealth)
        if newHealth >= lastHealth then
            lastHealth = newHealth
            return
        end

        local previousHealth = lastHealth
        lastHealth = newHealth

        if not self.roundService:IsRoundActive() then
            return
        end

        if player:GetAttribute("InMatch") ~= true then
            return
        end

        local attacker, creatorTag = self:_extractKillerFromHumanoid(humanoid)
        if not attacker or attacker == player then
            return
        end

        local validReach, dist, maxReach, yDiff, maxVertical = self:_validateReach(attacker, player, character)
        if validReach then
            return
        end

        if humanoid.Health > 0 then
            humanoid.Health = math.min(humanoid.MaxHealth, previousHealth)
            lastHealth = humanoid.Health
        end

        if creatorTag and creatorTag.Parent then
            creatorTag:Destroy()
        end

        self:_handleReachViolation(attacker, player, dist, maxReach, yDiff, maxVertical)
    end)
    table.insert(self.connections, healthConn)

    local deathConn = humanoid.Died:Connect(function()
        if deathHandled then
            return
        end
        deathHandled = true

        local shouldRespawn = player:GetAttribute("InMatch") == true
        local victimRoot = character:FindFirstChild("HumanoidRootPart")

        if self.roundService:IsRoundActive() and shouldRespawn then
            local killer = nil
            local invalidReachKill = false

            local killerCandidate = self:_extractKillerFromHumanoid(humanoid)
            if killerCandidate and killerCandidate:IsA("Player") and killerCandidate ~= player and killerCandidate:GetAttribute("InMatch") then
                local validReach, dist, maxReach, yDiff, maxVertical = self:_validateReach(killerCandidate, player, character)
                if validReach then
                    killer = killerCandidate
                else
                    invalidReachKill = true
                    self:_handleReachViolation(killerCandidate, player, dist, maxReach, yDiff, maxVertical)
                end
            end

            if not invalidReachKill then
                self.progressionService:OnDeath(player)

                if killer then
                    local killResult = self.progressionService:OnKill(killer, player)

                    local distanceStuds = nil
                    local killerCharacter = killer.Character
                    local killerRoot = killerCharacter and killerCharacter:FindFirstChild("HumanoidRootPart")
                    if killerRoot and victimRoot then
                        distanceStuds = math.floor((killerRoot.Position - victimRoot.Position).Magnitude + 0.5)
                    end

                    self.remotes.KillFeedEvent:FireAllClients({
                        killerUserId = killer.UserId,
                        killerName = killer.Name,
                        victimUserId = player.UserId,
                        victimName = player.Name,
                        distanceStuds = distanceStuds,
                    })

                    if killResult.won then
                        self.roundService:EndRound("DarkheartFinalKill", killer.UserId)
                    end
                end
            end
        end

        if shouldRespawn then
            task.delay(1.5, function()
                if player.Parent and player:GetAttribute("InMatch") then
                    if self.loadCharacterFn then
                        self.loadCharacterFn(player)
                    else
                        player:LoadCharacter()
                    end
                end
            end)
        end
    end)

    table.insert(self.connections, deathConn)
end

function CombatController:HookPlayer(player)
    local addedConn = player.CharacterAdded:Connect(function(character)
        self:_hookCharacter(player, character)
    end)

    table.insert(self.connections, addedConn)

    if player.Character then
        self:_hookCharacter(player, player.Character)
    end
end

function CombatController:Destroy()
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
    self.connections = {}
end

return CombatController
