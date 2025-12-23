local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local _Debris = game:GetService("Debris")
local _CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Wait for Factory
local Templates = ServerStorage:WaitForChild("Templates")
Templates:WaitForChild("FactoryReady")

-- 1. Modular Spiral Level Layout (Revised Colors for consistency)
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(200, 70, 0), Name = "Level1" },
	{ Position = Vector3.new(0, 140, 200), Name = "Level2" },
	{ Position = Vector3.new(-200, 210, 0), Name = "Level3" },
	{ Position = Vector3.new(0, 280, -200), Name = "Level4" },
}

local _LOBBY_RADIUS = 45 -- Detection radius for leaving the new lobby

-- 2. Dynamic Difficulty System
local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 12, MaxDist = 15, Variance = 3.5, Time = 5 },   -- Challenging Start
	[2] = { MinDist = 14, MaxDist = 17, Variance = 5.0, Time = 4.5 }, 
	[3] = { MinDist = 15, MaxDist = 18, Variance = 6.5, Time = 4 },   
	[4] = { MinDist = 16, MaxDist = 19, Variance = 8.0, Time = 3.5 }, -- Near-limit jumps
}

local ATMOSPHERE_COLORS = {
	[1] = Color3.fromRGB(150, 255, 180),
	[2] = Color3.fromRGB(130, 180, 255),
	[3] = Color3.fromRGB(255, 100, 50),
	[4] = Color3.fromRGB(150, 50, 255),
}

-- State
local playerPaths = {} -- player -> { LastBlock = Part, AllBlocks = {Part, ...} }
local playerProgress = {} -- player -> Highest Level Index Reached
local levelParts = {} -- levelIndex -> Part

-- Forward declarations
local spawnNextBlock
local setupBlockEvents
local startPath
local cleanupPlayerPath

--------------------------------------------------------------------------------
-- VISUALS: Animations & Countdown
--------------------------------------------------------------------------------

local function applyRewards(player, stage)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Level 2: WalkSpeed
	if stage >= 2 then
		humanoid.WalkSpeed = 20
	end

	-- Level 4: Particles
	if stage >= 4 then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("EliteEffect") then
			local particles = Instance.new("ParticleEmitter")
			particles.Name = "EliteEffect"
			particles.Texture = "rbxassetid://585426142" -- Stars
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold
			particles.Size = NumberSequence.new(0.5, 0)
			particles.Lifetime = NumberRange.new(0.5, 1)
			particles.Rate = 20
			particles.Speed = NumberRange.new(2, 5)
			particles.Parent = hrp
		end
	end

	-- Level-based Trail
	if stage > 0 then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp:ClearAllChildren() -- Reset effects on spawn/stage change (be careful with other items)
			-- Re-apply level 4 if needed
			if stage >= 4 then
				-- Redo particles if we cleared them
			end
			
			local attachment0 = Instance.new("Attachment", hrp)
			attachment0.Position = Vector3.new(0, 1, 0)
			local attachment1 = Instance.new("Attachment", hrp)
			attachment1.Position = Vector3.new(0, -1, 0)
			
			local trail = Instance.new("Trail")
			trail.Attachment0 = attachment0
			trail.Attachment1 = attachment1
			trail.Lifetime = 0.5
			trail.Transparency = NumberSequence.new(0.2, 1)
			
			local _config = LEVEL_CONFIGS[stage]
			local color = Color3.fromRGB(255,255,255)
			if stage == 1 then color = Color3.fromRGB(0, 255, 100)
			elseif stage == 2 then color = Color3.fromRGB(0, 150, 255)
			elseif stage == 3 then color = Color3.fromRGB(255, 80, 0)
			elseif stage == 4 then color = Color3.fromRGB(180, 0, 255) end
			
			trail.Color = ColorSequence.new(color)
			trail.Parent = hrp
		end
	end
end

local function animateBlockAppearance(block)
	local finalSize = block.Size
	local finalTransparency = block.Transparency
	block.Size = Vector3.new(0, 0, 0)
	block.Transparency = 1
	
	local tween = TweenService:Create(block, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = finalSize,
		Transparency = finalTransparency
	})
	tween:Play()
	
	-- Burst Particles on Arrival
	tween.Completed:Connect(function()
		local particles = block:FindFirstChild("BiomeEffect")
		if particles then
			particles:Emit(30)
		end
	end)
