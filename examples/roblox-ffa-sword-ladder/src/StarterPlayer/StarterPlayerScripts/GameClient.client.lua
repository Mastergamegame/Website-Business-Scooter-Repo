local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local roundStateChanged = remotes:WaitForChild("RoundStateChanged")
local playerTierChanged = remotes:WaitForChild("PlayerTierChanged")
local requestJoinMatch = remotes:WaitForChild("RequestJoinMatch")
local joinMatchResult = remotes:WaitForChild("JoinMatchResult")
local killFeedEvent = remotes:WaitForChild("KillFeedEvent")
local getServerBrowserData = remotes:WaitForChild("GetServerBrowserData")
local requestServerTeleport = remotes:WaitForChild("RequestServerTeleport")

local NEWLINE = string.char(10)
local leaderboardSlots = {}
local maxSlots = 20

local function formatTime(seconds)
    local s = math.max(0, tonumber(seconds) or 0)
    return string.format("%02d:%02d", math.floor(s / 60), s % 60)
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function animatePress(button)
    local from = button.BackgroundColor3
    local to = Color3.new(math.min(1, from.R + 0.09), math.min(1, from.G + 0.09), math.min(1, from.B + 0.09))
    TweenService:Create(button, TweenInfo.new(0.08), { BackgroundColor3 = to }):Play()
    task.delay(0.09, function()
        if button.Parent then
            TweenService:Create(button, TweenInfo.new(0.14), { BackgroundColor3 = from }):Play()
        end
    end)
end

local gui = make("ScreenGui", {
    Name = "SwordLadderUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
}, localPlayer:WaitForChild("PlayerGui"))

local backdrop = make("Frame", {
    Name = "Backdrop",
    Size = UDim2.fromScale(1, 1),
    BorderSizePixel = 0,
    BackgroundTransparency = 0,
    BackgroundColor3 = Color3.fromRGB(8, 12, 18),
}, gui)

make("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 5, 8)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 30)),
    }),
}, backdrop)

local menuRoot = make("Frame", {
    Name = "MenuRoot",
    Size = UDim2.new(0, 560, 0, 320),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(13, 20, 31),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, menuRoot)
make("UIStroke", { Color = Color3.fromRGB(76, 149, 118), Thickness = 1.5, Transparency = 0.25 }, menuRoot)

local menuScale = make("UIScale", { Scale = 1 }, menuRoot)

make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -30, 0, 52),
    Position = UDim2.new(0, 15, 0, 18),
    Font = Enum.Font.GothamBlack,
    Text = "SWORD LADDER",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(234, 246, 239),
}, menuRoot)

local statusLabel = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -30, 0, 30),
    Position = UDim2.new(0, 15, 0, 70),
    Font = Enum.Font.Gotham,
    Text = "",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(176, 205, 192),
    Visible = false,
}, menuRoot)

local playButton = make("TextButton", {
    Size = UDim2.new(0, 230, 0, 64),
    Position = UDim2.new(0.5, -244, 0, 128),
    BackgroundColor3 = Color3.fromRGB(60, 172, 121),
    BorderSizePixel = 0,
    Text = "PLAY",
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(244, 251, 247),
    AutoButtonColor = false,
}, menuRoot)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, playButton)

local serversButton = make("TextButton", {
    Size = UDim2.new(0, 230, 0, 64),
    Position = UDim2.new(0.5, 14, 0, 128),
    BackgroundColor3 = Color3.fromRGB(44, 87, 139),
    BorderSizePixel = 0,
    Text = "SERVERS",
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(245, 249, 255),
    AutoButtonColor = false,
}, menuRoot)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, serversButton)


local serversModal = make("Frame", {
    Visible = false,
    Size = UDim2.new(0, 620, 0, 340),
    Position = UDim2.new(0.5, -310, 0.5, -170),
    BackgroundColor3 = Color3.fromRGB(12, 19, 31),
    BorderSizePixel = 0,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, serversModal)
make("UIStroke", { Color = Color3.fromRGB(85, 118, 173), Thickness = 1.5, Transparency = 0.3 }, serversModal)

make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -210, 0, 44),
    Position = UDim2.new(0, 12, 0, 8),
    Font = Enum.Font.GothamBold,
    Text = "Server Browser",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(230, 239, 253),
}, serversModal)

