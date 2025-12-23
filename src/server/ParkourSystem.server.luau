local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Wait for Factory
local Templates = ServerStorage:WaitForChild("Templates")
Templates:WaitForChild("FactoryReady")

-- 1. Modular Spiral Level Layout (Revised Colors for consistency)
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(50, 30, 10), Name = "Level1" },
	{ Position = Vector3.new(0, 60, 20), Name = "Level2" },
	{ Position = Vector3.new(-50, 90, 30), Name = "Level3" },
	{ Position = Vector3.new(0, 120, 40), Name = "Level4" },
}

-- 2. Dynamic Difficulty System
local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 8, MaxDist = 12, Variance = 2.8, Time = 5 },   -- Easy
	[2] = { MinDist = 10, MaxDist = 14, Variance = 4.2, Time = 4.5 }, -- Medium
	[3] = { MinDist = 12, MaxDist = 16, Variance = 5.6, Time = 4 },   -- Hard
	[4] = { MinDist = 14, MaxDist = 17, Variance = 7.0, Time = 3 },  -- Extreme
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

local function animateBlockAppearance(block)
	local finalSize = block.Size
	local finalTransparency = block.Transparency
	
	block.Size = Vector3.new(0, 0, 0)
	block.Transparency = 1
	
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(block, tweenInfo, {
		Size = finalSize,
		Transparency = finalTransparency
	})
	
	tween:Play()
end

local function createCountdown(block, duration)
	local surfaceGui = block:WaitForChild("TimerGui", 5)
	if not surfaceGui then return end

	local label = surfaceGui:WaitForChild("TimerLabel", 5)
	if not label then return end

	label.Text = string.format("%.1f", duration)
	label.TextColor3 = Color3.new(1, 1, 1)

	task.spawn(function()
		local remaining = duration
		while remaining > 0 do
			if not block.Parent then break end
			label.Text = string.format("%.1f", remaining)

			-- Color Change Logic
			if remaining <= 1 then
				label.TextColor3 = Color3.fromRGB(255, 0, 0) -- Bright Red
				-- Fast Blinking
				label.Visible = not label.Visible
			elseif remaining <= 2 then
				label.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
				label.Visible = true
			else
				label.TextColor3 = Color3.new(1, 1, 1) -- White
				label.Visible = true
			end

			-- Pulse Effect (Grow/Shrink every 0.5s or on tick)
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
			remaining -= 0.1
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

	local lookAtPoint = Vector3.new(targetPos.X, finalPos.Y, targetPos.Z)
	block.CFrame = CFrame.lookAt(finalPos, lookAtPoint)

	block.Parent = Workspace
	
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

local function onCharacterAdded(player, char)
	cleanupPlayerPath(player)

	local levelIndex = playerProgress[player] or 0
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

