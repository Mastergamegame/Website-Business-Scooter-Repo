local Workspace = game:GetService("Workspace")

local SpawnService = {}
SpawnService.__index = SpawnService

local function isSpawnBaseplate(part)
    if not part:IsA("BasePart") then
        return false
    end
    local n = string.lower(part.Name)
    return string.find(n, "baseplate", 1, true) ~= nil
end

function SpawnService.new(gameConfig)
    local self = setmetatable({}, SpawnService)
    self.lastSpawnByUserId = {}
    self.gameConfig = gameConfig
    self.teleportGraceSeconds = (gameConfig and gameConfig.ANTI_EXPLOIT_TELEPORT_GRACE_SECONDS) or 1.25
    return self
end

function SpawnService:_getSpawnParts()
    local explicitFolder = Workspace:FindFirstChild("ArenaSpawns")
    local folderSpawns = {}
    if explicitFolder then
        for _, item in ipairs(explicitFolder:GetChildren()) do
            if item:IsA("BasePart") then
                table.insert(folderSpawns, item)
            end
        end
    end
    if #folderSpawns > 0 then
        return folderSpawns
    end

    local spawnLocations = {}
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("SpawnLocation") then
            table.insert(spawnLocations, item)
        end
    end
    if #spawnLocations > 0 then
        return spawnLocations
    end

    local baseplates = {}
    for _, item in ipairs(Workspace:GetDescendants()) do
        if isSpawnBaseplate(item) then
            table.insert(baseplates, item)
        end
    end

    return baseplates
end

function SpawnService:AssignSpawn(player)
    local spawnParts = self:_getSpawnParts()
    if #spawnParts == 0 then
        warn("SpawnService: no spawn parts found. Add SpawnLocations or ArenaSpawns folder.")
        return nil
    end

    local selected = spawnParts[math.random(1, #spawnParts)]

    local lastName = self.lastSpawnByUserId[player.UserId]
    if #spawnParts > 1 and lastName and selected.Name == lastName then
        local attempts = 0
        while attempts < 4 and selected.Name == lastName do
            selected = spawnParts[math.random(1, #spawnParts)]
            attempts += 1
        end
    end

    self.lastSpawnByUserId[player.UserId] = selected.Name
    local yOffset = (selected.Size and selected.Size.Y * 0.5 or 2) + 4
    return selected.CFrame + Vector3.new(0, yOffset, 0)
end

function SpawnService:TeleportCharacterToSpawn(player)
    local character = player.Character
    if not character then
        return
    end

    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not root then
        return
    end

    local target = self:AssignSpawn(player)
    if target then
        player:SetAttribute("ServerTeleportGraceUntil", os.clock() + self.teleportGraceSeconds)
        character:PivotTo(target)
    end
end

return SpawnService
