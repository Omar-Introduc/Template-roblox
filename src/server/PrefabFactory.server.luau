local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TEMPLATES_FOLDER_NAME = "Templates"

-- 1. Check and Clean/Create Folder
print("🏭 PrefabFactory: Starting initialization...")
local templates = ReplicatedStorage:FindFirstChild(TEMPLATES_FOLDER_NAME)
if templates then
	templates:ClearAllChildren()
	print("🏭 PrefabFactory: Cleaned existing templates.")
else
	templates = Instance.new("Folder")
	templates.Name = TEMPLATES_FOLDER_NAME
	templates.Parent = ReplicatedStorage
	print("🏭 PrefabFactory: Created new Templates folder in ReplicatedStorage.")
end

-- 2. External Assets Integration (ROJO Sync)
local function loadExternalAssets()
	local assetFolder = ReplicatedStorage:WaitForChild("asset", 10)
	if not assetFolder then
		warn("⚠️ PrefabFactory: 'asset' folder not found in ReplicatedStorage. External platforms skipped.")
		return
	end

	local function setupPlatformTemplate(assetName, templateName)
		local source = assetFolder:FindFirstChild(assetName)
		if source then
			local clone = source:Clone()
			clone.Name = templateName
			clone.Parent = templates
			print("✅ PrefabFactory: Loaded external template: " .. templateName)
		else
			warn("⚠️ PrefabFactory: Asset '" .. assetName .. "' not found. Using procedural fallback.")
		end
	end

	setupPlatformTemplate("plataforma1", "Level1Block")
	setupPlatformTemplate("plataforma2", "Level2Block")
end

-- 3. Factory functions for Master Prefabs
local function createMasterBlock()
	local block = Instance.new("Part")
	block.Name = "MasterBlock"
	block.Size = Vector3.new(12, 0.5, 12)
	block.Anchored = true
	
	-- Optimized Physics
	block.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5) -- Friction = 1

	-- Festive Style (Anti-Glare)
	block.Material = Enum.Material.SmoothPlastic
	block.Reflectance = 0.1
	block.Color = Color3.fromRGB(100, 200, 255)

	-- Neon Border SelectionBox
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Name = "NeonBorder"
	selectionBox.Adornee = block
	selectionBox.LineThickness = 0.1
	selectionBox.Transparency = 0.1
	selectionBox.Parent = block

	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TimerGui"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = block

	local label = Instance.new("TextLabel")
	label.Name = "TimerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "0.0"

	-- Pulsing Highlight Effect
	local highlight = Instance.new("Highlight")
	highlight.Name = "BlockHighlight"
	highlight.Adornee = block
	highlight.FillTransparency = 0.9 -- Reduced glare
	highlight.OutlineColor = Color3.fromRGB(200, 255, 255)
	highlight.OutlineTransparency = 0.5
	highlight.Parent = block

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 6
	stroke.Color = Color3.new(0, 0, 0)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label

	label.Parent = surfaceGui

	-- SFX: Jump Sound
	local jumpSound = Instance.new("Sound")
	jumpSound.Name = "JumpSound"
	jumpSound.SoundId = "rbxassetid://4607031412" -- Pop SFX
	jumpSound.Volume = 0.5
	jumpSound.Parent = block

	block.Parent = templates
end

local function createBombGift()
	local model = Instance.new("Model")
	model.Name = "BombGift"
	
	local box = Instance.new("Part")
	box.Name = "Handle"
	box.Size = Vector3.new(4, 4, 4)
	box.Color = Color3.fromRGB(255, 0, 0)
	box.Material = Enum.Material.Fabric
	box.Anchored = true
	box.Parent = model
	
	-- Festive Ribbon (Cross)
	local r1 = Instance.new("Part")
	r1.Size = Vector3.new(4.1, 0.5, 1)
	r1.Color = Color3.fromRGB(0, 200, 0)
	r1.Material = Enum.Material.Neon
	r1.Anchored = true
	r1.CFrame = box.CFrame
	r1.Parent = model
	
	local r2 = r1:Clone()
	r2.Size = Vector3.new(1, 0.5, 4.1)
	r2.Parent = model
	
	-- Tag for Identification
	CollectionService:AddTag(box, "GiftBomb")
	model.PrimaryPart = box
	model.Parent = templates
