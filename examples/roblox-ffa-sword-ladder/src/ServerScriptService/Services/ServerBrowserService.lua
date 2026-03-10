local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local ServerBrowserService = {}
ServerBrowserService.__index = ServerBrowserService

function ServerBrowserService.new(gameConfig)
    local self = setmetatable({}, ServerBrowserService)
    self.gameConfig = gameConfig
    self.placeId = game.PlaceId
    self.serverKey = (game.JobId and game.JobId ~= "") and game.JobId or ("studio-" .. HttpService:GenerateGUID(false))
    self.lastFetchByUserId = {}
    self.lastTeleportByUserId = {}
    self.registryName = string.format("FFA_ServerRegistry_v1_%d", self.placeId)
    self.serverMap = nil
    self._running = false

    local ok, map = pcall(function()
        return MemoryStoreService:GetSortedMap(self.registryName)
    end)
    if ok then
        self.serverMap = map
    else
        warn("ServerBrowserService: failed to initialize MemoryStore map: " .. tostring(map))
    end

    return self
end

function ServerBrowserService:_checkRateLimit(bucket, userId, seconds)
    local now = os.clock()
    local last = bucket[userId]
    if last and now - last < seconds then
        return false
    end

    bucket[userId] = now
    return true
end

function ServerBrowserService:_makeRecord()
    return {
        jobId = self.serverKey,
        placeId = self.placeId,
        playerCount = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
        pingEstimate = nil,
        updatedAt = os.time(),
    }
end

function ServerBrowserService:_publishSelf()
    if not self.serverMap then
        return false, "Registry unavailable"
    end

    local record = self:_makeRecord()
    local ok, err = pcall(function()
        self.serverMap:SetAsync(
            record.jobId,
            record,
            self.gameConfig.SERVER_REGISTRY_TTL_SECONDS,
            record.playerCount
        )
    end)

    if not ok then
        return false, tostring(err)
    end

    return true
end

function ServerBrowserService:Start()
    if self._running then
        return
    end

    self._running = true
    self:_publishSelf()

    task.spawn(function()
        while self._running do
            local ok, err = self:_publishSelf()
            if not ok then
                warn("ServerBrowserService publish failed: " .. tostring(err))
            end
            task.wait(self.gameConfig.SERVER_REGISTRY_HEARTBEAT_SECONDS)
        end
    end)
end

function ServerBrowserService:Stop()
    self._running = false

    if self.serverMap then
        pcall(function()
            self.serverMap:RemoveAsync(self.serverKey)
        end)
    end
end

function ServerBrowserService:_getRange(limit)
    if not self.serverMap then
        return false, "Registry unavailable"
    end

    local ok, result = pcall(function()
        return self.serverMap:GetRangeAsync(Enum.SortDirection.Descending, limit)
    end)
    if ok then
        return true, result
    end

    local fallbackOk, fallbackResult = pcall(function()
        return self.serverMap:GetRangeAsync("Descending", limit)
    end)
    if fallbackOk then
        return true, fallbackResult
    end

    return false, tostring(result)
end

function ServerBrowserService:_getServerRecord(jobId)
    if not self.serverMap then
        return false, nil, "Registry unavailable"
    end

    local ok, value = pcall(function()
        return self.serverMap:GetAsync(jobId)
    end)

    if not ok then
        return false, nil, tostring(value)
    end

    return true, value, nil
end

function ServerBrowserService:GetServerList(requestingPlayer)
    if requestingPlayer then
        local ok = self:_checkRateLimit(
            self.lastFetchByUserId,
            requestingPlayer.UserId,
            self.gameConfig.SERVER_BROWSER_RATE_LIMIT_SECONDS
        )
        if not ok then
            return {
                ok = false,
                source = "MemoryStore",
                servers = {},
                message = "Rate limited, wait a moment.",
                errorCode = "RateLimited",
            }
        end
    end

    local ok, entriesOrErr = self:_getRange(self.gameConfig.SERVER_LIST_MAX_RESULTS)
    if not ok then
        return {
            ok = false,
            source = "MemoryStore",
            servers = {},
            message = "Server list unavailable.",
            errorCode = "RegistryReadFailed",
            detail = entriesOrErr,
        }
    end

    local servers = {}
    local now = os.time()

    for _, entry in ipairs(entriesOrErr or {}) do
        local value = entry and entry.value
        if type(value) == "table" then
            local updatedAt = tonumber(value.updatedAt) or 0
            local isFresh = (now - updatedAt) <= (self.gameConfig.SERVER_REGISTRY_TTL_SECONDS + 2)
            local samePlace = value.placeId == self.placeId
            local notCurrent = value.jobId ~= self.serverKey
            local hasSpace = (tonumber(value.playerCount) or 0) < (tonumber(value.maxPlayers) or 0)

            if samePlace and notCurrent and hasSpace and isFresh then
                table.insert(servers, {
                    jobId = tostring(value.jobId),
                    playerCount = tonumber(value.playerCount) or 0,
                    maxPlayers = tonumber(value.maxPlayers) or Players.MaxPlayers,
                    pingEstimate = value.pingEstimate,
                    updatedAt = updatedAt,
                })
            end
        end
    end

    return {
        ok = true,
        source = "MemoryStore",
        servers = servers,
        message = #servers > 0 and "Server list updated" or "No available servers right now.",
    }
end

function ServerBrowserService:TeleportToServer(player, jobId)
    if typeof(jobId) ~= "string" or jobId == "" then
        return false, "Invalid job id"
    end

    if jobId == self.serverKey then
        return false, "Already in this server"
    end

    if string.sub(jobId, 1, 7) == "studio-" then
        return false, "Target server unavailable"
    end

    local ok = self:_checkRateLimit(
        self.lastTeleportByUserId,
        player.UserId,
        self.gameConfig.TELEPORT_RATE_LIMIT_SECONDS
    )
    if not ok then
        return false, "Teleport rate limited"
    end

    local fetchOk, record, fetchErr = self:_getServerRecord(jobId)
    if not fetchOk then
        return false, "Registry read failed: " .. tostring(fetchErr)
    end

    if type(record) ~= "table" then
        return false, "Target server unavailable"
    end

    if record.placeId ~= self.placeId then
        return false, "Invalid target place"
    end

    local updatedAt = tonumber(record.updatedAt) or 0
    local isFresh = (os.time() - updatedAt) <= (self.gameConfig.SERVER_REGISTRY_TTL_SECONDS + 2)
    if not isFresh then
        return false, "Target server expired"
    end

    local playerCount = tonumber(record.playerCount) or 0
    local maxPlayers = tonumber(record.maxPlayers) or Players.MaxPlayers
    if playerCount >= maxPlayers then
        return false, "Target server is full"
    end

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(self.placeId, jobId, player)
    end)

    if not success then
        return false, tostring(err)
    end

    return true
end

return ServerBrowserService

