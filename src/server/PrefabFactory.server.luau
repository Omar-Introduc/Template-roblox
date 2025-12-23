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

-- 2. Factory functions for Master Prefabs
local function createMasterBlock()
	local block = Instance.new("Part")
	block.Name = "MasterBlock"
	block.Size = Vector3.new(12, 0.5, 12)
	block.Anchored = true
	
	-- Optimized Physics
	block.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5) -- Friction = 1

	-- Festive Style (Default to Ice Blue)
	block.Material = Enum.Material.Neon
	block.Color = Color3.fromRGB(180, 240, 255)

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
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.new(1, 1, 1)
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
	light.Brightness = 3
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
	light.Brightness = 3
	light.Parent = gem

	-- SFX: Gem Sound
	local gemSound = Instance.new("Sound")
	gemSound.Name = "GemSound"
	gemSound.SoundId = "rbxassetid://1510219102" -- Coin Collect
	gemSound.Volume = 0.6
	gemSound.Parent = gem

	gem.Parent = templates
end

local function createPhysicalShopSign()
	local anchor = Instance.new("Part")
	anchor.Name = "FloatingShopSign"
	anchor.Size = Vector3.new(10, 7, 0.2)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = templates
	
	-- Partículas de "Polvo Mágico"
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "SignGlow"
	particles.Texture = "rbxassetid://244221440" -- Estrella
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
	particles.Size = NumberSequence.new(0.2, 0)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 5
	particles.Speed = NumberRange.new(1, 3)
	particles.Parent = anchor

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ShopDisplay"
	surfaceGui.Adornee = anchor
	surfaceGui.CanvasSize = Vector2.new(1000, 700)
	surfaceGui.Parent = anchor

	-- Contenedor Principal (Estilo Periódico)
	local bg = Instance.new("Frame")
	bg.Name = "Frame"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(245, 245, 220)
	bg.Parent = surfaceGui

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Thickness = 4
	bgStroke.Color = Color3.new(0, 0, 0)
	bgStroke.Parent = bg

	-- Texto "ÚLTIMA HORA"
	local newsFlash = Instance.new("TextLabel")
	newsFlash.Name = "NewsFlash"
	newsFlash.Size = UDim2.new(1, 0, 0.15, 0)
	newsFlash.Text = "🚨 ¡EL VOLCÁN DEL NIVEL 3 ESTÁ ACTIVÁNDOSE! 🚨"
	newsFlash.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	newsFlash.TextColor3 = Color3.fromRGB(255, 255, 255)
	newsFlash.Font = Enum.Font.GothamBold
	newsFlash.TextScaled = true
	newsFlash.Parent = bg

	-- Sección de Compra (Interactiva)
	local buySection = Instance.new("Frame")
	buySection.Name = "BuySection"
	buySection.Position = UDim2.new(0.1, 0, 0.25, 0)
	buySection.Size = UDim2.new(0.8, 0, 0.6, 0)
	buySection.BackgroundTransparency = 1
	buySection.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.05, 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = buySection

	-- Función interna para crear botones
	local function createItem(name, cost)
		local btn = Instance.new("TextButton")
		btn.Name = "Item_" .. name:gsub(" ", "")
		btn.Size = UDim2.new(1, 0, 0.4, 0)
		btn.Text = "Comprar " .. name .. " [" .. cost .. " Gems]"
		btn.Font = Enum.Font.SpecialElite
		btn.TextScaled = true
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = buySection
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Parent = btn

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = btn

		return btn
	end

	createItem("Super Salto", 100)
	local mainBtn = createItem("ABRIR TIENDA", "???")
	mainBtn.Name = "BuyButton" -- For consistency with click detection
	mainBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	mainBtn.TextColor3 = Color3.new(1, 1, 1)
end

createMasterBlock()
createBombGift()
createMasterPlatform()
createMasterPad()
createMasterGem()
createPhysicalShopSign()

local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Value = "Ready"
readyVal.Parent = templates
templates:SetAttribute("PrefabReady", true)
print("🏭 PrefabFactory: Ready signal sent!")
