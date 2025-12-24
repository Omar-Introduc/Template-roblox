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

	local root = ReplicatedStorage:FindFirstChild(TEMPLATES_NAME)
	if root then root:Destroy() end -- Reset limpio

	root = Instance.new("Folder")
	root.Name = TEMPLATES_NAME
	root.Parent = ReplicatedStorage

	local folders = {}
	for i = 1, LEVEL_COUNT do
		local f = Instance.new("Folder")
		f.Name = "Level" .. i
		f.Parent = root
		folders[i] = f
	end

	return root, folders
end

--------------------------------------------------------------------------------
-- 2. GENERADORES DE PREFABS
--------------------------------------------------------------------------------

-- A. Starter Pad (El activador del camino)
local function createStarterPad(levelFolder)
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
	-- Nota: ParkourSystem clonará esto, la animación debe ser manejada allí o con un script local si se desea.
	
	pad.Parent = levelFolder
	return pad
end

-- B. Bloque de Parkour (Plataforma de salto)
local function createParkourBlock(levelFolder, levelIndex)
	local block = Instance.new("Part")
	block.Name = "ParkourBlock"
	block.Size = Vector3.new(10, 0.5, 10)
	block.Anchored = true
	block.Material = Enum.Material.Plastic
	
	-- Estilizado básico por defecto (será sobreescrito por el sistema de biomas)
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

	block.Parent = levelFolder
	return block
end

-- C. Plataforma de Nivel (Isla segura)
local function createLevelPlatform(levelFolder, levelIndex)
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
		-- Añadir aquí otros assets personalizados
	}
	
	for _, map in ipairs(mappings) do
		local sourceObj = assetStorage:FindFirstChild(map.source)
		if sourceObj and folders[map.level] then
			-- Eliminar el generado por defecto si existe para reemplazarlo
			local existing = folders[map.level]:FindFirstChild(map.target)
			if existing then existing:Destroy() end

			local clone = sourceObj:Clone()
			clone.Name = map.target
			clone.Parent = folders[map.level]
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

-- Señal de finalización
local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Value = "True"
readyVal.Parent = templatesRoot

print("✅ PrefabFactory: Sistema de Templates (1-"..LEVEL_COUNT..") listo para ParkourSystem.")