local refreshServers = make("TextButton", {
    Size = UDim2.new(0, 90, 0, 28),
    Position = UDim2.new(1, -194, 0, 14),
    BackgroundColor3 = Color3.fromRGB(47, 88, 143),
    BorderSizePixel = 0,
    Text = "Refresh",
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(244, 249, 255),
    AutoButtonColor = false,
}, serversModal)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, refreshServers)

local closeServers = make("TextButton", {
    Size = UDim2.new(0, 90, 0, 28),
    Position = UDim2.new(1, -98, 0, 14),
    BackgroundColor3 = Color3.fromRGB(130, 54, 63),
    BorderSizePixel = 0,
    Text = "Close",
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(255, 246, 248),
    AutoButtonColor = false,
}, serversModal)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, closeServers)

local serverList = make("ScrollingFrame", {
    Size = UDim2.new(1, -16, 1, -60),
    Position = UDim2.new(0, 8, 0, 52),
    BackgroundColor3 = Color3.fromRGB(17, 26, 42),
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 7,
}, serversModal)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, serverList)

local serverLayout = make("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, serverList)

local hudRoot = make("Frame", {
    Name = "HUD",
    Visible = false,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
}, gui)

local topWrap = make("Frame", {
    Size = UDim2.new(0, 320, 0, 44),
    Position = UDim2.new(0.5, -160, 0, 8),
    BackgroundColor3 = Color3.fromRGB(12, 20, 32),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
}, hudRoot)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, topWrap)
make("UIStroke", { Color = Color3.fromRGB(84, 162, 126), Thickness = 1.2, Transparency = 0.25 }, topWrap)

local timerLabel = make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -14, 1, 0),
    Position = UDim2.new(0, 7, 0, 0),
    Font = Enum.Font.GothamBold,
    Text = "00:00",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(239, 249, 245),
}, topWrap)

local leaderboardRow = make("ScrollingFrame", {
    BackgroundColor3 = Color3.fromRGB(12, 20, 32),
    BackgroundTransparency = 0.08,
    Size = UDim2.new(0, 760, 0, 72),
    Position = UDim2.new(0.5, 0, 0, 58),
    AnchorPoint = Vector2.new(0.5, 0),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.X,
    AutomaticCanvasSize = Enum.AutomaticSize.None,
}, hudRoot)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, leaderboardRow)
make("UIStroke", { Color = Color3.fromRGB(84, 162, 126), Thickness = 1.2, Transparency = 0.2 }, leaderboardRow)

local leaderboardLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 4),
}, leaderboardRow)

local infoLabel = make("TextLabel", {
    BackgroundColor3 = Color3.fromRGB(13, 22, 34),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 210, 0, 34),
    Position = UDim2.new(1, -224, 1, -44),
    Font = Enum.Font.Gotham,
    Text = "Tier 0 | Linked Sword",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(231, 242, 250),
}, hudRoot)
make("UICorner", { CornerRadius = UDim.new(0, 9) }, infoLabel)

local deathNotice = make("TextLabel", {
    Visible = false,
    BackgroundColor3 = Color3.fromRGB(108, 46, 46),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 380, 0, 42),
    Position = UDim2.new(0.5, -190, 0.76, 0),
    Font = Enum.Font.GothamBold,
    Text = "",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(255, 244, 244),
}, hudRoot)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, deathNotice)

local resultModal = make("TextLabel", {
    Visible = false,
    Size = UDim2.new(0, 420, 0, 170),
    Position = UDim2.new(0.5, -210, 0.35, 0),
    BackgroundColor3 = Color3.fromRGB(14, 24, 35),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "Round finished",
    TextScaled = true,
    TextColor3 = Color3.fromRGB(242, 249, 246),
}, hudRoot)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, resultModal)

