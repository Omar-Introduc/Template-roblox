--[[
    🏛️ Lobby System - Optimized for Parkour Framework

    Responsabilidad: Generar el área de inicio (Lobby) y configurar la iluminación.
    Asegura compatibilidad con ParkourSystem mediante nomenclatura estricta ("Lobby").

    Autor: Arquitecto de Sistemas Roblox (IA)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuración Centralizada
local CONFIG = {
	LobbyName = "Lobby", -- CRÍTICO: Debe coincidir con ParkourSystem
	Size = Vector3.new(250, 2, 80),
	Position = Vector3.new(0, 0, 0), -- Centro del mundo
	Color = BrickColor.new("Dark stone grey"),
	Material = Enum.Material.SmoothPlastic,
	WallHeight = 6
}

local LIGHTING_OPTS = {
	Time = 0, -- Media noche
	Brightness = 2,
	Ambient = Color3.fromRGB(100, 100, 120),
	OutdoorAmbient = Color3.fromRGB(60, 60, 80)
}

--------------------------------------------------------------------------------
-- 1. GESTIÓN DE ILUMINACIÓN
--------------------------------------------------------------------------------
local function setupLighting()
	Lighting.ClockTime = LIGHTING_OPTS.Time
	Lighting.Brightness = LIGHTING_OPTS.Brightness
	Lighting.Ambient = LIGHTING_OPTS.Ambient
	Lighting.OutdoorAmbient = LIGHTING_OPTS.OutdoorAmbient
	Lighting.GlobalShadows = true

	-- Limpieza de efectos atmosféricos antiguos
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") or child:IsA("Sky") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end

	-- Nuevos efectos visuales
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 18
	bloom.Threshold = 0.8
	bloom.Parent = Lighting
end

--------------------------------------------------------------------------------
-- 2. CONSTRUCCIÓN DEL LOBBY
--------------------------------------------------------------------------------
local function clearArea()
	-- Eliminar conflictos de nombres antiguos o duplicados
	local objectsToRemove = {
		CONFIG.LobbyName,
		"LobbyIsland", -- Nombre antiguo conflictivo
		"Baseplate",   -- Default de Roblox
		"Decorations"  -- Posible carpeta de decoraciones antiguas
	}

	for _, name in ipairs(objectsToRemove) do
		local obj = Workspace:FindFirstChild(name)
		if obj then obj:Destroy() end
	end
end

local function createWalls(floor)
	local w, h, d = floor.Size.X, CONFIG.WallHeight, floor.Size.Z
	
	local function addWall(name, size, cf)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = size
		wall.CFrame = cf
		wall.Anchored = true
		wall.BrickColor = CONFIG.Color
		wall.Material = Enum.Material.Concrete
		wall.Parent = floor
	end

	-- Paredes (Front/Back/Left/Right)
	addWall("Wall_Back",  Vector3.new(w, h, 1), floor.CFrame * CFrame.new(0, h/2, -d/2))
	addWall("Wall_Front", Vector3.new(w, h, 1), floor.CFrame * CFrame.new(0, h/2, d/2))
	addWall("Wall_Left",  Vector3.new(1, h, d), floor.CFrame * CFrame.new(-w/2, h/2, 0))
	addWall("Wall_Right", Vector3.new(1, h, d), floor.CFrame * CFrame.new(w/2, h/2, 0))
end

local function createLobby()
	print("🏗️ Generando Lobby Optimizado...")
	clearArea()
	setupLighting()

	-- 1. Suelo Principal
	local floor = Instance.new("Part")
	floor.Name = CONFIG.LobbyName
	floor.Size = CONFIG.Size
	floor.Position = CONFIG.Position
	floor.Anchored = true
	floor.BrickColor = CONFIG.Color
	floor.Material = CONFIG.Material
	floor.Parent = Workspace

	-- 2. Paredes
	createWalls(floor)

	-- 3. Spawn Point Seguro
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = floor.Position + Vector3.new(0, CONFIG.Size.Y/2 + 0.5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = Workspace

	-- 4. Océano "Mortal" (Safety Net)
	local ocean = Instance.new("Part")
	ocean.Name = "DeadlyVoid"
	ocean.Size = Vector3.new(2048, 1, 2048)
	ocean.Position = Vector3.new(0, -50, 0)
	ocean.Transparency = 0.5
	ocean.BrickColor = BrickColor.new("Black")
	ocean.Anchored = true
	ocean.CanCollide = false
	ocean.Parent = Workspace

	-- Señal para otros scripts
	Workspace:SetAttribute("LobbyReady", true)
	print("✅ Lobby generado exitosamente en (0,0,0).")

	return floor
end

--------------------------------------------------------------------------------
-- 3. EJECUCIÓN
--------------------------------------------------------------------------------
createLobby()
