local Players = game:GetService("Players")

local RoundService = {}
RoundService.__index = RoundService

function RoundService.new(gameConfig, progressionService, spawnService, loadoutService, remotes, loadCharacterFn)
    local self = setmetatable({}, RoundService)
    self.gameConfig = gameConfig
    self.progressionService = progressionService
    self.spawnService = spawnService
    self.loadoutService = loadoutService
    self.remotes = remotes
    self.loadCharacterFn = loadCharacterFn

    self.state = "Lobby"
    self.timeRemaining = 0
    self.roundId = 0
    self.endedRoundId = -1

    self._running = false
    return self
end

function RoundService:GetState()
    return self.state
end

function RoundService:IsRoundActive()
    return self.state == "Round"
end

function RoundService:GetActivePlayers()
    local active = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("InMatch") then
            table.insert(active, player)
        end
    end
    return active
end

function RoundService:_broadcastRoundState(extra)
    local leader = self.progressionService:GetLeader(self:GetActivePlayers())
    local payload = {
        state = self.state,
        timeRemaining = self.timeRemaining,
        leaderUserId = leader and leader.UserId or nil,
        leaderTier = leader and (leader:GetAttribute("Tier") or 0) or nil,
        leaderKills = leader and (leader:GetAttribute("Kills") or 0) or nil,
    }

    if extra then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    end

    self.remotes.RoundStateChanged:FireAllClients(payload)
end

function RoundService:_setState(nextState, nextTime, extra)
    self.state = nextState
    self.timeRemaining = math.max(nextTime or 0, 0)
    self:_broadcastRoundState(extra)
end

function RoundService:TryStartIntermission()
    if self.state ~= "Lobby" then
        return
    end

    if #self:GetActivePlayers() >= self.gameConfig.MIN_PLAYERS_TO_START then
        self:_setState("Intermission", self.gameConfig.INTERMISSION_DURATION, { reason = "IntermissionStarted" })
    else
        self:_broadcastRoundState({ reason = "WaitingForPlayers" })
    end
end

function RoundService:StartRound()
    self.roundId += 1
    self.endedRoundId = -1

    self:_setState("Round", self.gameConfig.ROUND_DURATION, { reason = "RoundStarted" })

    local activePlayers = self:GetActivePlayers()
    self.progressionService:ResetForRound(activePlayers)

    for _, player in ipairs(activePlayers) do
        local hadCharacter = player.Character ~= nil

        if not hadCharacter then
            if self.loadCharacterFn then
                self.loadCharacterFn(player)
            else
                player:LoadCharacter()
            end
        else
            task.delay(0.2, function()
                if player.Parent and player:GetAttribute("InMatch") then
                    self.spawnService:TeleportCharacterToSpawn(player)
                    self.loadoutService:EquipCurrentTier(player)
                end
            end)
        end
    end
end

function RoundService:EndRound(reason, winnerUserId)
    if self.state ~= "Round" then
        return
    end

    if self.endedRoundId == self.roundId then
        return
    end

    self.endedRoundId = self.roundId
    self:_setState("PostRound", self.gameConfig.POST_ROUND_DURATION, {
        reason = reason,
        winnerUserId = winnerUserId,
    })
end

function RoundService:_tick()
    local activePlayers = self:GetActivePlayers()
    local activeCount = #activePlayers

    if self.state == "Lobby" then
        if activeCount >= self.gameConfig.MIN_PLAYERS_TO_START then
            self:_setState("Intermission", self.gameConfig.INTERMISSION_DURATION, { reason = "IntermissionStarted" })
        else
            self:_broadcastRoundState({ reason = "WaitingForPlayers" })
        end
        return
    end

    if self.state == "Intermission" then
        if activeCount < self.gameConfig.MIN_PLAYERS_TO_START then
            self:_setState("Lobby", 0, { reason = "WaitingForPlayers" })
            return
        end

        self.timeRemaining -= 1
        if self.timeRemaining <= 0 then
            self:StartRound()
            return
        end

        self:_broadcastRoundState()
        return
    end

    if self.state == "Round" then
        if activeCount == 0 then
            self:_setState("Lobby", 0, { reason = "WaitingForPlayers" })
            return
        end

        if activeCount == 1 then
            self:EndRound("LastPlayerStanding", activePlayers[1] and activePlayers[1].UserId or nil)
            return
        end

        self.timeRemaining -= 1
        if self.timeRemaining <= 0 then
            local winner = self.progressionService:GetLeader(activePlayers)
            self:EndRound("TimeExpired", winner and winner.UserId or nil)
            return
        end

        self:_broadcastRoundState()
        return
    end

    if self.state == "PostRound" then
        self.timeRemaining -= 1
        if self.timeRemaining <= 0 then
            self:_setState("Lobby", 0, { reason = "ReturnToLobby" })
            return
        end

        self:_broadcastRoundState()
    end
end

function RoundService:Start()
    if self._running then
        return
    end

    self._running = true
    self:_setState("Lobby", 0, { reason = "WaitingForPlayers" })

    task.spawn(function()
        while self._running do
            local ok, err = pcall(function()
                self:_tick()
            end)

            if not ok then
                warn("RoundService tick error: " .. tostring(err))
            end

            task.wait(1)
        end
    end)
end

function RoundService:Stop()
    self._running = false
end

return RoundService