local function updateMenuScale()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local scale = math.clamp(math.min(viewport.X / 1366, viewport.Y / 768), 0.72, 1)
    menuScale.Scale = scale
end

local function findMenuCameraCFrame()
    local camPart = workspace:FindFirstChild("MenuCamera") or workspace:FindFirstChild("LobbyCamera")
    if camPart and camPart:IsA("BasePart") then
        return camPart.CFrame
    end

    local firstSpawn = workspace:FindFirstChild("ArenaSpawns")
    if firstSpawn then
        for _, child in ipairs(firstSpawn:GetChildren()) do
            if child:IsA("BasePart") then
                return CFrame.new(child.Position + Vector3.new(0, 28, 40), child.Position + Vector3.new(0, 2, 0))
            end
        end
    end

    for _, child in ipairs(workspace:GetDescendants()) do
        if child:IsA("SpawnLocation") then
            return CFrame.new(child.Position + Vector3.new(0, 28, 40), child.Position + Vector3.new(0, 2, 0))
        end
    end

    return CFrame.new(0, 42, 65) * CFrame.Angles(math.rad(-18), 0, 0)
end

local function applyMenuCamera(enabled)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    if enabled then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = findMenuCameraCFrame()
        return
    end

    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    camera.CameraType = Enum.CameraType.Custom
    if humanoid then
        camera.CameraSubject = humanoid
    end
end

local function setInMatchUI(inMatch)
    menuRoot.Visible = not inMatch
    hudRoot.Visible = inMatch
    backdrop.Visible = not inMatch
    updateMenuScale()
    applyMenuCamera(not inMatch)
    if not inMatch then
        serversModal.Visible = false
    end
end

local function setStatus(text)
    statusLabel.Text = text
end

local function refreshInfoLabel()
    local tier = localPlayer:GetAttribute("Tier") or 0
    local swordNamesByTier = {
        [0] = "Linked Sword",
        [1] = "Venomshank",
        [2] = "Firebrand",
        [3] = "Ice Dagger",
        [4] = "Ghostwalker",
        [5] = "Illumina",
        [6] = "Darkheart",
    }
    infoLabel.Text = string.format("Tier %d | %s", tier, swordNamesByTier[tier] or "Unknown")
end

local function buildSlot(index)
    local slot = make("Frame", {
        Size = UDim2.new(0, 92, 0, 58),
        BackgroundColor3 = Color3.fromRGB(13, 22, 40),
        BorderSizePixel = 0,
        LayoutOrder = index,
        Visible = false,
    }, leaderboardRow)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, slot)

    local avatar = make("ImageLabel", {
        Size = UDim2.new(1, -4, 1, -18),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
    }, slot)

    local label = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 14),
        Position = UDim2.new(0, 3, 1, -16),
        Font = Enum.Font.GothamBold,
        Text = "0",
        TextScaled = true,
        TextWrapped = false,
        TextColor3 = Color3.fromRGB(240, 244, 255),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, slot)

    return {
        frame = slot,
        avatar = avatar,
        label = label,
    }
end

for i = 1, maxSlots do
    leaderboardSlots[i] = buildSlot(i)
end

local function getKD(player)
    local kills = player:GetAttribute("Kills") or 0
    local deaths = player:GetAttribute("Deaths") or 0
    if deaths <= 0 then
        return kills
    end
    return kills / deaths
end

local function rankedPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(list, p)
    end

    table.sort(list, function(a, b)
        local kda = getKD(a)
        local kdb = getKD(b)
        if kda ~= kdb then
            return kda > kdb
        end

        local ka = a:GetAttribute("Kills") or 0
        local kb = b:GetAttribute("Kills") or 0
        if ka ~= kb then
            return ka > kb
        end

        local da = a:GetAttribute("Deaths") or 0
        local db = b:GetAttribute("Deaths") or 0
        if da ~= db then
            return da < db
        end

        return a.UserId < b.UserId
    end)

    return list
end

