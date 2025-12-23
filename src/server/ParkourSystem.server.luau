local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

-- Wait for Factory
local Templates = ServerStorage:WaitForChild("Templates")
Templates:WaitForChild("FactoryReady")

-- 1. Modular Spiral Level Layout
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(100, 50, 0), Name = "Level1", Color = BrickColor.new("Bright green") }, -- East
	{ Position = Vector3.new(0, 100, 100), Name = "Level2", Color = BrickColor.new("Bright yellow") }, -- South
	{ Position = Vector3.new(-100, 150, 0), Name = "Level3", Color = BrickColor.new("Bright orange") }, -- West
	{ Position = Vector3.new(0, 200, -100), Name = "Level4", Color = BrickColor.new("Bright red") }, -- North
}

-- 2. Dynamic Difficulty System
local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 8, MaxDist = 12, Variance = 4, Time = 5 },   -- Easy
	[2] = { MinDist = 10, MaxDist = 14, Variance = 6, Time = 4.5 }, -- Medium
	[3] = { MinDist = 12, MaxDist = 16, Variance = 8, Time = 4 },   -- Hard
	[4] = { MinDist = 14, MaxDist = 17, Variance = 10, Time = 3 },  -- Extreme
}

local BLOCK_SIZE = Vector3.new(10, 1, 10)

-- State
local playerPaths = {} -- player -> { LastBlock = Part, AllBlocks = {Part, ...} }
local playerProgress = {} -- player -> Highest Level Index Reached (0 = Lobby, 1 = Level1, etc.)
local levelParts = {} -- levelIndex -> Part

-- Forward declarations
local spawnNextBlock
local setupBlockEvents
local startPath
local cleanupPlayerPath

--------------------------------------------------------------------------------
-- VISUALS: Countdown Timer
--------------------------------------------------------------------------------

local function createCountdown(block, duration)
	-- Look for the SurfaceGui and Label created by Factory
	local surfaceGui = block:WaitForChild("TimerGui", 5)
	if not surfaceGui then return end

	local label = surfaceGui:WaitForChild("TimerLabel", 5)
	if not label then return end

	label.Text = tostring(duration) .. ".0"

	task.spawn(function()
		local remaining = duration
		while remaining > 0 do
			if not block.Parent then break end
			label.Text = string.format("%.1f", remaining)
			task.wait(0.1)
			remaining -= 0.1
		end

		if block and block.Parent then
			block:Destroy()
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

	local startPos = currentBlock.Position
	local targetPos = targetConfig.Position

	-- 1. Calculate the direct vector (The Invisible Line) to the target center
	local vectorToTarget = (targetPos - startPos)
	local distToTarget = vectorToTarget.Magnitude

	-- Direction unit vector
	local moveDir = vectorToTarget.Unit

	-- 2. Proportional Division: Move along this line by JumpDistance
	local jumpDist = math.random(diff.MinDist * 10, diff.MaxDist * 10) / 10

	-- Safety: Don't overshoot target if we are very close
	if distToTarget < jumpDist + 5 then
		jumpDist = distToTarget - 5 -- Land just before it
		if jumpDist < 5 then jumpDist = 5 end -- Minimum jump
	end

	local idealPos = startPos + (moveDir * jumpDist)

	-- 3. Sub-plane Probability: Apply controlled random Offset (Variance) on X/Z axis
	local varAmount = diff.Variance
	local offsetX = (math.random() - 0.5) * 2 * varAmount
	local offsetZ = (math.random() - 0.5) * 2 * varAmount

	-- We only modify X and Z. Y is determined by the 'Invisible Line' (idealPos.Y)
	local finalPos = Vector3.new(idealPos.X + offsetX, idealPos.Y, idealPos.Z + offsetZ)

	-- Create Block from Prefab
	local block = Templates.ParkourBlock:Clone()
	block.Name = "Path_" .. player.Name
	block.Position = finalPos

	-- FIX: Flat Platforms (No Tilt)
	-- Construct CFrame looking at the target's X/Z but keeping current Y (level)
	local lookAtPoint = Vector3.new(targetPos.X, finalPos.Y, targetPos.Z)
	block.CFrame = CFrame.lookAt(finalPos, lookAtPoint)

	block.Parent = Workspace

	-- Visual Countdown
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
			-- Verify this is the last block
			local pathData = playerPaths[player]
			-- Fix: Only spawn if this is indeed the last block in the chain
			if pathData and pathData.LastBlock == block then
				triggered = true
				local nextBlock = spawnNextBlock(player, block)
				if nextBlock then
					pathData.LastBlock = nextBlock
				else
					-- Reached destination or stop
					pathData.LastBlock = nil
				end
			end
		end
	end)
end

function startPath(player, startPad)
	cleanupPlayerPath(player) -- Ensure clean slate

	playerPaths[player] = {
		LastBlock = nil,
		AllBlocks = {}
	}

	-- Spawn first block from the pad
	local firstBlock = spawnNextBlock(player, startPad)

	if firstBlock then
		playerPaths[player].LastBlock = firstBlock
	end
end

--------------------------------------------------------------------------------
-- LEVEL & PAD SETUP
--------------------------------------------------------------------------------

local function createStarterPads()
	-- Lobby -> Level 1 (Index 0 -> 1)
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

	-- Helper to create a pad
	local function makePad(sourcePart, targetPos, levelIndexForUnlock)
		local pad = Templates.StarterPad:Clone()
		pad.Name = "StarterPad_Level" .. (levelIndexForUnlock + 1)

		-- Position at edge facing target
		local dir = (targetPos - sourcePart.Position).Unit
		local distFromCenter = (sourcePart.Size.X / 2) - 2.5

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

	-- 1. Lobby -> Level 1 (Index 0 unlock)
	makePad(lobbyPart, LEVEL_CONFIGS[1].Position, 0)
	
	-- 2. Level i -> Level i+1 (Index i unlock)
	for i, config in ipairs(LEVEL_CONFIGS) do
		if i < #LEVEL_CONFIGS then
			local nextConfig = LEVEL_CONFIGS[i+1]
			local sourcePart = levelParts[i]
			if sourcePart then
				makePad(sourcePart, nextConfig.Position, i)
			end
		end
	end
end

local function createLevels()
	for i, config in ipairs(LEVEL_CONFIGS) do
		local existing = Workspace:FindFirstChild(config.Name)
		local platform

		if existing then
			platform = existing
			-- Update props just in case
			platform.Position = config.Position
			platform.BrickColor = config.Color
		else
			platform = Templates.LevelPlatform:Clone()
			platform.Name = config.Name
			platform.Position = config.Position
			platform.BrickColor = config.Color
			platform.Parent = Workspace
		end

		levelParts[i] = platform

		-- Checkpoint Logic with Fix 1: Independent Level Generation
		platform.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				-- Immediately stop current path generation
				if playerPaths[player] then
					playerPaths[player].LastBlock = nil
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

	-- Fix 2: Checkpoint Spawning Logic
	-- If progress > 0, teleport to that level
	local levelIndex = playerProgress[player] or 0
	if levelIndex > 0 then
		local levelPart = levelParts[levelIndex]
		if levelPart then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				task.wait(0.1) -- Physics frame wait
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
