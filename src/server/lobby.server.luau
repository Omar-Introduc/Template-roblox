-- Lobby Island and Deadly Ocean Setup Script (MEJORADO)
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Configuración
local LOBBY_SIZE = 80
local WALL_HEIGHT = 3

-- Función para crear una pared
local function createWall(position, size, parent)
	local wall = Instance.new("Part")
	wall.Name = "LobbyWall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.BrickColor = BrickColor.new("Dark stone grey")
	wall.Material = Enum.Material.Concrete
	wall.Transparency = 0.2
	wall.Parent = parent
end

-- Función para crear un Árbol de Cerezo (Sakura)
local function createCherryTree(position, parent)
	local treeFolder = Instance.new("Model")
	treeFolder.Name = "CherryTree"
	treeFolder.Parent = parent

	-- Tronco
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 10, 2)
	trunk.Position = position + Vector3.new(0, 5, 0)
	trunk.Anchored = true
	trunk.BrickColor = BrickColor.new("Reddish brown")
	trunk.Material = Enum.Material.Wood
	trunk.Parent = treeFolder

	-- Hojas (Copa del árbol)
	local function createLeafCluster(offset, size)
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = size
		leaves.Position = trunk.Position + Vector3.new(0, 5, 0) + offset
		leaves.Anchored = true
		leaves.BrickColor = BrickColor.new("Pink")
		leaves.Material = Enum.Material.Grass -- Para darle algo de textura
		leaves.CanCollide = false
		leaves.Parent = treeFolder

		-- Partículas de pétalos cayendo
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "Petals"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 192, 203))
		particles.Size = NumberSequence.new(0.2, 0)
		particles.Lifetime = NumberRange.new(2, 5)
		particles.Rate = 5
		particles.Speed = NumberRange.new(2, 5)
		particles.SpreadAngle = Vector2.new(45, 45)
		particles.Texture = "rbxassetid://2415370814" -- Textura de copo/hoja pequeña
		particles.Acceleration = Vector3.new(0, -1, 0)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		particles.Parent = leaves
	end

	createLeafCluster(Vector3.new(0, 0, 0), Vector3.new(8, 8, 8))
	createLeafCluster(Vector3.new(3, -2, 2), Vector3.new(5, 5, 5))
	createLeafCluster(Vector3.new(-3, -2, -2), Vector3.new(5, 5, 5))
	createLeafCluster(Vector3.new(2, -2, -3), Vector3.new(5, 5, 5))
	
	print("🌸 Árbol de cerezo añadido.")
end

-- Función para crear el Lobby con seguridad
local function createLobbyIsland()
	-- 1. Crear el suelo de la isla
	local lobbyIsland = Instance.new("Part")
	lobbyIsland.Name = "Lobby"
	lobbyIsland.Size = Vector3.new(LOBBY_SIZE, 2, LOBBY_SIZE)
	lobbyIsland.Position = Vector3.new(0, 0, 0) -- Top surface at Y=1 (thickness 2)
	lobbyIsland.Anchored = true
	lobbyIsland.BrickColor = BrickColor.new("Bright green")
	lobbyIsland.Material = Enum.Material.Grass
	lobbyIsland.Parent = Workspace

	-- 2. Crear paredes alrededor (para que sea seguro)
	local halfSize = LOBBY_SIZE / 2
	local wallThick = 1
	-- Pared Norte
	createWall(Vector3.new(0, WALL_HEIGHT/2, -halfSize), Vector3.new(LOBBY_SIZE, WALL_HEIGHT, wallThick), lobbyIsland)
	-- Pared Sur
	createWall(Vector3.new(0, WALL_HEIGHT/2, halfSize), Vector3.new(LOBBY_SIZE, WALL_HEIGHT, wallThick), lobbyIsland)
	-- Pared Este
	createWall(Vector3.new(halfSize, WALL_HEIGHT/2, 0), Vector3.new(wallThick, WALL_HEIGHT, LOBBY_SIZE), lobbyIsland)
	-- Pared Oeste
	createWall(Vector3.new(-halfSize, WALL_HEIGHT/2, 0), Vector3.new(wallThick, WALL_HEIGHT, LOBBY_SIZE), lobbyIsland)

	-- 3. SpawnLocation (Invisible and functional)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(10, 0.1, 10) -- Más delgado para evitar interferencias
	spawnLocation.Position = Vector3.new(0, 1.1, 0) -- 1.1 asegura que esté ARRIBA del suelo (Y=1.0)
	spawnLocation.Anchored = true
	spawnLocation.Transparency = 1 -- Completamente invisible
	spawnLocation.CanCollide = false
	spawnLocation.CanTouch = false
	spawnLocation.Duration = 0
	spawnLocation.Parent = Workspace
	
	-- Eliminar el logo por defecto si existe
	local decal = spawnLocation:FindFirstChildOfClass("Decal")
	if decal then decal:Destroy() end

	-- 4. Añadir Árboles de Cerezo para decorar
	createCherryTree(Vector3.new(20, 1, 20), lobbyIsland)
	createCherryTree(Vector3.new(-20, 1, -20), lobbyIsland)

	print("✅ Lobby Spawn (Dorado) integrado.")

	print("✅ Lobby Island (con seguridad) creada.")
end

-- Función para crear el Océano Mortal
local function createDeadlyOcean()
	local deadlyOcean = Instance.new("Part")
	deadlyOcean.Name = "DeadlyOcean"
	deadlyOcean.Size = Vector3.new(2048, 8, 2048) -- Un poco más grueso
	deadlyOcean.Position = Vector3.new(0, -25, 0) -- Más abajo para dar espacio de caída
	deadlyOcean.Anchored = true
	deadlyOcean.CanCollide = false
	deadlyOcean.BrickColor = BrickColor.new("Deep blue")
	deadlyOcean.Material = Enum.Material.Water
	deadlyOcean.Transparency = 0.4
	deadlyOcean.Reflectance = 0.3 -- Un poco de brillo
	deadlyOcean.Parent = Workspace

	-- Lógica de muerte DIRECTA (sin crear otro script)
	deadlyOcean.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		
		if humanoid and humanoid.Health > 0 then
			print("🌊 Jugador cayó al agua: " .. character.Name)
			
			-- Splash Sound
			local splash = Instance.new("Sound", hit)
			splash.SoundId = "rbxassetid://6831034444" -- Water Splash
			splash.Volume = 0.8
			splash.PlayOnRemove = true
			splash:Play()
			splash:Destroy()

			humanoid.Health = 0 -- Muerte instantánea
		end
	end)

	print("✅ Océano Mortal activado.")
end

local function cleanupBaseplate()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("🗑️ Baseplate eliminado.")
	end
end

-- Ejecución principal
local function setupGameEnvironment()
	print("🛠️ Iniciando configuración del entorno...")
	
	cleanupBaseplate()
	createLobbyIsland()
	createDeadlyOcean()
	
	-- Ajuste de iluminación básico para que se vea mejor
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.Brightness = 2.5
	
	print("✨ Entorno listo. ¡A saltar!")
end

setupGameEnvironment()