end

local function createCountdown(block, duration)
	local surfaceGui = block:WaitForChild("TimerGui", 5)
	if not surfaceGui then return end

	local label = surfaceGui:WaitForChild("TimerLabel", 5)
	if not label then return end

	label.Text = string.format("%.1f", duration)
	label.TextColor3 = Color3.new(1, 1, 1)

	-- Store time as an attribute to allow external modification
	block:SetAttribute("RemainingTime", duration)

	task.spawn(function()
		while true do
			local remaining = block:GetAttribute("RemainingTime") or 0
			if remaining <= 0 or not block.Parent then break end
			
			label.Text = string.format("%.1f", remaining)

			-- Color Change Logic
			if remaining <= 1 then
				label.TextColor3 = Color3.fromRGB(255, 0, 0) -- Bright Red
				label.Visible = not label.Visible
			elseif remaining <= 2 then
				label.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
				label.Visible = true
			else
				label.TextColor3 = Color3.new(1, 1, 1) -- White
				label.Visible = true
			end

			-- Vibration Effect (Low Time Shake)
			if remaining <= 1.5 then
				local shakeOffset = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.05, 0.5 + (math.random() - 0.5) * 0.05)
				label.Position = shakeOffset
			else
				label.Position = UDim2.fromScale(0.5, 0.5)
			end

			-- Pulse Effect
			local pulseTween = TweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromScale(1.1, 1.1)
			})
			pulseTween:Play()
			pulseTween.Completed:Connect(function()
				if label and label.Parent then
					TweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Size = UDim2.fromScale(1, 1)
					}):Play()
				end
			end)

			task.wait(0.1)
			block:SetAttribute("RemainingTime", remaining - 0.1)
		end

		if block and block.Parent then
			-- Disintegration Animation
			local disintegrateInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local disintegrateTween = TweenService:Create(block, disintegrateInfo, {
				Size = Vector3.new(0, 0, 0),
				Transparency = 1
			})
			disintegrateTween:Play()
			disintegrateTween.Completed:Connect(function()
				block:Destroy()
			end)
		end
	end)
end

--------------------------------------------------------------------------------
-- CORE LOGIC
--------------------------------------------------------------------------------

