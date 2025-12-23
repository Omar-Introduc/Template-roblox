local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Configuration
local BLOCK_SIZE = Vector3.new(10, 1, 10)
local CLEANUP_TIME = 5 -- Tiempo antes de borrar bloques
local LOBBY_RADIUS = 13 -- Un poquito más del borde real (12) para dar margen

local LEVEL_CONFIGS = {
	{ Position = Vector3.new(0, 20, 100), Name = "Level1", Color = BrickColor.new("Bright green") },
	{ Position = Vector3.new(50, 40, 200), Name = "Level2", Color = BrickColor.new("Bright yellow") },
	{ Position = Vector3.new(0, 60, 300), Name = "Level3", Color = BrickColor.new("Bright orange") },
	{ Position = Vector3.new(-50, 80, 400), Name = "Level4", Color = BrickColor.new("Bright red") },
}

-- Player Data
local playerPaths = {}
local playerProgress = {} -- Tracks current target level index for each player
local levelParts = {} -- Stores the actual Part instances for levels

-- Forward declarations
local spawnNextBlock
local setupBlockEvents

-- 1. Create Levels (Waypoints)
local function createLevels()
	for i, config in ipairs(LEVEL_CONFIGS) do
		local existing = Workspace:FindFirstChild(config.Name)
		if not existing then
			local platform = Instance.new("Part")
			platform.Name = config.Name
			platform.Size = Vector3.new(20, 2, 20)
			platform.Position = config.Position
			platform.Anchored = true
			platform.Material = Enum.Material.Neon
			platform.BrickColor = config.Color
			platform.Parent = Workspace

			-- Add level number indicator (optional but helpful)
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 100, 0, 50)
			bb.StudsOffset = Vector3.new(0, 5, 0)
			bb.AlwaysOnTop = true
			bb.Parent = platform

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = config.Name
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.Parent = bb

			levelParts[i] = platform
		else
			levelParts[i] = existing
		end

		-- Setup Touch for Level Progression
		levelParts[i].Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				local currentTarget = playerProgress[player]

				-- If player reached their target level
				if currentTarget == i then
					-- Advance to next level
					if i < #LEVEL_CONFIGS then
						playerProgress[player] = i + 1
						print(player.Name .. " Reached " .. config.Name .. "! Next Target: Level " .. (i + 1))

						-- CONTINUE PATH GENERATION
						-- Treat the Level Platform as the "LastBlock" to spawn the next segment
						local pathData = playerPaths[player]
						if pathData then
							-- Ensure we don't spawn multiple branches from the level if touched multiple times
							-- We can check if the LastBlock is already ahead of the level, but simple re-assignment is safer
							-- actually, we should just spawn the next block immediately.

							pathData.LastBlock = levelParts[i]
							local nextBlock = spawnNextBlock(player, levelParts[i])
							pathData.LastBlock = nextBlock
							setupBlockEvents(player, nextBlock)
						end

					else
						print(player.Name .. " COMPLETED THE COURSE!")
						-- Maybe reset or just let them chill
					end
				end
			end
		end)
	end
end

-- Limpieza
local function cleanupPlayerPath(player)
	if playerPaths[player] and playerPaths[player].AllBlocks then
		for _, block in pairs(playerPaths[player].AllBlocks) do
			if block and block.Parent then
				block:Destroy()
			end
		end
	end
	playerPaths[player] = nil
	playerProgress[player] = nil
end

