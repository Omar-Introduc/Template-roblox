-- Lobby Island and Deadly Ocean Setup Script (MEJORADO)
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	local Templates = ReplicatedStorage:WaitForChild("Templates")
	while not Templates:GetAttribute("SakuraReady") do task.wait(0.1) end
	local tree = Templates:WaitForChild("MasterSakuraTree"):Clone()
	
	-- Posicionamos el modelo
	tree:SetPrimaryPartCFrame(CFrame.new(position))
	tree.Parent = parent
	
	print("🌸 Árbol de cerezo profesional añadido.")
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
	-- 3. SpawnLocation (DEFINITIVE INVISIBLE FIX)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(1, 1, 1) -- Small enough but safe
	spawnLocation.Position = Vector3.new(0, 1.5, 0) -- Elevated safely (top of floor is 1.0)
	spawnLocation.Anchored = true
	spawnLocation.Transparency = 1 
	spawnLocation.CastShadow = false -- Critical optimization
	spawnLocation.CanCollide = false
	spawnLocation.CanTouch = false
	spawnLocation.Duration = 0 
	spawnLocation.Parent = Workspace
	
	-- Robust Decal Removal
	spawnLocation.ChildAdded:Connect(function(child)
		if child:IsA("Decal") then child:Destroy() end
	end)
	for _, child in ipairs(spawnLocation:GetChildren()) do
		if child:IsA("Decal") then child:Destroy() end
	end
	
	print("🎯 Spawn del Lobby arreglado definitivamente.")

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
			splash.SoundId = "rbxassetid://5930519356" -- High Quality Water Splash
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
	-- 1. Eliminar Baseplate original
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("🗑️ Baseplate eliminado.")
	end

	-- 2. Eliminar Spawns por defecto para evitar duplicados
	for _, item in ipairs(Workspace:GetChildren()) do
		if item:IsA("SpawnLocation") and item.Name ~= "LobbySpawn" then
			item:Destroy()
			print("🗑️ Spawn por defecto '" .. item.Name .. "' eliminado.")
		end
	end
end

-- Ejecución principal
local function setupGameEnvironment()
	print("🛠️ Iniciando configuración del entorno...")
	
	cleanupBaseplate()
	createLobbyIsland()
	createDeadlyOcean()
	
	-- Ajuste de Iluminación (Tokyo Style)
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.OutdoorAmbient = Color3.fromHex("#FFE4E1") -- Tinte rosa amanecer
	Lighting.GlobalShadows = true
	Lighting.Brightness = 2.5
	
	-- Bloom para "brillo" suave
	local bloom = Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.2
	bloom.Threshold = 0.95
	
	print("✨ Entorno listo (Estilo Tokyo). ¡A saltar!")
end

setupGameEnvironment()