function spawnNextBlock(player, currentBlock)
	local currentLevel = playerProgress[player] or 0
	local targetIndex = currentLevel + 1

	if targetIndex > #LEVEL_CONFIGS then
		return nil
	end

	local targetConfig = LEVEL_CONFIGS[targetIndex]
	local diff = DIFFICULTY_SETTINGS[targetIndex] or DIFFICULTY_SETTINGS[1]
	
	-- Get themed folder
	local biomeFolder = Templates:FindFirstChild("Level" .. targetIndex) 
		or Templates:FindFirstChild("Level1") -- Fallback

	local startPos = currentBlock.Position
	local targetPos = targetConfig.Position

	-- 1. Calculate the direct vector (The Invisible Line)
	local vectorToTarget = (targetPos - startPos)
	local distToTarget = vectorToTarget.Magnitude
	local moveDir = vectorToTarget.Unit

	-- 2. Proportional Division
	local jumpDist = math.random(diff.MinDist * 10, diff.MaxDist * 10) / 10

	if distToTarget < jumpDist + 5 then
		jumpDist = distToTarget - 5
		if jumpDist < 5 then jumpDist = 5 end
	end

	local idealPos = startPos + (moveDir * jumpDist)

	-- 3. Offset (Variance)
	local varAmount = diff.Variance
	local offsetX = (math.random() - 0.5) * 2 * varAmount
	local offsetZ = (math.random() - 0.5) * 2 * varAmount

	local finalPos = Vector3.new(idealPos.X + offsetX, idealPos.Y, idealPos.Z + offsetZ)

	-- Create Block from Themed Prefab
	local block = biomeFolder.ParkourBlock:Clone()
	block.Name = "Path_" .. player.Name
	block.Position = finalPos

	-- Position it accurately
	block.Position = finalPos
	block.Parent = Workspace
	
	-- 30% Chance to Spawn a Gem
	if math.random() <= 0.3 then
		local gem = biomeFolder.Gem:Clone()
		gem.Position = finalPos + Vector3.new(0, 4, 0)
		gem.Parent = Workspace
		
		-- Rotation Animation for Gem
		task.spawn(function()
			while gem.Parent do
				gem.CFrame = gem.CFrame * CFrame.Angles(0, math.rad(5), 0)
				task.wait()
			end
		end)

		-- Collection Event
		local collected = false
		gem.Touched:Connect(function(hit)
			if collected then return end
			local p = Players:GetPlayerFromCharacter(hit.Parent)
			if p and p == player then
				collected = true
				
				-- Award Gem
				local ls = p:FindFirstChild("leaderstats")
				if ls then
					local gVal = ls:FindFirstChild("Gems")
					if gVal then gVal.Value += 1 end
				end

				-- Time Bonus for the block
				local currentTime = block:GetAttribute("RemainingTime") or 0
				block:SetAttribute("RemainingTime", currentTime + 0.5)

				-- Visual feedback (Shrink and Destroy)
				TweenService:Create(gem, TweenInfo.new(0.2), {Size = Vector3.new(0,0,0), Transparency = 1}):Play()
				task.wait(0.2)
				gem:Destroy()
			end
		end)
		
		-- Gem remains for max of the block duration or until collected
		game:GetService("Debris"):AddItem(gem, diff.Time + 2)
	end

	-- Animations
	animateBlockAppearance(block)
	createCountdown(block, diff.Time)

	-- Tracking
	if playerPaths[player] then
		table.insert(playerPaths[player].AllBlocks, block)
	end
	
	setupBlockEvents(player, block)

	return block
end

function setupBlockEvents(player, block)
	local triggered = false
	block.Touched:Connect(function(hit)
		if triggered then return end
		if hit.Parent == player.Character then
			local pathData = playerPaths[player]
			if pathData and pathData.LastBlock == block then
				triggered = true
				local nextBlock = spawnNextBlock(player, block)
				if nextBlock then
					pathData.LastBlock = nextBlock
				else
					pathData.LastBlock = nil
				end
			end
		end
	end)
end

function startPath(player, startPad)
	cleanupPlayerPath(player)

	playerPaths[player] = {
		LastBlock = nil,
		AllBlocks = {}
	}

	local firstBlock = spawnNextBlock(player, startPad)

	if firstBlock then
		playerPaths[player].LastBlock = firstBlock
	end
end

--------------------------------------------------------------------------------
-- LEVEL & PAD SETUP
--------------------------------------------------------------------------------

local function createStarterPads()
	local lobbyPart = Workspace:FindFirstChild("Lobby")
	if not lobbyPart then
		lobbyPart = Instance.new("Part")
		lobbyPart.Name = "Lobby"
		lobbyPart.Size = Vector3.new(30, 1, 30)
		lobbyPart.Position = Vector3.new(0, 0, 0)
		lobbyPart.Anchored = true
		lobbyPart.BrickColor = BrickColor.new("Dark stone grey")
		lobbyPart.Material = Enum.Material.Concrete
		lobbyPart.Parent = Workspace
	end

	local function makePad(sourcePart, levelIndexForUnlock)
		local targetLevelIndex = levelIndexForUnlock + 1
		local biomeFolder = Templates:FindFirstChild("Level" .. targetLevelIndex) or Templates:FindFirstChild("Level1")
		
		local targetPos = LEVEL_CONFIGS[targetLevelIndex].Position
		
		local pad = biomeFolder.StarterPad:Clone()
		pad.Name = "StarterPad_Level" .. targetLevelIndex

		local distFromCenter = 0
		if sourcePart.Name:find("Level") then
			distFromCenter = (sourcePart.Size.Y / 2) - 2.5
		else
			distFromCenter = (sourcePart.Size.X / 2) - 2.5
		end

		local dir = (targetPos - sourcePart.Position).Unit

		pad.Position = sourcePart.Position + (dir * distFromCenter) + Vector3.new(0, 0.6, 0)
		pad.CFrame = CFrame.lookAt(pad.Position, Vector3.new(targetPos.X, pad.Position.Y, targetPos.Z))

		pad.Parent = Workspace

		local debounce = false
		pad.Touched:Connect(function(hit)
			if debounce then return end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				local progress = playerProgress[player] or 0
				if progress >= levelIndexForUnlock then
					debounce = true
					startPath(player, pad)
					task.wait(1)
					debounce = false
				end
			end
		end)
	end

	-- 1. Lobby -> Level 1
	makePad(lobbyPart, 0)
	
	-- 2. Level i -> Level i+1
	for i = 1, #LEVEL_CONFIGS - 1 do
		local sourcePart = levelParts[i]
		if sourcePart then
			makePad(sourcePart, i)
		end
	end
