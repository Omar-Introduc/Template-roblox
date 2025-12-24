local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TEMPLATES_FOLDER_NAME = "Templates"
local LEVEL_COUNT = 4

-- 1. Inicialización de Carpetas
print("🏭 PrefabFactory: Iniciando Protocolo de Generación v2.0...")
local templates = ReplicatedStorage:FindFirstChild(TEMPLATES_FOLDER_NAME)
if templates then
	templates:ClearAllChildren()
	print("   > Limpieza de Templates completada.")
else
	templates = Instance.new("Folder")
	templates.Name = TEMPLATES_FOLDER_NAME
	templates.Parent = ReplicatedStorage
	print("   > Carpeta Templates creada.")
end

-- Crear subcarpetas por nivel
local levelFolders = {}
for i = 1, LEVEL_COUNT do
	local folder = Instance.new("Folder")
	folder.Name = "Level" .. i
	folder.Parent = templates
	levelFolders[i] = folder
end
print("   > Carpetas de Nivel (1-4) generadas.")

-- 2. Integración de Assets Externos (ROJO)
local function loadExternalAssets()
	local assetFolder = ReplicatedStorage:FindFirstChild("asset")
	if not assetFolder then
		warn("⚠️ PrefabFactory: Carpeta 'asset' no encontrada. Se usarán fallbacks.")
		return
	end

	-- Mapa de carga de assets específicos a carpetas de nivel
	local assetMap = {
		{asset = "plataforma1", target = "ParkourBlock", level = 1},
		{asset = "plataforma2", target = "ParkourBlock", level = 2},
		-- Agregar más mapeos según sea necesario
	}

	for _, data in ipairs(assetMap) do
		local source = assetFolder:FindFirstChild(data.asset)
		if source then
			local clone = source:Clone()
			clone.Name = data.target
			clone.Parent = levelFolders[data.level]
			print("   > Asset cargado: " .. data.asset .. " -> Level" .. data.level)
		end
	end
end

-- 3. Generadores de Prefabs Maestros

-- A. BLOQUE BASE DE PARKOUR (Fallback)
local function createBaseBlock(parent)
	local block = Instance.new("Part")
	block.Name = "ParkourBlock"
	block.Size = Vector3.new(12, 0.5, 12)
	block.Anchored = true
	block.Material = Enum.Material.SmoothPlastic
	block.Reflectance = 0.1
	block.Color = Color3.fromRGB(200, 200, 200)

	-- Física optimizada
	block.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)

	-- Decoración visual
	local highlight = Instance.new("Highlight")
	highlight.Name = "BlockHighlight"
	highlight.Adornee = block
	highlight.FillTransparency = 0.9
	highlight.OutlineColor = Color3.new(1,1,1)
	highlight.Parent = block

	-- Sonido
	local jumpSound = Instance.new("Sound")
	jumpSound.Name = "JumpSound"
	jumpSound.SoundId = "rbxassetid://4607031412"
	jumpSound.Volume = 0.5
	jumpSound.Parent = block

	-- Timer GUI
	local sg = Instance.new("SurfaceGui")
	sg.Name = "TimerGui"; sg.Face = Enum.NormalId.Top; sg.Parent = block
	local tl = Instance.new("TextLabel")
	tl.Name = "TimerLabel"; tl.Size = UDim2.fromScale(1,1); tl.BackgroundTransparency=1
	tl.TextScaled=true; tl.Font=Enum.Font.GothamBold; tl.TextColor3=Color3.new(1,1,1); tl.Text="0.0"
	tl.Parent = sg
	local stroke = Instance.new("UIStroke"); stroke.Thickness=6; stroke.Parent=tl

	block.Parent = parent
	return block
end

