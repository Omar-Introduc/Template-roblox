-- Lobby: Galería Lineal y Iluminación Realista (Versión Final Estable)
-- Optimizado por Arquitecto de Sistemas Roblox
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- 1. Configuración Principal
local LOBBY_CONFIG = {
	Width = 250,
	Depth = 80,
	WallHeight = 4,
	FloorColor = BrickColor.new("Dark stone grey"),
	FloorMaterial = Enum.Material.SmoothPlastic,
	Name = "Lobby" -- CRÍTICO: Nombre exacto para el sistema de parkour
}

local LIGHTING_CONFIG = {
	ClockTime = 0,
	Brightness = 2.0,
	Ambient = Color3.fromRGB(120, 120, 140),
	OutdoorAmbient = Color3.fromRGB(80, 80, 100)
}

-- 2. Sistema de Iluminación
local function setupGlobalLighting()
	print("🌕 [LOBBY] Configurando Iluminación Nocturna...")
	Lighting.ClockTime = LIGHTING_CONFIG.ClockTime
	Lighting.Brightness = LIGHTING_CONFIG.Brightness
	Lighting.GlobalShadows = true
	Lighting.Ambient = LIGHTING_CONFIG.Ambient
	Lighting.OutdoorAmbient = LIGHTING_CONFIG.OutdoorAmbient
	
	-- Limpiar efectos antiguos
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("BloomEffect") then
			child:Destroy()
		end
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 12
	bloom.Threshold = 0.8
	bloom.Parent = Lighting
end

-- 3. Funciones de Construcción Auxiliares
local function createWall(name, size, position, parent)
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.BrickColor = LOBBY_CONFIG.FloorColor
	wall.Material = Enum.Material.Concrete
	wall.Parent = parent
	return wall
end

local function cleanLobbyArea()
	-- Eliminar cualquier objeto previo que cause conflictos
	local existingLobby = Workspace:FindFirstChild(LOBBY_CONFIG.Name)
	if existingLobby then existingLobby:Destroy() end
	
	local oldIsland = Workspace:FindFirstChild("LobbyIsland") -- Limpieza de nombres antiguos
	if oldIsland then oldIsland:Destroy() end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then baseplate:Destroy() end
end

-- 4. Creación del Lobby
local function createLobby()
	cleanLobbyArea()
	setupGlobalLighting()
	
	-- Suelo Principal
	local floor = Instance.new("Part")
	floor.Name = LOBBY_CONFIG.Name -- ¡CORRECCIÓN APLICADA!
	floor.Size = Vector3.new(LOBBY_CONFIG.Width, 2, LOBBY_CONFIG.Depth)
	floor.Position = Vector3.new(0, 0, 0) -- Posición 0,0,0 Garantizada
	floor.Anchored = true
	floor.Material = LOBBY_CONFIG.FloorMaterial
	floor.BrickColor = LOBBY_CONFIG.FloorColor
	floor.Parent = Workspace

	-- Paredes Perimetrales
	local w2 = LOBBY_CONFIG.Width/2
	local d2 = LOBBY_CONFIG.Depth/2
	local h = LOBBY_CONFIG.WallHeight

	createWall("Wall_Back", Vector3.new(LOBBY_CONFIG.Width, h, 1), Vector3.new(0, h/2, -d2), floor)
	createWall("Wall_Front", Vector3.new(LOBBY_CONFIG.Width, h, 1), Vector3.new(0, h/2, d2), floor)
	createWall("Wall_Right", Vector3.new(1, h, LOBBY_CONFIG.Depth), Vector3.new(w2, h/2, 0), floor)
	createWall("Wall_Left", Vector3.new(1, h, LOBBY_CONFIG.Depth), Vector3.new(-w2, h/2, 0), floor)

	-- Spawn Point
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 1.5, 0)
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Parent = Workspace

	-- Señal de Listo
	Workspace:SetAttribute("LobbyReady", true)
	print("✅ [LOBBY] Isla Generada Correctamente en (0,0,0).")

	return floor
end

-- 5. Decoración y Assets
local function loadDecorations(floor)
	-- Cargar HexPlatform_V2 si existe (Plataforma de inicio alternativa)
	task.spawn(function()
		local Templates = ReplicatedStorage:WaitForChild("Templates", 5)
		if Templates then
			local platform = Templates:FindFirstChild("HexPlatform_V2")
			if platform then
				local p = platform:Clone()
				p.Name = "HexPlatform_V2"
				p:PivotTo(CFrame.new(Vector3.new(50, 1.2, -20)))
				p.Parent = Workspace
			end

			-- Árboles Sakura
			local tree = Templates:FindFirstChild("MasterSakuraTree")
			if tree then
				local t1 = tree:Clone(); t1:PivotTo(CFrame.new(-100, 1.2, -20)); t1.Parent = floor
				local t2 = tree:Clone(); t2:PivotTo(CFrame.new(100, 1.2, -20)); t2.Parent = floor
			end
		end
	end)
end

-- 6. Océano Mortal
local function createDeadlyOcean()
	local ocean = Instance.new("Part")
	ocean.Name = "DeadlyOcean"
	ocean.Size = Vector3.new(2048, 4, 2048)
	ocean.Position = Vector3.new(0, -30, 0)
	ocean.Anchored = true
	ocean.CanCollide = false
	ocean.BrickColor = BrickColor.new("Deep blue")
	ocean.Material = Enum.Material.Water
	ocean.Transparency = 0.4
	ocean.Parent = Workspace

	ocean.Touched:Connect(function(hit)
		local h = hit.Parent:FindFirstChild("Humanoid")
		if h then h.Health = 0 end
	end)
end

-- Ejecución Principal
local lobbyFloor = createLobby()
loadDecorations(lobbyFloor)
createDeadlyOcean()
