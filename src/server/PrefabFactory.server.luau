--[[
    🏭 PrefabFactory - Asset Management System

    Responsabilidad: Crear y organizar los modelos base (Prefabs) para cada nivel.
    Asegura que 'StarterPad' sea visible (Amarillo Neón) y accesible.

    Autor: Arquitecto de Sistemas Roblox (IA)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TEMPLATES_NAME = "Templates"
local LEVEL_COUNT = 4

--------------------------------------------------------------------------------
-- 1. CONFIGURACIÓN DE CARPETAS
--------------------------------------------------------------------------------
local function setupFolders()
	print("🏭 PrefabFactory: Inicializando estructura de carpetas...")

	-- CORRECCIÓN: No destruir la carpeta si existe, para evitar condición de carrera con PlatformFactory/CharizardFactory
	local root = ReplicatedStorage:FindFirstChild(TEMPLATES_NAME)
	if not root then
		root = Instance.new("Folder")
		root.Name = TEMPLATES_NAME
		root.Parent = ReplicatedStorage
	end

	local folders = {}
	for i = 1, LEVEL_COUNT do
		local folderName = "Level" .. i
		local f = root:FindFirstChild(folderName)
		if not f then
			f = Instance.new("Folder")
			f.Name = folderName
			f.Parent = root
		end
		folders[i] = f
	end

	return root, folders
end

--------------------------------------------------------------------------------
-- 2. GENERADORES DE PREFABS
--------------------------------------------------------------------------------

-- Helper para Timer Visual
local function createTimerGui(parent)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TimerGui"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.CanvasSize = Vector2.new(200, 200)
	surfaceGui.Adornee = parent

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TimerLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "..."
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.Parent = surfaceGui

	surfaceGui.Parent = parent
	return surfaceGui
end

-- A. Starter Pad (El activador del camino)
local function createStarterPad(levelFolder)
	if levelFolder:FindFirstChild("StarterPad") then return end -- No duplicar si ya existe

	local pad = Instance.new("Part")
	pad.Name = "StarterPad"
	pad.Size = Vector3.new(8, 0.5, 8)
	pad.Anchored = true
	pad.CanCollide = true
	
	-- REQUISITO CRÍTICO: Amarillo Neón para alta visibilidad
	pad.Color = Color3.fromRGB(255, 255, 0)
	pad.Material = Enum.Material.Neon
	
	-- Efectos Visuales (Partículas para llamar la atención)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Glow"
	emitter.Texture = "rbxassetid://296874871" -- Textura suave
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
	emitter.Size = NumberSequence.new(1)
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Rate = 4
	emitter.Speed = NumberRange.new(2)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = pad

	-- Indicador Flotante (Flecha/Boya)
	local marker = Instance.new("Part")
	marker.Name = "Marker"
	marker.Size = Vector3.new(1, 1, 1)
	marker.Shape = Enum.PartType.Ball
	marker.Color = Color3.fromRGB(255, 255, 0)
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.3
	marker.Position = pad.Position + Vector3.new(0, 4, 0)
	marker.CanCollide = false
	marker.Anchored = true
	
	pad.Parent = levelFolder
	return pad
end

-- B. Bloque de Parkour (Plataforma de salto)
local function createParkourBlock(levelFolder, levelIndex)
	if levelFolder:FindFirstChild("ParkourBlock") then return end

	local block = Instance.new("Part")
	block.Name = "ParkourBlock"
	block.Size = Vector3.new(10, 0.5, 10)
	block.Anchored = true
	block.Material = Enum.Material.Plastic
	
	-- Estilizado básico por defecto
	block.Color = Color3.fromRGB(200, 200, 200)

	-- Highlight para visibilidad
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.Parent = block
	
	-- Sonido de Salto
	local sfx = Instance.new("Sound")
	sfx.Name = "JumpSound"
	sfx.SoundId = "rbxassetid://12221967" -- Sonido "Pop" genérico
	sfx.Parent = block

	-- CORRECCIÓN: Añadir TimerGui para visualización del tiempo restante (Cliente lo espera)
	createTimerGui(block)

	-- CORRECCIÓN: Añadir BiomeEffect (ParticleEmitter) que el cliente espera para VFX
	local effect = Instance.new("ParticleEmitter")
	effect.Name = "BiomeEffect"
	effect.Texture = "rbxassetid://243098098" -- Textura genérica de partícula
	effect.Rate = 0 -- Se activa por el cliente (Emit)
	effect.Speed = NumberRange.new(5)
	effect.Lifetime = NumberRange.new(0.5, 1)
	effect.Parent = block

	block.Parent = levelFolder
	return block
end

-- C. Plataforma de Nivel (Isla segura)
local function createLevelPlatform(levelFolder, levelIndex)
	if levelFolder:FindFirstChild("LevelPlatform") then return end

	local plat = Instance.new("Part")
	plat.Name = "LevelPlatform"
	plat.Size = Vector3.new(40, 2, 40)
	plat.Anchored = true
	plat.Material = Enum.Material.SmoothPlastic
	plat.Color = Color3.fromRGB(50, 50, 60)
	
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 2
	light.Parent = plat
	
	plat.Parent = levelFolder
	return plat
end

--------------------------------------------------------------------------------
-- 3. INTEGRACIÓN DE ASSETS EXTERNOS
--------------------------------------------------------------------------------
local function loadAssetsIntoFolders(folders)
	local assetStorage = ReplicatedStorage:FindFirstChild("asset")
	if not assetStorage then
		warn("⚠️ PrefabFactory: Carpeta 'asset' no encontrada. Usando generadores por defecto.")
		return
	end
	
	-- Mapeo: Nombre en 'asset' -> Nombre destino, Nivel destino
	local mappings = {
		{ source = "plataforma1", target = "ParkourBlock", level = 1 },
		{ source = "plataforma2", target = "ParkourBlock", level = 2 },
		{ source = "plataforma3", target = "ParkourBlock", level = 3 },
		{ source = "plataforma4", target = "ParkourBlock", level = 4 },
	}
	
	for _, map in ipairs(mappings) do
		local sourceObj = assetStorage:FindFirstChild(map.source)
		if sourceObj and folders[map.level] then
			-- Eliminar el generado por defecto si existe
			local existing = folders[map.level]:FindFirstChild(map.target)
			if existing then existing:Destroy() end

			local clone = sourceObj:Clone()
			clone.Name = map.target
			clone.Parent = folders[map.level]

			-- Asegurarnos de que tenga los componentes necesarios si es un ParkourBlock
			if map.target == "ParkourBlock" then
				if not clone:FindFirstChild("TimerGui") then
					createTimerGui(clone)
				end
				if not clone:FindFirstChild("BiomeEffect") then
					local effect = Instance.new("ParticleEmitter")
					effect.Name = "BiomeEffect"
					effect.Texture = "rbxassetid://243098098"
					effect.Rate = 0
					effect.Parent = clone
				end
			end

			print(string.format("   > Asset '%s' asignado a Nivel %d", map.source, map.level))
		end
	end
end

--------------------------------------------------------------------------------
-- 4. EJECUCIÓN PRINCIPAL
--------------------------------------------------------------------------------
local templatesRoot, levelFolders = setupFolders()

-- Generar básicos para todos los niveles
for i = 1, LEVEL_COUNT do
	createStarterPad(levelFolders[i])
	createParkourBlock(levelFolders[i], i)
	createLevelPlatform(levelFolders[i], i)
end

-- Sobrescribir con assets artísticos si existen
loadAssetsIntoFolders(levelFolders)

-- Señal de finalización UNIFICADA (Usa atributo para CharizardBot y Tests)
templatesRoot:SetAttribute("PrefabReady", true)

-- Mantenemos compatibilidad hacia atrás por si acaso, aunque el atributo es el estándar ahora
local readyVal = templatesRoot:FindFirstChild("FactoryReady") or Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Value = "True"
readyVal.Parent = templatesRoot

print("✅ PrefabFactory: Sistema de Templates (1-"..LEVEL_COUNT..") listo para ParkourSystem.")