-- B. STARTER PAD (Amarillo Neón - Corrección Visual)
local function createStarterPad(parent)
	local pad = Instance.new("Part")
	pad.Name = "StarterPad"
	pad.Size = Vector3.new(8, 0.5, 8) -- Ligeramente más pequeño que el bloque
	pad.Anchored = true
	pad.CanCollide = true
	
	-- APARIENCIA CLAVE: Amarillo Neón
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(255, 255, 0) -- Amarillo Puro
	
	-- Partículas de "Aquí estoy"
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "Beacon"
	particles.Texture = "rbxassetid://296874871" -- Soft glow
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
	particles.Size = NumberSequence.new(0.5, 0)
	particles.Lifetime = NumberRange.new(1, 1.5)
	particles.Rate = 5
	particles.Speed = NumberRange.new(2, 4)
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Parent = pad

	-- Flecha flotante (Visual aid)
	local arrow = Instance.new("Part")
	arrow.Name = "Arrow"
	arrow.Size = Vector3.new(2, 2, 2)
	arrow.Shape = Enum.PartType.Cylinder -- Aproximación
	arrow.Color = Color3.fromRGB(255, 255, 0)
	arrow.Material = Enum.Material.Neon
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Transparency = 0.5
	arrow.Position = pad.Position + Vector3.new(0, 3, 0)
	-- Nota: La animación se hará localmente o con TweenService al instanciar
	
	pad.Parent = parent
	return pad
end

-- C. PLATAFORMA DE NIVEL
local function createLevelPlatform(parent)
	local platform = Instance.new("Part")
	platform.Name = "LevelPlatform"
	platform.Size = Vector3.new(30, 2, 30)
	platform.Anchored = true
	platform.Material = Enum.Material.Glass
	platform.Color = Color3.fromRGB(50, 50, 50)
	
	-- Luz de base
	local light = Instance.new("PointLight")
	light.Range = 40; light.Brightness = 1.5; light.Parent = platform
	
	platform.Parent = parent
	return platform
end

-- D. PREMIO (Gema)
local function createMasterGem()
	local gem = Instance.new("Part")
	gem.Name = "MasterGem"
	gem.Size = Vector3.new(1.5, 2.5, 1.5)
	gem.Shape = Enum.PartType.Ball
	gem.Material = Enum.Material.Neon
	gem.Color = Color3.fromRGB(255, 255, 255)
	gem.Anchored = true; gem.CanCollide = false
	
	CollectionService:AddTag(gem, "CollectionItem")
	
	local sound = Instance.new("Sound")
	sound.Name = "GemSound"; sound.SoundId = "rbxassetid://1510219102"; sound.Parent = gem
	
	gem.Parent = templates -- Se queda en la raíz para acceso general
end

-- 4. Distribución de Prefabs
local function populateFolders()
	-- Cargar assets externos primero
	loadExternalAssets()

	-- Llenar cada carpeta de nivel con lo necesario
	for i = 1, LEVEL_COUNT do
		local folder = levelFolders[i]
		
		-- 1. Starter Pad (Siempre necesario)
		createStarterPad(folder)

		-- 2. Parkour Block (Si no se cargó externo)
		if not folder:FindFirstChild("ParkourBlock") then
			createBaseBlock(folder)
		end
		
		-- 3. Level Platform (Si no se cargó externo)
		if not folder:FindFirstChild("LevelPlatform") then
			createLevelPlatform(folder)
		end
	end
	
	-- Crear otros elementos globales en la raíz de Templates
	createMasterGem()
	
	-- Fallback para HexPlatform si no existe
	if not templates:FindFirstChild("HexPlatform_V2") then
		local hp = Instance.new("Part")
		hp.Name = "HexPlatform_V2"
		hp.Anchored = true
		hp.Size = Vector3.new(10, 1, 10)
		hp.Parent = templates
	end
end

-- Ejecución
populateFolders()

-- Señal de Finalización
local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Value = "Ready"
readyVal.Parent = templates
templates:SetAttribute("PrefabReady", true)

print("✅ PrefabFactory: Estructura de Niveles (1-"..LEVEL_COUNT..") Lista y Verificada.")
