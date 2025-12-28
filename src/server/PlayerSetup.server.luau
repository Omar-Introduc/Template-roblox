-- src/server/PlayerSetup.server.luau
local Players = game:GetService("Players")

local function onPlayerAdded(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local cr = Instance.new("IntValue")
    cr.Name = "CR"
    cr.Value = 0
    cr.Parent = leaderstats
    
    print("✅ Stats iniciados para: " .. player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Manejar jugadores que ya estén conectados (si el script arranca tarde)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
