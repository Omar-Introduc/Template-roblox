-- Analytics & Progression Monitor (Server-side)
local Players = game:GetService("Players")

print("📊 Analytics Server: Active.")

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("Stage"):Connect(function()
		local stage = player:GetAttribute("Stage") or 0
		print(string.format("📈 [PROGRESS] Player %s unlocked Level %d", player.Name, stage))
	end)
end)