end

local function createMasterPlatform()
	local platform = Instance.new("Part")
	platform.Name = "MasterPlatform"
	platform.Shape = Enum.PartType.Block
	platform.Size = Vector3.new(25, 2, 25)
	platform.Anchored = true
	
	-- Visibility Glow
	local light = Instance.new("PointLight")
	light.Range = 35
	light.Brightness = 1.2 -- Reduced from 3
	light.Parent = platform

	platform.Parent = templates
end

local function createMasterPad()
	local pad = Instance.new("Part")
	pad.Name = "MasterPad"
	pad.Size = Vector3.new(12, 1, 12)
	pad.Anchored = true
	
	-- Particles for visibility
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "PadBeacon"
	particles.Texture = "rbxassetid://244221440" -- Flare/Star
	particles.Size = NumberSequence.new(0.5, 0)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 10
	particles.Speed = NumberRange.new(2, 5)
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Color = ColorSequence.new(Color3.new(1, 1, 0))
	particles.Parent = pad

	pad.Parent = templates
end

local function createMasterGem()
	local gem = Instance.new("Part")
	gem.Name = "MasterGem"
	gem.Size = Vector3.new(1.5, 2.5, 1.5)
	gem.Shape = Enum.PartType.Ball
	gem.Material = Enum.Material.Neon
	gem.Color = Color3.fromRGB(255, 255, 255)
	gem.Transparency = 0.3
	gem.Anchored = true
	gem.CanCollide = false

	CollectionService:AddTag(gem, "CollectionItem")

	local light = Instance.new("PointLight")
	light.Name = "GemLight"
	light.Range = 10
	light.Brightness = 1.2 -- Reduced from 3
	light.Parent = gem

	-- SFX: Gem Sound
	local gemSound = Instance.new("Sound")
	gemSound.Name = "GemSound"
	gemSound.SoundId = "rbxassetid://1510219102" -- Coin Collect
	gemSound.Volume = 0.6
	gemSound.Parent = gem

	gem.Parent = templates
end

local function createHexPlatformFallback()
	if templates:FindFirstChild("HexPlatform_V2") then return end
	
	print("⚠️ PrefabFactory: Creating Procedural HexPlatform_V2 (Asset missing)")
	local model = Instance.new("Model")
	model.Name = "HexPlatform_V2"
	
	local part = Instance.new("Part")
	part.Name = "Base"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(1, 15, 15) -- Cylinder is sideways
	part.Rotation = Vector3.new(0, 0, 90)
	part.Color = Color3.fromHex("#ffffff")
	part.Material = Enum.Material.Glass
	part.Anchored = true
	part.Parent = model
	
	-- Neon Rim
	local rim = Instance.new("Part")
	rim.Name = "Rim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(1.1, 15.5, 15.5)
	rim.Rotation = Vector3.new(0, 0, 90)
	rim.Color = Color3.fromHex("#00ffff")
	rim.Material = Enum.Material.Neon
	rim.Anchored = true
	rim.Parent = model
	
	model.PrimaryPart = part
	model.Parent = templates
end

