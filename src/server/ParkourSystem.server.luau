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
local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 8, MaxDist = 12, MinHeight = -1, MaxHeight = 1, Time = 5 },   -- Easy
	[2] = { MinDist = 10, MaxDist = 14, MinHeight = -1, MaxHeight = 2, Time = 4.5 }, -- Medium
	[3] = { MinDist = 12, MaxDist = 16, MinHeight = -2, MaxHeight = 3, Time = 4 },   -- Hard
	[4] = { MinDist = 14, MaxDist = 17, MinHeight = -2, MaxHeight = 4, Time = 3 },   -- Extreme
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

				-- 4. Checkpoint Logic: Update target to X+1 when touching Level X
				-- If currentTarget is aiming for 'i', it means they just arrived at 'i'.
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

	-- Calculate Direction (3D Vector to allow climbing)
	local dirVec = (targetPos - startPos)
	local distToTarget = dirVec.Magnitude
	local moveDir = dirVec.Unit

	-- Math Settings from Difficulty Table
	local dist = math.random(diff.MinDist * 10, diff.MaxDist * 10) / 10
	local height = math.random(diff.MinHeight * 10, diff.MaxHeight * 10) / 10

	-- Safety: Avoid overshooting the target if close
	if distToTarget < 20 then
		dist = math.min(dist, distToTarget)
	end

	-- "Steeper Stairs" Interpretation:
	-- The 'height' from difficulty is applied as variance to the natural slope of the path.
	-- This ensures the player climbs towards the target while respecting the difficulty 'jagginess'.
	-- If the target is significantly higher, we ensure we don't accidentally step down too much.
	if dirVec.Y > 10 and height < 0 then
		-- If we need to go up, and random gave us down, flip it or clamp it.
		-- This keeps the "randomness" but biases it correctly.
		height = math.abs(height)
	end

	-- Calculate New Position: Move along the slope (moveDir * dist) then add vertical variance (height)
	-- Note: Since moveDir includes Y, 'dist' already adds some height. The 'height' variable adds EXTRA offset.
	-- However, standard parkour logic usually treats 'dist' as horizontal.
	-- Let's stick to the prompt's likely intent:
	-- If we use moveDir (3D), we climb naturally. The 'Height' param is variance.
	local newPos = startPos + (moveDir * dist) + Vector3.new(0, height, 0)

	-- Create Block
	local block = Instance.new("Part")
	block.Name = "Path_" .. player.Name
	block.Size = BLOCK_SIZE
	block.Position = newPos
	block.Anchored = true
	block.CFrame = CFrame.lookAt(newPos, newPos + moveDir) -- Face the target direction
	block.Material = Enum.Material.Glass
	block.BrickColor = BrickColor.new("Institutional white")
	
	-- 5. Integration: Tags & Attributes
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	block.Parent = Workspace

	-- 3. Disappearing Platforms
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
	block.CFrame = CFrame.lookAt(spawnPos, spawnPos + dir)
	
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
