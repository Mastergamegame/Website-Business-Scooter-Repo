local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local configFolder = ReplicatedStorage:WaitForChild("Config")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(configFolder:WaitForChild("GameConfig"))
local SwordLadder = require(configFolder:WaitForChild("SwordLadder"))
local RemoteRegistry = require(sharedFolder:WaitForChild("RemoteRegistry"))

local servicesFolder = script.Parent:WaitForChild("Services")
local LoadoutService = require(servicesFolder:WaitForChild("LoadoutService"))
local ProgressionService = require(servicesFolder:WaitForChild("ProgressionService"))
local SpawnService = require(servicesFolder:WaitForChild("SpawnService"))
local ServerBrowserService = require(servicesFolder:WaitForChild("ServerBrowserService"))
local RoundService = require(servicesFolder:WaitForChild("RoundService"))
local CombatController = require(servicesFolder:WaitForChild("CombatController"))
local AntiExploitService = require(servicesFolder:WaitForChild("AntiExploitService"))

local remotes = RemoteRegistry.EnsureRemotes()

local loadoutService = LoadoutService.new(GameConfig, SwordLadder)
local progressionService = ProgressionService.new(GameConfig, SwordLadder, loadoutService, remotes)
local spawnService = SpawnService.new(GameConfig)
local serverBrowserService = ServerBrowserService.new(GameConfig)

local function loadR6Character(player)
    local okDesc, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(player.UserId)
    end)

    if okDesc and desc then
        local okLoad = pcall(function()
            player:LoadCharacterWithHumanoidDescription(desc, Enum.HumanoidRigType.R6)
        end)
        if okLoad then
            player:SetAttribute("R6LoadFailed", false)
            return true
        end
    end

    player:SetAttribute("R6LoadFailed", true)
    return pcall(function()
        player:LoadCharacter()
    end)
end

local roundService = RoundService.new(GameConfig, progressionService, spawnService, loadoutService, remotes, loadR6Character)
local antiExploitService = AntiExploitService.new(GameConfig, remotes, SwordLadder, spawnService, loadoutService)
local combatController = CombatController.new(GameConfig, roundService, progressionService, remotes, loadR6Character, antiExploitService)

local FORCEFIELD_DURATION_SECONDS = 1.5

local function removeCharacterIfAny(player)
    if player.Character then
        player.Character:Destroy()
    end
end

local function setupCharacterLifecycle(player)
    player.CharacterAdded:Connect(function(character)
        task.delay(FORCEFIELD_DURATION_SECONDS, function()
            if not character or not character.Parent then
                return
            end
            local ff = character:FindFirstChildOfClass("ForceField")
            if ff then
                ff:Destroy()
            end
        end)

        local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if hum and hum.RigType ~= Enum.HumanoidRigType.R6 and player:GetAttribute("InMatch") then
            local retries = (player:GetAttribute("R6RetryCount") or 0) + 1
            player:SetAttribute("R6RetryCount", retries)

            if retries <= 2 and not player:GetAttribute("R6LoadFailed") then
                task.defer(function()
                    if player.Parent and player:GetAttribute("InMatch") then
                        loadR6Character(player)
                    end
                end)
                return
            end
        else
            player:SetAttribute("R6RetryCount", 0)
        end

        if not player:GetAttribute("InMatch") then
            loadoutService:RemoveAllSwords(player)
            return
        end

        task.wait(0.15)

        if roundService:IsRoundActive() then
            spawnService:TeleportCharacterToSpawn(player)
            loadoutService:EquipCurrentTier(player)
        else
            loadoutService:RemoveAllSwords(player)
        end
    end)
end

local function playerAdded(player)
    progressionService:InitPlayer(player)
    combatController:HookPlayer(player)
    antiExploitService:HookPlayer(player)
    setupCharacterLifecycle(player)

    player:SetAttribute("InMatch", false)
    player:SetAttribute("R6RetryCount", 0)
    player:SetAttribute("R6LoadFailed", false)
    loadoutService:RemoveAllSwords(player)
    removeCharacterIfAny(player)

    remotes.JoinMatchResult:FireClient(player, {
        ok = true,
        message = "Ready",
    })

    player:GetAttributeChangedSignal("InMatch"):Connect(function()
        if player:GetAttribute("InMatch") then
            if not player.Character then
                loadR6Character(player)
            end
            roundService:TryStartIntermission()
        else
            loadoutService:RemoveAllSwords(player)
            removeCharacterIfAny(player)
        end
    end)
end

local function playerRemoving(player)
    progressionService:CleanupPlayer(player)
    antiExploitService:UnhookPlayer(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(playerAdded, player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

remotes.RequestJoinMatch.OnServerEvent:Connect(function(player)
    if player:GetAttribute("InMatch") then
        remotes.JoinMatchResult:FireClient(player, {
            ok = true,
            message = "Already in match",
        })
        return
    end

    player:SetAttribute("InMatch", true)

    remotes.JoinMatchResult:FireClient(player, {
        ok = true,
        message = "Joined match",
    })

    roundService:TryStartIntermission()
end)

remotes.GetServerBrowserData.OnServerInvoke = function(player)
    return serverBrowserService:GetServerList(player)
end

remotes.RequestServerTeleport.OnServerEvent:Connect(function(player, payload)
    if type(payload) ~= "table" then
        remotes.JoinMatchResult:FireClient(player, {
            ok = false,
            message = "Invalid teleport payload",
        })
        return
    end

    local success, err = serverBrowserService:TeleportToServer(player, payload.jobId)
    if not success then
        remotes.JoinMatchResult:FireClient(player, {
            ok = false,
            message = "Teleport failed: " .. tostring(err),
        })
    end
end)

roundService:Start()
serverBrowserService:Start()
antiExploitService:Start()

game:BindToClose(function()
    pcall(function()
        roundService:Stop()
    end)
    pcall(function()
        antiExploitService:Stop()
    end)
    pcall(function()
        serverBrowserService:Stop()
    end)
end)

