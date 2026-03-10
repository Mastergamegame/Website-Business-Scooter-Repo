local Players = game:GetService("Players")

local ProgressionService = {}
ProgressionService.__index = ProgressionService

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function ensureLeaderstats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local kills = leaderstats:FindFirstChild("Kills")
    if not kills then
        kills = Instance.new("IntValue")
        kills.Name = "Kills"
        kills.Parent = leaderstats
    end

    local tier = leaderstats:FindFirstChild("Tier")
    if not tier then
        tier = Instance.new("IntValue")
        tier.Name = "Tier"
        tier.Parent = leaderstats
    end

    local deaths = leaderstats:FindFirstChild("Deaths")
    if not deaths then
        deaths = Instance.new("IntValue")
        deaths.Name = "Deaths"
        deaths.Parent = leaderstats
    end

    return leaderstats
end

function ProgressionService.new(gameConfig, swordLadder, loadoutService, remotes)
    local self = setmetatable({}, ProgressionService)
    self.gameConfig = gameConfig
    self.swordLadder = swordLadder
    self.loadoutService = loadoutService
    self.remotes = remotes
    self.roundStamp = os.clock()
    self.playerData = {}
    return self
end

function ProgressionService:ResetRoundStamp()
    self.roundStamp = os.clock()
end

function ProgressionService:_now()
    return os.clock() - self.roundStamp
end

function ProgressionService:InitPlayer(player)
    ensureLeaderstats(player)
    self.playerData[player] = {
        tierReachedAt = {},
    }

    player:SetAttribute("Tier", 0)
    player:SetAttribute("Kills", 0)
    player:SetAttribute("Deaths", 0)
    player:SetAttribute("Streak", 0)
    if player:GetAttribute("InMatch") == nil then
        player:SetAttribute("InMatch", false)
    end

    self:SetTier(player, 0)
    self:_syncStats(player)
end

function ProgressionService:CleanupPlayer(player)
    self.playerData[player] = nil
end

function ProgressionService:_syncStats(player)
    local leaderstats = ensureLeaderstats(player)
    leaderstats.Kills.Value = player:GetAttribute("Kills") or 0
    leaderstats.Deaths.Value = player:GetAttribute("Deaths") or 0
    leaderstats.Tier.Value = player:GetAttribute("Tier") or 0
end

function ProgressionService:SetTier(player, tier)
    if not player or not player.Parent then
        return 0
    end

    local clamped = clamp(tier, 0, self.gameConfig.MAX_TIER)
    player:SetAttribute("Tier", clamped)

    local pdata = self.playerData[player]
    if pdata then
        pdata.tierReachedAt[clamped] = self:_now()
    end

    self:_syncStats(player)

    local entry = self.swordLadder[clamped + 1]
    self.remotes.PlayerTierChanged:FireAllClients({
        userId = player.UserId,
        tier = clamped,
        swordName = entry and entry.toolName or "Unknown",
    })

    if player:GetAttribute("InMatch") then
        self.loadoutService:EquipTierSword(player, clamped)
    else
        self.loadoutService:RemoveAllSwords(player)
    end

    return clamped
end

function ProgressionService:OnDeath(player)
    if not player or not player.Parent then
        return
    end

    local deaths = (player:GetAttribute("Deaths") or 0) + 1
    player:SetAttribute("Deaths", deaths)
    player:SetAttribute("Streak", 0)

    local currentTier = player:GetAttribute("Tier") or 0
    local penalty = self.gameConfig.ENABLE_DEATH_TIER_LOSS and (self.gameConfig.DEATH_TIER_PENALTY or 1) or 0
    if penalty > 0 then
        self:SetTier(player, currentTier - penalty)
    else
        self:_syncStats(player)
    end
end

function ProgressionService:OnKill(killer, victim)
    if not killer or not killer.Parent then
        return { won = false }
    end
    if not victim or not victim.Parent then
        return { won = false }
    end
    if killer == victim then
        return { won = false }
    end

    local preTier = killer:GetAttribute("Tier") or 0
    local kills = (killer:GetAttribute("Kills") or 0) + 1
    local streak = (killer:GetAttribute("Streak") or 0) + 1
    killer:SetAttribute("Kills", kills)
    killer:SetAttribute("Streak", streak)

    local won = preTier >= self.gameConfig.MAX_TIER
    if not won then
        self:SetTier(killer, preTier + 1)
    else
        self:SetTier(killer, preTier)
    end

    self:_syncStats(killer)
    return { won = won }
end

function ProgressionService:GetRankedPlayers(players)
    local ranked = {}

    for _, player in ipairs(players or Players:GetPlayers()) do
        if player:GetAttribute("InMatch") then
            table.insert(ranked, player)
        end
    end

    table.sort(ranked, function(a, b)
        local tierA = a:GetAttribute("Tier") or 0
        local tierB = b:GetAttribute("Tier") or 0
        if tierA ~= tierB then
            return tierA > tierB
        end

        local killsA = a:GetAttribute("Kills") or 0
        local killsB = b:GetAttribute("Kills") or 0
        if killsA ~= killsB then
            return killsA > killsB
        end

        local deathsA = a:GetAttribute("Deaths") or 0
        local deathsB = b:GetAttribute("Deaths") or 0
        if deathsA ~= deathsB then
            return deathsA < deathsB
        end

        local dataA = self.playerData[a]
        local dataB = self.playerData[b]
        local reachedA = dataA and dataA.tierReachedAt[tierA] or math.huge
        local reachedB = dataB and dataB.tierReachedAt[tierB] or math.huge
        if reachedA ~= reachedB then
            return reachedA < reachedB
        end

        return a.UserId < b.UserId
    end)

    return ranked
end

function ProgressionService:GetLeader(players)
    local ranked = self:GetRankedPlayers(players)
    return ranked[1]
end

function ProgressionService:ResetForRound(players)
    self:ResetRoundStamp()
    for _, player in ipairs(players or Players:GetPlayers()) do
        if player:GetAttribute("InMatch") then
            local pdata = self.playerData[player]
            if pdata then
                pdata.tierReachedAt = {}
            end

            player:SetAttribute("Kills", 0)
            player:SetAttribute("Deaths", 0)
            player:SetAttribute("Streak", 0)
            self:SetTier(player, 0)
            self:_syncStats(player)
        end
    end
end

return ProgressionService

