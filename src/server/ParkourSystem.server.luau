local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- 1. Modular Spiral Level Layout
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(100, 50, 0), Name = "Level1", Color = BrickColor.new("Bright green") }, -- East
	{ Position = Vector3.new(0, 100, 100), Name = "Level2", Color = BrickColor.new("Bright yellow") }, -- South
	{ Position = Vector3.new(-100, 150, 0), Name = "Level3", Color = BrickColor.new("Bright orange") }, -- West
	{ Position = Vector3.new(0, 200, -100), Name = "Level4", Color = BrickColor.new("Bright red") }, -- North
}

-- 2. Dynamic Difficulty System
-- Updated to use 'Variance' instead of Height, controlling X/Z offset
local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 8, MaxDist = 12, Variance = 4, Time = 5 },   -- Easy
	[2] = { MinDist = 10, MaxDist = 14, Variance = 6, Time = 4.5 }, -- Medium
	[3] = { MinDist = 12, MaxDist = 16, Variance = 8, Time = 4 },   -- Hard
	[4] = { MinDist = 14, MaxDist = 17, Variance = 10, Time = 3 },  -- Extreme
}

local BLOCK_SIZE = Vector3.new(10, 1, 10)
local LOBBY_RADIUS = 15

-- State
local playerPaths = {}
local playerProgress = {}
local levelParts = {}

-- Forward declarations
local spawnNextBlock
local setupBlockEvents

--------------------------------------------------------------------------------
-- LEVEL SETUP
--------------------------------------------------------------------------------

local function createLevels()
	for i, config in ipairs(LEVEL_CONFIGS) do
		local existing = Workspace:FindFirstChild(config.Name)
		local platform

		if existing then
			platform = existing
			platform.Position = config.Position
			platform.BrickColor = config.Color
		else
			platform = Instance.new("Part")
			platform.Name = config.Name
			platform.Size = Vector3.new(20, 2, 20)
			platform.Position = config.Position
			platform.Anchored = true
			platform.Material = Enum.Material.Neon
			platform.BrickColor = config.Color
			platform.Parent = Workspace
		end

		levelParts[i] = platform

		-- Checkpoint Logic
		platform.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				local currentTarget = playerProgress[player] or 1

				-- Checkpoint Logic: Update target to X+1 when touching Level X
				if currentTarget == i then
					if i < #LEVEL_CONFIGS then
						playerProgress[player] = i + 1
						print(player.Name .. " reached " .. config.Name .. "! Next Target: Level " .. (i + 1))

						local pathData = playerPaths[player]
						if pathData then
							pathData.LastBlock = platform
							spawnNextBlock(player, platform)
						end
					else
						print(player.Name .. " COMPLETED THE SPIRAL!")
					end
				end
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- CORE LOGIC
--------------------------------------------------------------------------------

function spawnNextBlock(player, currentBlock)
	local targetIndex = playerProgress[player] or 1
	if targetIndex > #LEVEL_CONFIGS then targetIndex = #LEVEL_CONFIGS end

	local targetConfig = LEVEL_CONFIGS[targetIndex]
	local diff = DIFFICULTY_SETTINGS[targetIndex] or DIFFICULTY_SETTINGS[1]

	local startPos = currentBlock.Position
	local targetPos = targetConfig.Position

	-- NEW ALGORITHM: 'Invisible Line' Projection

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

	-- Create Block
	local block = Instance.new("Part")
	block.Name = "Path_" .. player.Name
	block.Size = BLOCK_SIZE
	block.Position = finalPos
	block.Anchored = true

	-- FIX: Flat Platforms (No Tilt)
	-- Construct CFrame looking at the target's X/Z but keeping current Y (level)
	-- This ensures Pitch and Roll are 0.
	local lookAtPoint = Vector3.new(targetPos.X, finalPos.Y, targetPos.Z)
	block.CFrame = CFrame.lookAt(finalPos, lookAtPoint)

	block.Material = Enum.Material.Glass
	block.BrickColor = BrickColor.new("Institutional white")
	
	-- Integration: Tags & Attributes
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	block.Parent = Workspace

	-- Disappearing Platforms
	Debris:AddItem(block, diff.Time)

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
			if pathData and pathData.LastBlock == block then
				triggered = true
				local nextBlock = spawnNextBlock(player, block)
				pathData.LastBlock = nextBlock
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- LIFECYCLE
--------------------------------------------------------------------------------

local function cleanupPlayerPath(player)
	if playerPaths[player] then
		for _, b in pairs(playerPaths[player].AllBlocks) do
			if b and b.Parent then b:Destroy() end
		end
	end
	playerPaths[player] = nil
	playerProgress[player] = nil
end

local function startPath(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	if playerPaths[player] then return end

	playerProgress[player] = 1 -- Start at Level 1

	-- Generate first block aiming at Level 1
	local targetPos = LEVEL_CONFIGS[1].Position
	local dir = (targetPos - hrp.Position).Unit
	local spawnPos = hrp.Position + (dir * 8) + Vector3.new(0, -2, 0)

	local block = Instance.new("Part")
	block.Name = "Start_" .. player.Name
	block.Size = BLOCK_SIZE
	block.Position = spawnPos
	block.Anchored = true

	-- Fix Rotation for start block too
	local lookAtPoint = Vector3.new(targetPos.X, spawnPos.Y, targetPos.Z)
	block.CFrame = CFrame.lookAt(spawnPos, lookAtPoint)
	
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)
	block.Parent = Workspace

	Debris:AddItem(block, DIFFICULTY_SETTINGS[1].Time)

	playerPaths[player] = {
		LastBlock = block,
		AllBlocks = {block}
	}
	
	setupBlockEvents(player, block)
	
	-- Teleport player slightly to start
	hrp.CFrame = block.CFrame + Vector3.new(0, 5, 0)
	hrp.AssemblyLinearVelocity = Vector3.zero
end

local function onCharacterAdded(player, char)
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	cleanupPlayerPath(player)

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not char or not char.Parent or hum.Health <= 0 then
			conn:Disconnect()
			return
		end

		if playerPaths[player] then return end
		
		-- Trigger if player jumps out of lobby or falls
		local pos = hrp.Position
		local dist = Vector3.new(pos.X, 0, pos.Z).Magnitude
		
		if (pos.Y < -5) or (dist > LOBBY_RADIUS and pos.Y > 0) then
			startPath(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(c) onCharacterAdded(p, c) end)
end)

Players.PlayerRemoving:Connect(cleanupPlayerPath)

createLevels()
