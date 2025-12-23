local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

-- Configuration
local TARGET_POS = Vector3.new(400, 150, 400) -- Dónde está la isla de lava
local LOBBY_CENTER = Vector3.new(0, 0, 0)
local BLOCK_SIZE = Vector3.new(4, 1, 4)
local CLEANUP_TIME = 10 -- Tiempo antes de que los bloques viejos desaparezcan solos

-- Player Data: Stores current path and ALL blocks for cleanup
local playerPaths = {}

-- 1. Create Destination (Lava Island) - (Igual que antes)
local function createLavaIsland()
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
	fire.Heat = 10
	fire.Parent = island

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 100, 0)
	light.Range = 60
	light.Brightness = 3
	light.Parent = island
end

-- Función para limpiar TODO el camino de un jugador (al morir o salir)
local function cleanupPlayerPath(player)
	if playerPaths[player] and playerPaths[player].AllBlocks then
		for _, block in pairs(playerPaths[player].AllBlocks) do
			if block and block.Parent then
				block:Destroy()
			end
		end
	end
	playerPaths[player] = nil -- Borrar datos
end

-- 2. Spawn Next Block Logic
local function spawnNextBlock(player, currentBlock)
	local startPos = currentBlock.Position
	local dirToTarget = (TARGET_POS - startPos).Unit
	local horizontalDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z).Unit

	-- Distancia de salto aleatoria pero posible
	local forwardDist = math.random(9, 13) 
	local heightDiff = math.random(-1, 3) 

	local newPos = startPos + (horizontalDir * forwardDist) + Vector3.new(0, heightDiff, 0)

	local block = Instance.new("Part")
	block.Name = player.Name .. "_PathBlock"
	block.Size = BLOCK_SIZE
	block.Position = newPos
	block.Anchored = true
	block.BrickColor = BrickColor.new("Dark stone grey")
	block.Material = Enum.Material.Slate
	block.TopSurface = Enum.SurfaceType.Smooth
	block.Parent = Workspace
	block.CFrame = CFrame.lookAt(newPos, newPos + horizontalDir)

	-- Guardar bloque en la lista para borrarlo si muere
	if playerPaths[player] then
		table.insert(playerPaths[player].AllBlocks, block)
	end
	
	-- Auto-destrucción por tiempo (opcional, para no laggear el server)
	game:GetService("Debris"):AddItem(block, CLEANUP_TIME)

	return block
end

local function setupBlockEvents(player, block)
	local hasTriggeredNext = false

	block.Touched:Connect(function(hit)
		if hasTriggeredNext then return end

		if hit.Parent == player.Character then
			local pathData = playerPaths[player]
			-- Solo generar si es el último bloque que pisó
			if pathData and pathData.LastBlock == block then
				hasTriggeredNext = true
				local nextBlock = spawnNextBlock(player, block)
				pathData.LastBlock = nextBlock -- Actualizar referencia
				setupBlockEvents(player, nextBlock)
			end
		end
	end)
end

-- 3. LOGICA DEL PRIMER BLOQUE (Modificada: Instantánea y Segura)
local function startPath(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Si ya tiene un camino activo, no creamos otro encima
	if playerPaths[player] then return end

	-- Dirección hacia la meta
	local dirToLava = (TARGET_POS - hrp.Position).Unit
	local horizontalDir = Vector3.new(dirToLava.X, 0, dirToLava.Z).Unit

	-- Crear bloque justo enfrente y un poco abajo
	local spawnPos = hrp.Position + (horizontalDir * 8) - Vector3.new(0, 4, 0)

	local block = Instance.new("Part")
	block.Name = player.Name .. "_FirstBlock"
	block.Size = BLOCK_SIZE
	block.Position = spawnPos
	block.Anchored = true
	block.BrickColor = BrickColor.new("Dark stone grey")
	block.Material = Enum.Material.Slate
	block.Parent = Workspace
	block.CFrame = CFrame.lookAt(spawnPos, spawnPos + horizontalDir)

	-- Inicializar datos del jugador
	playerPaths[player] = { 
		LastBlock = block,
		AllBlocks = {block} -- Lista para limpieza
	}
	
	setupBlockEvents(player, block)

	-- *** TELETRANSPORTE DE SEGURIDAD ***
	-- Movemos al jugador justo encima del bloque para asegurar que no falle el primer salto
	hrp.CFrame = block.CFrame + Vector3.new(0, 3, 0)
	hrp.Velocity = Vector3.new(0,0,0) -- Detener inercia de caída

	print(player.Name .. " comenzó el parkour (Teletransportado al primer bloque).")
end

-- Player Management
local function onCharacterAdded(player, char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not hrp then return end

	-- Limpiar camino anterior si existía
	cleanupPlayerPath(player)

	-- Detectar salto inicial desde el Lobby
	humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			-- Verificar si estamos cerca del Lobby y no hemos empezado
			local distFromLobby = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - LOBBY_CENTER).Magnitude
			
			-- Si salta fuera del lobby (> 15 studs) y no tiene camino
			if distFromLobby > 15 and not playerPaths[player] then
				startPath(player)
			end
		end
	end)

	-- Detectar MUERTE para limpiar bloques
	humanoid.Died:Connect(function()
		print(player.Name .. " murió. Reiniciando bloques...")
		cleanupPlayerPath(player)
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

-- Initial Setup
createLavaIsland()