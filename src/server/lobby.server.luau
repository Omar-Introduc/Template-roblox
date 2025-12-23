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

	-- 3. SpawnLocation (Visible and functional)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(10, 0.5, 10)
	spawnLocation.Position = Vector3.new(0, 1.25, 0) -- Sitting on top of Lobby (Y=1)
	spawnLocation.Anchored = true
	spawnLocation.BrickColor = BrickColor.new("Gold")
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Transparency = 0.2
	spawnLocation.CanCollide = true
	spawnLocation.Duration = 3
	spawnLocation.Parent = Workspace
	
	-- SelectionBox for extra detail
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = spawnLocation
	selectionBox.Color3 = Color3.new(1, 1, 0)
	selectionBox.Parent = spawnLocation

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