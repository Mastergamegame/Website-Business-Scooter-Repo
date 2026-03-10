local Workspace = game:GetService("Workspace")

local generated = Workspace:FindFirstChild("ArenaGenerated")
if generated then
    generated:Destroy()
end

local spawnsFolder = Workspace:FindFirstChild("ArenaSpawns")
if spawnsFolder and spawnsFolder:IsA("Folder") then
    local onlyGeneratedSpawns = true
    for _, child in ipairs(spawnsFolder:GetChildren()) do
        if not child.Name:match("^Spawn_%d+$") then
            onlyGeneratedSpawns = false
            break
        end
    end

    if onlyGeneratedSpawns then
        spawnsFolder:Destroy()
    end
end

script:Destroy()