local thumbCache = {}
local function getThumb(userId)
    local cached = thumbCache[userId]
    if cached then
        return cached
    end

    local thumb
    local ok, content, ready = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    if ok and ready and type(content) == "string" and content ~= "" then
        thumb = content
    else
        thumb = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", userId)
    end

    thumbCache[userId] = thumb
    return thumb
end

local function updateLeaderboardLayout(playerCount)
    local visibleSlots = math.clamp(playerCount, 0, maxSlots)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    local maxWidth = math.clamp(math.floor(viewport.X * 0.9), 320, 1120)
    local height = 72
    local spacing = 4

    local slotWidth = 92
    if visibleSlots > 0 then
        local available = math.max(120, maxWidth - 8)
        local fitWidth = math.floor((available - ((visibleSlots - 1) * spacing)) / visibleSlots)
        slotWidth = math.clamp(fitWidth, 76, 112)
    end

    local contentWidth = 8
    if visibleSlots > 0 then
        contentWidth = (visibleSlots * slotWidth) + ((visibleSlots - 1) * spacing) + 8
    end

    local width = math.clamp(contentWidth + 8, 120, maxWidth)

    leaderboardLayout.HorizontalAlignment = contentWidth <= width and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left

    for i = 1, maxSlots do
        local slot = leaderboardSlots[i]
        if slot and slot.frame then
            slot.frame.Size = UDim2.new(0, slotWidth, 0, 58)
        end
    end

    leaderboardRow.Visible = visibleSlots > 0
    leaderboardRow.Size = UDim2.new(0, width, 0, height)
    leaderboardRow.Position = UDim2.new(0.5, 0, 0, 58)
    leaderboardRow.CanvasSize = UDim2.new(0, math.max(contentWidth, width), 0, 0)
    if contentWidth <= width then
        leaderboardRow.CanvasPosition = Vector2.new(0, 0)
    end
end

local function renderLeaderboard()
    local ranked = rankedPlayers()
    updateLeaderboardLayout(#ranked)

    for i = 1, maxSlots do
        local slot = leaderboardSlots[i]
        local p = ranked[i]
        if p then
            slot.frame.Visible = true
            slot.avatar.Image = getThumb(p.UserId)

            local kills = p:GetAttribute("Kills") or 0
            slot.label.Text = string.format("%d  K:%d", i, kills)
        else
            slot.frame.Visible = false
        end
    end
end

local function clearServerRows()
    for _, c in ipairs(serverList:GetChildren()) do
        if c:IsA("Frame") then
            c:Destroy()
        end
    end
end

local function renderServers(servers)
    clearServerRows()

    if #servers == 0 then
        local row = make("Frame", {
            Size = UDim2.new(1, -12, 0, 36),
            BackgroundColor3 = Color3.fromRGB(30, 40, 58),
            BorderSizePixel = 0,
        }, serverList)
        make("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 5, 0, 0),
            Font = Enum.Font.Gotham,
            Text = "No available servers",
            TextScaled = true,
            TextColor3 = Color3.fromRGB(210, 218, 231),
        }, row)
    end

    for _, entry in ipairs(servers) do
        local row = make("Frame", {
            Size = UDim2.new(1, -12, 0, 42),
            BackgroundColor3 = Color3.fromRGB(24, 35, 52),
            BorderSizePixel = 0,
        }, serverList)
        make("UICorner", { CornerRadius = UDim.new(0, 8) }, row)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.format("%d/%d players", entry.playerCount or 0, entry.maxPlayers or 0),
            TextScaled = true,
            TextColor3 = Color3.fromRGB(229, 236, 248),
        }, row)

        local joinButton = make("TextButton", {
            Size = UDim2.new(0.26, 0, 0.72, 0),
            Position = UDim2.new(0.72, 0, 0.14, 0),
            BackgroundColor3 = Color3.fromRGB(58, 152, 108),
            BorderSizePixel = 0,
            Text = "Join",
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(245, 251, 248),
            AutoButtonColor = false,
        }, row)
        make("UICorner", { CornerRadius = UDim.new(0, 8) }, joinButton)

        joinButton.Activated:Connect(function()
            animatePress(joinButton)
            setStatus("Teleporting...")
            requestServerTeleport:FireServer({ jobId = entry.jobId })
        end)
    end

    task.wait()
    serverList.CanvasSize = UDim2.new(0, 0, 0, serverLayout.AbsoluteContentSize.Y + 10)
