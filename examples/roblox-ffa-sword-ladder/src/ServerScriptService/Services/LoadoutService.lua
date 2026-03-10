local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local LoadoutService = {}
LoadoutService.__index = LoadoutService

local function normalizeName(name)
    return string.lower((name or ""):gsub("[%s_%-]", ""))
end

function LoadoutService.new(gameConfig, swordLadder)
    local self = setmetatable({}, LoadoutService)
    self.gameConfig = gameConfig
    self.swordLadder = swordLadder
    self.swordsFolder = ServerStorage:WaitForChild("Swords")
    self.swordNameSet = {}

    for _, entry in ipairs(swordLadder) do
        self.swordNameSet[entry.toolName] = true
    end

    return self
end

function LoadoutService:_clearSwordTools(player)
    local function clearContainer(container)
        if not container then
            return
        end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and self.swordNameSet[child.Name] then
                child:Destroy()
            end
        end
    end

    clearContainer(player:FindFirstChild("Backpack"))
    clearContainer(player.Character)
end

function LoadoutService:_findSwordTool(toolName)
    local exact = self.swordsFolder:FindFirstChild(toolName)
    if exact and exact:IsA("Tool") then
        return exact
    end

    local target = normalizeName(toolName)
    for _, child in ipairs(self.swordsFolder:GetChildren()) do
        if child:IsA("Tool") and normalizeName(child.Name) == target then
            return child
        end
    end

    return nil
end

function LoadoutService:EquipTierSword(player, tier)
    if not player or not player.Parent then
        return false
    end

    local entry = self.swordLadder[tier + 1]
    if not entry then
        return false
    end

    local sourceTool = self:_findSwordTool(entry.toolName)
    if not sourceTool then
        warn(string.format("Missing sword tool '%s' in ServerStorage/Swords", entry.toolName))
        return false
    end

    self:_clearSwordTools(player)

    local clone = sourceTool:Clone()
    clone.Name = entry.toolName
    clone:SetAttribute("SwordTier", tier)
    clone:SetAttribute("BaseDamage", entry.baseDamage)
    clone:SetAttribute("DamageScale", entry.damageScale)
    clone:SetAttribute("SwingCooldown", entry.swingCooldown)
    clone.Parent = player:WaitForChild("Backpack")

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(clone)
        end
    end

    return true
end

function LoadoutService:RemoveAllSwords(player)
    self:_clearSwordTools(player)
end

function LoadoutService:EquipCurrentTier(player)
    local tier = player:GetAttribute("Tier") or 0
    self:EquipTierSword(player, tier)
end

function LoadoutService:EquipAllActive(players)
    for _, player in ipairs(players or Players:GetPlayers()) do
        if player:GetAttribute("InMatch") then
            self:EquipCurrentTier(player)
        else
            self:RemoveAllSwords(player)
        end
    end
end

return LoadoutService