end

local function createLevels()
	for i, config in ipairs(LEVEL_CONFIGS) do
		local existing = Workspace:FindFirstChild(config.Name)
		local platform

		if existing then
			platform = existing
			platform.Position = config.Position
		else
			local biomeFolder = Templates:FindFirstChild("Level" .. i)
			platform = biomeFolder.LevelPlatform:Clone()
			platform.Name = config.Name
			platform.Position = config.Position
			platform.Parent = Workspace
		end

		levelParts[i] = platform

		platform.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				if playerPaths[player] then
					playerPaths[player].LastBlock = nil
					cleanupPlayerPath(player)
				end

				local currentProgress = playerProgress[player] or 0
				if i > currentProgress then
					playerProgress[player] = i
					print(player.Name .. " UNLOCKED " .. config.Name)
					
					-- Update Leaderstats
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						local stageVal = ls:FindFirstChild("Stage")
						if stageVal then stageVal.Value = i end
					end
					
					-- Apply immediate rewards
					applyRewards(player, i)
					
					-- Screen Notification
					task.spawn(function()
						local playerGui = player:FindFirstChild("PlayerGui")
						if playerGui then
							local msgLabel = Instance.new("TextLabel")
							msgLabel.Size = UDim2.fromScale(1, 0.2)
							msgLabel.Position = UDim2.fromScale(0, 0.4)
							msgLabel.BackgroundTransparency = 1
							msgLabel.Text = "¡NIVEL " .. i .. " DESBLOQUEADO!"
							msgLabel.TextColor3 = Color3.new(1, 1, 0)
							msgLabel.Font = Enum.Font.GothamBlack
							msgLabel.TextScaled = true
							msgLabel.Parent = playerGui
							
							task.wait(2)
							TweenService:Create(msgLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
							task.wait(0.5)
							msgLabel:Destroy()
						end
					end)
				end
			end
		end)
	end
	
	createStarterPads()
end

--------------------------------------------------------------------------------
-- LIFECYCLE
--------------------------------------------------------------------------------

function cleanupPlayerPath(player)
	if playerPaths[player] then
		for _, b in pairs(playerPaths[player].AllBlocks) do
			if b and b.Parent then b:Destroy() end
		end
	end
	playerPaths[player] = nil
end

-- Atmosphere Management Loop
task.spawn(function()
	local Lighting = game:GetService("Lighting")
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere", Lighting)
	end

	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local stage = playerProgress[player] or 1
				local atmosphereColor = ATMOSPHERE_COLORS[stage]
				if atmosphereColor then
					-- Smooth transition
					TweenService:Create(atmosphere, TweenInfo.new(2), {
						Color = atmosphereColor
					}):Play()
				end
			end
		end
		task.wait(2)
	end
end)

local function onCharacterAdded(player, char)
	cleanupPlayerPath(player)

	local levelIndex = playerProgress[player] or 0
	
	-- Apply rewards based on progress
	applyRewards(player, levelIndex)

	if levelIndex > 0 then
		local levelPart = levelParts[levelIndex]
		if levelPart then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				task.wait(0.1)
				hrp.CFrame = levelPart.CFrame + Vector3.new(0, 3, 0)
			end
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(c) onCharacterAdded(p, c) end)
end)

Players.PlayerRemoving:Connect(function(p)
	cleanupPlayerPath(p)
	playerProgress[p] = nil
end)

createLevels()