end

local function loadServers()
    setStatus("Loading servers...")
    local ok, result = pcall(function()
        return getServerBrowserData:InvokeServer()
    end)
    if not ok then
        setStatus("Could not load servers")
        renderServers({})
        return
    end

    local servers = result
    if type(result) == "table" and result.servers then
        servers = result.servers
        if result.ok == false then
            setStatus(result.message or "Could not load servers")
        else
            setStatus(result.message or "Server list updated")
        end
    else
        setStatus("Server list updated")
    end

    if type(servers) ~= "table" then
        servers = {}
    end

    renderServers(servers)
end

playButton.Activated:Connect(function()
    animatePress(playButton)
    setStatus("Joining match...")
    requestJoinMatch:FireServer()
end)

serversButton.Activated:Connect(function()
    animatePress(serversButton)
    serversModal.Visible = true
    loadServers()
end)

refreshServers.Activated:Connect(function()
    animatePress(refreshServers)
    loadServers()
end)

closeServers.Activated:Connect(function()
    animatePress(closeServers)
    serversModal.Visible = false
end)

joinMatchResult.OnClientEvent:Connect(function(payload)
    if type(payload) == "table" then
        setStatus(payload.message or "")
    end
end)

roundStateChanged.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    local state = payload.state or "Lobby"
    local t = formatTime(payload.timeRemaining or 0)

    if state == "Lobby" then
        timerLabel.Text = "Waiting for 2 players"
    elseif state == "Intermission" then
        timerLabel.Text = "Start in " .. t
    elseif state == "Round" then
        timerLabel.Text = t
    elseif state == "PostRound" then
        timerLabel.Text = "Next " .. t
    else
        timerLabel.Text = state .. " " .. t
    end

    if state == "PostRound" then
        resultModal.Visible = true
        if payload.winnerUserId then
            local winnerName = tostring(payload.winnerUserId)
            local p = Players:GetPlayerByUserId(payload.winnerUserId)
            if p then
                winnerName = p.DisplayName
            end
            resultModal.Text = string.format("Winner: %s%sReason: %s", winnerName, NEWLINE, payload.reason or "RoundEnd")
        else
            resultModal.Text = "Round ended"
        end
    else
        resultModal.Visible = false
    end
end)

playerTierChanged.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.userId == localPlayer.UserId then
        localPlayer:SetAttribute("Tier", payload.tier)
        refreshInfoLabel()
    end
end)

killFeedEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.victimUserId == localPlayer.UserId then
        local killer = payload.killerName or "Unknown"
        local dist = payload.distanceStuds
        if dist then
            deathNotice.Text = string.format("Killed by %s from %d studs", killer, dist)
        else
            deathNotice.Text = string.format("Killed by %s", killer)
        end
        deathNotice.Visible = true
        task.delay(3, function()
            if deathNotice.Parent then
                deathNotice.Visible = false
            end
        end)
    end
end)

localPlayer:GetAttributeChangedSignal("InMatch"):Connect(function()
    setInMatchUI(localPlayer:GetAttribute("InMatch") == true)
end)

localPlayer:GetAttributeChangedSignal("Tier"):Connect(refreshInfoLabel)

localPlayer.CharacterAdded:Connect(function()
    task.defer(function()
        setInMatchUI(localPlayer:GetAttribute("InMatch") == true)
    end)
end)

task.spawn(function()
    while gui.Parent do
        updateMenuScale()
        renderLeaderboard()
        task.wait(1)
    end
end)

setInMatchUI(localPlayer:GetAttribute("InMatch") == true)
refreshInfoLabel()
renderLeaderboard()

