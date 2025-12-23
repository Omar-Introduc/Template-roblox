local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Configuration
local TARGET_POS = Vector3.new(400, 150, 400)
local LOBBY_CENTER = Vector3.new(0, 0, 0)
local BLOCK_SIZE = Vector3.new(4, 1, 4)
local CLEANUP_TIME = 5
local START_DELAY = 1

-- Player Data: Stores the current active path state for each player
local playerPaths = {}

-- 1. The Destination (Lava Island)
local function createLavaIsland()
	local island = Instance.new("Part")
	island.Name = "LavaIsland"
	island.Size = Vector3.new(30, 2, 30) -- Large platform
	island.Position = TARGET_POS
	island.Anchored = true
	island.Material = Enum.Material.CrackedLava
	island.BrickColor = BrickColor.new("Bright orange")
	island.Parent = Workspace

	-- Styling: Fire and PointLights
	local fire = Instance.new("Fire")
	fire.Size = 10
	fire.Heat = 10
	fire.Parent = island

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 100, 0)
	light.Range = 60
	light.Brightness = 3
	light.Parent = island

	print("✅ Lava Island created at " .. tostring(TARGET_POS))
end

-- Cleanup Helper
local function scheduleBlockCleanup(block)
	task.delay(CLEANUP_TIME, function()
		if block and block.Parent then
			-- Optional: Fade out effect could be added here
			block:Destroy()
		end
	end)
end

-- 3. Iterative Generation Logic (The Core)
local function spawnNextBlock(player, currentBlock)
	-- Calculate direction towards Lava Island
	local startPos = currentBlock.Position
	local dirToTarget = (TARGET_POS - startPos).Unit

	-- Flatten direction to horizontal plane for movement
	local horizontalDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z).Unit

	-- Jumpability: Random offsets strictly within limits
	local forwardDist = math.random(10, 14) -- 10 to 14 studs forward
	local heightDiff = math.random(-2, 4)   -- -2 to +4 studs height

	local newPos = startPos + (horizontalDir * forwardDist) + Vector3.new(0, heightDiff, 0)

	-- Block Style
	local block = Instance.new("Part")
	block.Name = player.Name .. "_PathBlock"
	block.Size = BLOCK_SIZE
	block.Position = newPos
	block.Anchored = true
	block.BrickColor = BrickColor.new("Dark stone grey") -- Dark stone
	block.Material = Enum.Material.Slate -- Fits lava theme
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Parent = Workspace

	-- Orient block to look at next target roughly
	block.CFrame = CFrame.lookAt(newPos, newPos + horizontalDir)

	return block
end

-- Setup events for a block (Touch to spawn next, TouchEnded to cleanup)
local function setupBlockEvents(player, block)
	local hasTriggeredNext = false

	-- Touch to Spawn Next
	block.Touched:Connect(function(hit)
		if hasTriggeredNext then return end

		if hit.Parent == player.Character then
			local pathData = playerPaths[player]
			-- Only spawn if this is the player's latest block (Single Path)
			if pathData and pathData.LastBlock == block then
				hasTriggeredNext = true

				local nextBlock = spawnNextBlock(player, block)
				pathData.LastBlock = nextBlock -- Update latest block

				setupBlockEvents(player, nextBlock)
			end
		end
	end)

	-- TouchEnded for Cleanup
	block.TouchEnded:Connect(function(hit)
		if hit.Parent == player.Character then
			scheduleBlockCleanup(block)
		end
	end)
end

-- 2. First Block Logic
local function startPath(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Direction towards Lava Island
	local dirToLava = (TARGET_POS - hrp.Position).Unit
	local horizontalDir = Vector3.new(dirToLava.X, 0, dirToLava.Z).Unit

	-- Spawn exactly under where they are likely to fall (or slightly ahead)
	-- We put it slightly ahead so they have momentum to land on it
	local spawnPos = hrp.Position + (horizontalDir * 5) - Vector3.new(0, 5, 0)

	local block = Instance.new("Part")
	block.Name = player.Name .. "_FirstBlock"
	block.Size = BLOCK_SIZE
	block.Position = spawnPos
	block.Anchored = true
	block.BrickColor = BrickColor.new("Dark stone grey")
	block.Material = Enum.Material.Slate
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Parent = Workspace
	block.CFrame = CFrame.lookAt(spawnPos, spawnPos + horizontalDir)

	-- Initialize path data
	playerPaths[player] = { LastBlock = block }
	setupBlockEvents(player, block)

	print(player.Name .. " started parkour!")
end

-- Player Management
local function onCharacterAdded(player, char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not hrp then return end

	local jumpCheckDebounce = false

	humanoid.StateChanged:Connect(function(old, new)
		-- Start Trigger: Detect jump/fall
		if new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
			if jumpCheckDebounce then return end
			jumpCheckDebounce = true

			-- Wait 1 second to see if they are "off" the lobby
			task.delay(START_DELAY, function()
				if not char or not char.Parent or humanoid.Health <= 0 then
					jumpCheckDebounce = false
					return
				end

				local currentState = humanoid:GetState()
				if currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping then
					-- Player is still in air. Check if they are away from Lobby center.
					local currentPos = hrp.Position
					local distFromLobby = (Vector3.new(currentPos.X, 0, currentPos.Z) - LOBBY_CENTER).Magnitude

					-- If sufficiently far from lobby center (approx 12 studs radius) OR significantly below
					if distFromLobby > 15 or currentPos.Y < -5 then
						-- Trigger First Block if we haven't already recently?
						-- We rely on the fact that they have to land to jump again or wait.
						-- If they are already parkouring, this might trigger a reset if they fall.
						-- For now, we always spawn a first block if they fall long enough.
						startPath(player)
					end
				end
				jumpCheckDebounce = false
			end)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerPaths[player] = nil
end)

-- Initial Setup
createLavaIsland()