-- 2. Spawn Next Block Logic
function spawnNextBlock(player, currentBlock)
	local targetIndex = playerProgress[player] or 1
	-- Safety check: if finished or invalid, default to last level
	if targetIndex > #LEVEL_CONFIGS then
		targetIndex = #LEVEL_CONFIGS
	end

	local targetPos = LEVEL_CONFIGS[targetIndex].Position
	local startPos = currentBlock.Position

	-- Calculate direction
	local dirToTarget = (targetPos - startPos)
	local distToTarget = dirToTarget.Magnitude

	-- Normalized direction
	local unitDir = Vector3.new(0,0,1) -- Default backup
	if distToTarget > 0.1 then
		unitDir = dirToTarget.Unit
	end

	local horizontalDir = Vector3.new(unitDir.X, 0, unitDir.Z)
	if horizontalDir.Magnitude > 0.1 then
		horizontalDir = horizontalDir.Unit
	else
		horizontalDir = Vector3.new(0,0,1) -- Fallback
	end

	-- Height Difference
	local heightDiffToTarget = targetPos.Y - startPos.Y

	local forwardDist = math.random(10, 14) 
	local blockHeightDiff = 0 -- Default

	-- HEIGHT CORRECTION LOGIC
	-- If target is much higher (> 10 studs), force upward steps
	if heightDiffToTarget > 15 then
		blockHeightDiff = math.random(2, 5) -- Go up!
	elseif heightDiffToTarget < -15 then
		blockHeightDiff = math.random(-5, -2) -- Go down!
	else
		-- Normal variation
		blockHeightDiff = math.random(-1, 4)
	end

	-- PRECISION FIX: If target is far, prioritize forward distance.
	-- The logic naturally does this because `horizontalDir` points to the target.
	-- But we can tweak `forwardDist` if we are getting close.
	if distToTarget < 20 then
		forwardDist = math.min(forwardDist, distToTarget) -- Don't overshoot too much
	end

	local newPos = startPos + (horizontalDir * forwardDist) + Vector3.new(0, blockHeightDiff, 0)

	local block = Instance.new("Part")
	block.Name = player.Name .. "_PathBlock"
	block.Size = BLOCK_SIZE
	block.Position = newPos
	block.Anchored = true
	
	-- Crystal Logic
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	block.Parent = Workspace
	block.CFrame = CFrame.lookAt(newPos, newPos + horizontalDir)

	if playerPaths[player] then
		table.insert(playerPaths[player].AllBlocks, block)
	end
	
	Debris:AddItem(block, CLEANUP_TIME)

	return block
end

function setupBlockEvents(player, block)
	local hasTriggeredNext = false

	block.Touched:Connect(function(hit)
		if hasTriggeredNext then return end

		if hit.Parent == player.Character then
			local pathData = playerPaths[player]
			if pathData and pathData.LastBlock == block then
				hasTriggeredNext = true
				local nextBlock = spawnNextBlock(player, block)
				pathData.LastBlock = nextBlock
				setupBlockEvents(player, nextBlock)
			end
		end
	end)
end

-- 3. LOGICA DEL PRIMER BLOQUE (Instantánea)
local function startPath(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	if playerPaths[player] then return end -- Ya tiene camino

	-- Initialize Progress
	playerProgress[player] = 1
	local firstTargetPos = LEVEL_CONFIGS[1].Position

	local dirToTarget = (firstTargetPos - hrp.Position).Unit
	local horizontalDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z).Unit

	-- Aparece justo enfrente
	local spawnPos = hrp.Position + (horizontalDir * 8) - Vector3.new(0, 4, 0)

	local block = Instance.new("Part")
	block.Name = player.Name .. "_FirstBlock"
	block.Size = BLOCK_SIZE
	block.Position = spawnPos
	block.Anchored = true
	
	-- Crystal Logic
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	block.Parent = Workspace
	block.CFrame = CFrame.lookAt(spawnPos, spawnPos + horizontalDir)

	Debris:AddItem(block, CLEANUP_TIME)

	playerPaths[player] = { 
		LastBlock = block,
		AllBlocks = {block}
	}
	
	setupBlockEvents(player, block)

	-- *** TELETRANSPORTE INSTANTÁNEO ***
	-- Esto asegura que quedes encima del bloque
	hrp.CFrame = block.CFrame + Vector3.new(0, 3, 0)
	hrp.Velocity = Vector3.new(0,0,0)
	
	print("🚀 Parkour iniciado para: " .. player.Name .. " -> Objetivo: Level 1")
end

-- Gestión de Jugadores
local function onCharacterAdded(player, char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not hrp then return end

	cleanupPlayerPath(player)

	-- BUCLE ULTRA RÁPIDO (Heartbeat)
	-- Chequea cada frame si el jugador salió de la isla
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not char or not char.Parent or humanoid.Health <= 0 then
			connection:Disconnect()
			return
		end

		-- Verificar si ya tenemos camino
		if playerPaths[player] then return end

		local pos = hrp.Position
		-- Distancia horizontal desde el centro (0,0,0)
		local distFromCenter = Vector3.new(pos.X, 0, pos.Z).Magnitude
		
		-- CONDICIONES DE ACTIVACIÓN:
		-- 1. Estás cayendo (Y < -1)  O
		-- 2. Estás saltando fuera del radio del Lobby (> LOBBY_RADIUS) y en el aire
		local isInAir = humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping
		
		if pos.Y < -1 or (distFromCenter > LOBBY_RADIUS and isInAir) then
			startPath(player)
		end
	end)

	humanoid.Died:Connect(function()
		cleanupPlayerPath(player)
		if connection then connection:Disconnect() end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	cleanupPlayerPath(player)
end)

createLevels()