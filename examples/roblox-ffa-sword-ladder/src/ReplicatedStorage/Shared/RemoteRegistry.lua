local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteRegistry = {}

local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if folder and folder:IsA("Folder") then
        return folder
    end

    local created = Instance.new("Folder")
    created.Name = name
    created.Parent = parent
    return created
end

function RemoteRegistry.EnsureRemotes()
    local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")

    local function ensureRemoteEvent(name)
        local remote = remotesFolder:FindFirstChild(name)
        if not remote then
            remote = Instance.new("RemoteEvent")
            remote.Name = name
            remote.Parent = remotesFolder
        end
        return remote
    end

    local function ensureRemoteFunction(name)
        local remote = remotesFolder:FindFirstChild(name)
        if not remote then
            remote = Instance.new("RemoteFunction")
            remote.Name = name
            remote.Parent = remotesFolder
        end
        return remote
    end

    return {
        RoundStateChanged = ensureRemoteEvent("RoundStateChanged"),
        PlayerTierChanged = ensureRemoteEvent("PlayerTierChanged"),
        RequestServerTeleport = ensureRemoteEvent("RequestServerTeleport"),
        RequestJoinMatch = ensureRemoteEvent("RequestJoinMatch"),
        JoinMatchResult = ensureRemoteEvent("JoinMatchResult"),
        KillFeedEvent = ensureRemoteEvent("KillFeedEvent"),
        AntiExploitIncident = ensureRemoteEvent("AntiExploitIncident"),
        ClientIntegrityReport = ensureRemoteEvent("ClientIntegrityReport"),
        GetServerBrowserData = ensureRemoteFunction("GetServerBrowserData"),
    }
end

return RemoteRegistry
