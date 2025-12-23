-- ShopService (Server)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ItemsData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemsData"))

-- Setup Remotes
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local purchaseEvent = Instance.new("RemoteEvent")
purchaseEvent.Name = "PurchaseItem"
purchaseEvent.Parent = remotes

local function applySpeed(humanoid, value, duration)
	local _originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = value
	task.wait(duration)
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = 16 -- Standard
	end
end

local function applyJump(humanoid, value, duration)
	local _originalJump = humanoid.JumpPower
	humanoid.UseJumpPower = true
	humanoid.JumpPower = value
	task.wait(duration)
	if humanoid and humanoid.Parent then
		humanoid.JumpPower = 50 -- Standard
	end
end

purchaseEvent.OnServerEvent:Connect(function(player, itemId)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	
	local gems = ls:FindFirstChild("Gems")
	if not gems then return end
	
	local item = nil
	for _, p in ipairs(ItemsData.Powerups) do
		if p.Id == itemId then
			item = p
			break
		end
	end
	
	if item and gems.Value >= item.Price then
		-- Deduct Gems
		gems.Value -= item.Price
		print("🛒 [SHOP] " .. player.Name .. " bought " .. item.Name)
		
		-- Feedback Sound
		local sound = Instance.new("Sound", player.Character:FindFirstChild("HumanoidRootPart") or Workspace)
		sound.SoundId = "rbxassetid://131102685" -- Success sound
		sound.Volume = 0.5
		sound.PlayOnRemove = true
		sound:Play()
		sound:Destroy()

		-- Apply Effects
		local char = player.Character
		if not char then return end
		local humanoid = char:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		if item.Id == "SpeedCoil" then
			task.spawn(applySpeed, humanoid, item.Value, item.Duration)
		elseif item.Id == "GravityBoots" then
			task.spawn(applyJump, humanoid, item.Value, item.Duration)
		elseif item.Id == "CheckpointSave" then
			player:SetAttribute("HasGhostCheckpoint", true)
		elseif item.Id == "PinguinoNavideño" then
			task.spawn(function()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local attachment0 = Instance.new("Attachment", hrp)
				attachment0.Position = Vector3.new(0, -1, 0)
				local attachment1 = Instance.new("Attachment", hrp)
				attachment1.Position = Vector3.new(0, -1.1, 0)

				local trail = Instance.new("Trail")
				trail.Name = "PenguinTrail"
				trail.Attachment0 = attachment0
				trail.Attachment1 = attachment1
				trail.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
				trail.Lifetime = 0.5
				trail.Transparency = NumberSequence.new(0.3, 1)
				trail.WidthScale = NumberSequence.new(1, 0)
				trail.Parent = hrp

				applySpeed(humanoid, item.Value, item.Duration)
				
				if trail then trail:Destroy() end
				if attachment0 then attachment0:Destroy() end
				if attachment1 then attachment1:Destroy() end
			end)
		end
	else
		-- Optional: Send a fail message to client
		warn("❌ [SHOP] " .. player.Name .. " failed to buy " .. itemId .. " (Insufficient Gems)")
		
		local failSound = Instance.new("Sound", player.Character:FindFirstChild("HumanoidRootPart") or Workspace)
		failSound.SoundId = "rbxassetid://5843105785" -- Fail/Error sound
		failSound.Volume = 0.5
		failSound.PlayOnRemove = true
		failSound:Play()
		failSound:Destroy()
	end
end)

print("🛍️ ShopService: Active.")
