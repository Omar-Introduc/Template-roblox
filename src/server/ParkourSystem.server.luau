local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Configuration
local TARGET_POS = Vector3.new(400, 150, 400) -- Dónde está la isla de lava
local BLOCK_SIZE = Vector3.new(10, 1, 10)
local CLEANUP_TIME = 5 -- Tiempo antes de borrar bloques
local LOBBY_RADIUS = 13 -- Un poquito más del borde real (12) para dar margen

-- Player Data
local playerPaths = {}

-- 1. Create Destination (Lava Island)
local function createLavaIsland()
	if Workspace:FindFirstChild("LavaIsland") then return end

	local island = Instance.new("Part")
	island.Name = "LavaIsland"
	island.Size = Vector3.new(30, 2, 30)
	island.Position = TARGET_POS
	island.Anchored = true
	island.Material = Enum.Material.CrackedLava
	island.BrickColor = BrickColor.new("Bright orange")
	island.Parent = Workspace

	local fire = Instance.new("Fire")
	fire.Size = 10
	fire.Parent = island

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 100, 0)
	light.Range = 60
	light.Brightness = 3
	light.Parent = island
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
end

-- 2. Spawn Next Block Logic
local function spawnNextBlock(player, currentBlock)
	local startPos = currentBlock.Position
	local dirToTarget = (TARGET_POS - startPos).Unit
	local horizontalDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z).Unit

	local forwardDist = math.random(10, 14) 
	local heightDiff = math.random(-1, 4) 

	local newPos = startPos + (horizontalDir * forwardDist) + Vector3.new(0, heightDiff, 0)

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

local function setupBlockEvents(player, block)
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

	local dirToLava = (TARGET_POS - hrp.Position).Unit
	local horizontalDir = Vector3.new(dirToLava.X, 0, dirToLava.Z).Unit

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
	
	print("🚀 Parkour iniciado para: " .. player.Name)
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

createLavaIsland()