local function createPhysicalShopSign()
	-- 1. BASE FÍSICA (El Cristal)
	-- Equivalente a: new THREE.BoxGeometry(16, 9, 0.4)
	local anchor = Instance.new("Part")
	anchor.Name = "FloatingShopSign"
	anchor.Size = Vector3.new(16, 9, 0.5) -- Escala en Studs (Ratio 16:9)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Material = Enum.Material.Glass -- Material Cristal
	anchor.Color = Color3.fromHex("#0a0a12") -- Color base oscuro
	anchor.Transparency = 0.8 -- Equivalente a opacity: 0.6 + transmission
	anchor.Reflectance = 0.5 -- Brillo del cristal
	anchor.CastShadow = false
	anchor.Parent = templates
	
	-- 2. EFECTO DE BORDE NEÓN (Glow)
	-- Equivalente a: borderMat (Three.js) + backLight
	local highlight = Instance.new("Highlight")
	highlight.Name = "NeonGlow"
	highlight.Adornee = anchor
	highlight.FillTransparency = 1 -- Solo queremos el borde
	highlight.OutlineColor = Color3.fromHex("#a855f7") -- Púrpura Cyberpunk
	highlight.OutlineTransparency = 0
	highlight.Parent = anchor

	-- 3. PARTÍCULAS CYBERPUNK
	-- Equivalente a: particlesGeo (Three.js)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "CyberDust"
	particles.Texture = "rbxassetid://244221440" -- Textura de punto/brillo suave
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#22d3ee")), -- Cyan
		ColorSequenceKeypoint.new(1, Color3.fromHex("#a855f7"))  -- Púrpura
	})
	particles.Size = NumberSequence.new(0.1, 0)
	particles.Lifetime = NumberRange.new(2, 4)
	particles.Rate = 20
	particles.Speed = NumberRange.new(0.5, 1)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = anchor

	-- 4. SURFACE GUI (La Interfaz Gráfica)
	-- Equivalente a: canvasUI (Three.js)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ShopDisplay"
	surfaceGui.Adornee = anchor
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.CanvasSize = Vector2.new(1600, 900) -- Resolución exacta de tu Canvas HTML
	surfaceGui.LightInfluence = 0 -- Auto-iluminado (Neon UI)
	surfaceGui.AlwaysOnTop = false -- User requested: "no traspase todas las vistas" (Fix X-Ray effect)
	surfaceGui.Parent = anchor

	-- Fondo Base (Oscuro translúcido)
	local bg = Instance.new("Frame")
	bg.Name = "Frame"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromHex("#0a0a12")
	bg.BackgroundTransparency = 0.1
	bg.BorderSizePixel = 0
	bg.Parent = surfaceGui

	-- --- SIDEBAR (Izquierda) ---
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 400, 1, 0) -- 400px ancho
	sidebar.BackgroundColor3 = Color3.new(0,0,0)
	sidebar.BackgroundTransparency = 0.4
	sidebar.BorderSizePixel = 0
	sidebar.Parent = bg
	
	-- Línea divisoria
	local divLine = Instance.new("Frame")
	divLine.Size = UDim2.new(0, 2, 1, 0)
	divLine.Position = UDim2.new(1, 0, 0, 0)
	divLine.BackgroundColor3 = Color3.new(1,1,1)
	divLine.BackgroundTransparency = 0.9
	divLine.Parent = sidebar

	-- Título TOKYO SHOP
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = '<font color="#ffffff">TOKYO</font> <font color="#22d3ee">SHOP</font>'
	titleLabel.RichText = true
	titleLabel.Size = UDim2.new(1, 0, 0, 100)
	titleLabel.Position = UDim2.new(0, 40, 0, 40)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 60
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = sidebar
	
	local subTitle = Instance.new("TextLabel")
	subTitle.Text = "SYSTEM V7.5 // 3D"
	subTitle.Size = UDim2.new(1, 0, 0, 50)
	subTitle.Position = UDim2.new(0, 40, 0, 110)
	subTitle.BackgroundTransparency = 1
	subTitle.TextColor3 = Color3.fromHex("#94a3b8")
	subTitle.Font = Enum.Font.Gotham
	subTitle.TextSize = 30
	subTitle.TextXAlignment = Enum.TextXAlignment.Left
	subTitle.Parent = sidebar

	-- --- CONTENIDO PRINCIPAL (Derecha) ---
	local mainContent = Instance.new("Frame")
	mainContent.Name = "MainContent"
	mainContent.Position = UDim2.new(0, 450, 0, 150)
	mainContent.Size = UDim2.new(0, 1100, 0, 600)
	mainContent.BackgroundTransparency = 1
	mainContent.Parent = bg

	-- Grid Layout para productos
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 540, 0, 260)
	gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
	gridLayout.FillDirectionMaxCells = 2
	gridLayout.Parent = mainContent

	-- Función interna para crear Tarjetas de Producto (Estilo V7.5)
	local function createCard(name, price, colorHex)
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.new(1,1,1)
		card.BackgroundTransparency = 0.95
		card.Parent = mainContent
		
		-- Borde de color (Stroke)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromHex(colorHex)
		stroke.Thickness = 2
		stroke.Transparency = 0.5
		stroke.Parent = card

		-- Icono cuadrado
		local icon = Instance.new("Frame")
		icon.Size = UDim2.fromOffset(80, 80)
		icon.Position = UDim2.new(0, 20, 0, 20)
		icon.BackgroundColor3 = Color3.fromHex(colorHex)
		icon.BackgroundTransparency = 0.8
		icon.Parent = card

		-- Nombre Producto
		local pName = Instance.new("TextLabel")
		pName.Text = name
		pName.Size = UDim2.new(1, -40, 0, 40)
		pName.Position = UDim2.new(0, 20, 0, 120)
		pName.TextColor3 = Color3.new(1,1,1)
		pName.Font = Enum.Font.GothamBold
		pName.TextSize = 30
		pName.TextXAlignment = Enum.TextXAlignment.Left
		pName.BackgroundTransparency = 1
		pName.Parent = card

		-- Botón COMPRAR
		local btn = Instance.new("TextButton")
		btn.Name = "BuyButton" -- Importante: No cambiar el nombre para que ShopUI funcione
		btn.Text = "COMPRAR ["..price.."]"
		btn.Size = UDim2.fromOffset(200, 60)
		btn.Position = UDim2.new(1, -220, 1, -80)
		btn.BackgroundColor3 = Color3.new(1,1,1)
		btn.TextColor3 = Color3.new(0,0,0)
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 20
		btn.Parent = card
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.Parent = btn
	end

	-- Generar productos simulados
	createCard("Velocidad Sónica", 50, "#22d3ee") -- Cyan
	createCard("Salto Gravitatorio", 100, "#a855f7") -- Purple
	createCard("Escudo Fantasma", 200, "#22c55e") -- Green
	createCard("ABRIR TIENDA", "???", "#facc15") -- Yellow (Botón principal)
	
	-- Noticia Footer (Alerta Roja)
	local footer = Instance.new("Frame")
	footer.Size = UDim2.new(0, 1100, 0, 100)
	footer.Position = UDim2.new(0, 450, 0, 780)
	footer.BackgroundColor3 = Color3.fromHex("#422006") -- Dark Orange
	footer.BorderSizePixel = 0
	footer.Parent = bg
	
	local fStroke = Instance.new("UIStroke")
	fStroke.Color = Color3.fromHex("#eab308")
	fStroke.Thickness = 4
	fStroke.Parent = footer
	
	local fText = Instance.new("TextLabel")
	fText.Text = "OFERTA LIMITADA: PAQUETE GOLDEN"
	fText.Size = UDim2.fromScale(1, 1)
	fText.TextColor3 = Color3.new(1,1,1)
	fText.Font = Enum.Font.GothamBold
	fText.TextSize = 35
	fText.BackgroundTransparency = 1
	fText.Parent = footer
end

createMasterBlock()
createBombGift()
createMasterPlatform()
createMasterPad()
createMasterGem()
createPhysicalShopSign()
loadExternalAssets()
createHexPlatformFallback() -- Critical fallback

local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Value = "Ready"
readyVal.Parent = templates
templates:SetAttribute("PrefabReady", true)
print("🏭 PrefabFactory: Ready signal sent!")
