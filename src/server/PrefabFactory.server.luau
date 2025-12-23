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

-- 4. Signal Ready
print("🏭 PrefabFactory: Creating Master Prefabs...")
createMasterBlock()
createMasterPlatform()
createMasterPad()
createMasterGem()

local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Value = "Ready"
readyVal.Parent = templates
print("🏭 PrefabFactory: Ready signal sent!")
