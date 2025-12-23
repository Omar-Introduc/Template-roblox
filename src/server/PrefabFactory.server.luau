local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local TEMPLATES_FOLDER_NAME = "Templates"

-- 1. Check and Clean/Create Folder
local templates = ServerStorage:FindFirstChild(TEMPLATES_FOLDER_NAME)
if templates then
	templates:ClearAllChildren()
else
	templates = Instance.new("Folder")
	templates.Name = TEMPLATES_FOLDER_NAME
	templates.Parent = ServerStorage
end

-- 2. Biome Configuration
local BIOME_CONFIG = {
	[1] = {
		Name = "Level1",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(0, 255, 100), -- Neon Green
		ParticleType = "Leaves",
		ParticleColor = ColorSequence.new(Color3.fromRGB(50, 200, 50)),
		AtmosphereColor = Color3.fromRGB(150, 255, 180) -- Light Green tint
	},
	[2] = {
		Name = "Level2",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(0, 150, 255), -- Electric Blue
		ParticleType = "Bubbles",
		ParticleColor = ColorSequence.new(Color3.fromRGB(150, 220, 255)),
		AtmosphereColor = Color3.fromRGB(130, 180, 255) -- Soft Blue tint
	},
	[3] = {
		Name = "Level3",
		Material = Enum.Material.CrackedLava,
		Color = Color3.fromRGB(255, 80, 0), -- Lava Orange
		ParticleType = "Fire",
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)),
		AtmosphereColor = Color3.fromRGB(255, 100, 50) -- Hot Red/Orange tint
	},
	[4] = {
		Name = "Level4",
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(180, 0, 255), -- Galaxy Purple
		ParticleType = "Stars",
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 0, 255)),
		AtmosphereColor = Color3.fromRGB(150, 50, 255) -- Deep Purple tint
	}
}

-- 3. Utility to add particles
local function addParticles(parent, biome)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BiomeEffect"
	emitter.Color = biome.ParticleColor
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Rate = 20
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Acceleration = Vector3.new(0, 2, 0)
	
	if biome.ParticleType == "Leaves" then
		emitter.Texture = "rbxassetid://6736340536" -- Leaf texture placeholder
	elseif biome.ParticleType == "Bubbles" then
		emitter.Texture = "rbxassetid://243004475" -- Bubble texture
	elseif biome.ParticleType == "Fire" then
		emitter.Texture = "rbxassetid://242291244" -- Fire texture
	elseif biome.ParticleType == "Stars" then
		emitter.Texture = "rbxassetid://585426142" -- Star texture
	end
	
	emitter.Parent = parent
end

-- 4. Factory functions
local function createParkourBlock(biome, folder)
	local block = Instance.new("Part")
	block.Name = "ParkourBlock"
	block.Size = Vector3.new(12, 0.5, 12) -- Flat and wider for better landing
	block.Material = biome.Material
	block.Color = biome.Color
	block.Transparency = 0.2
	block.Anchored = true
	
	-- Polish Movement: High Friction
	block.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) -- Friction, Elasticity, Weighting

	-- Neon Border Effect
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Name = "NeonBorder"
	selectionBox.Adornee = block
	selectionBox.Color3 = biome.Color
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
	highlight.FillColor = biome.Color
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.5
	highlight.Parent = block

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 6 -- Bold outline for maximum visibility
	stroke.Color = Color3.new(0, 0, 0)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label

	label.Parent = surfaceGui

	addParticles(block, biome)
	block.Parent = folder
end

local function createLevelPlatform(biome, folder)
	local platform = Instance.new("Part")
	platform.Name = "LevelPlatform"
	platform.Shape = Enum.PartType.Cylinder
	platform.Size = Vector3.new(1, 20, 20)
	platform.CFrame = CFrame.Angles(0, 0, math.rad(90))
	platform.Material = biome.Material
	platform.Color = biome.Color
	platform.Anchored = true

	addParticles(platform, biome)
	platform.Parent = folder
end

local function createStarterPad(biome, folder)
	local pad = Instance.new("Part")
	pad.Name = "StarterPad"
	pad.Size = Vector3.new(10, 1, 10) -- Large launchpad
	pad.Material = biome.Material
	pad.Color = biome.Color
	pad.Anchored = true

	pad.Parent = folder
end

local function createGem(biome, folder)
	local gem = Instance.new("Part")
	gem.Name = "Gem"
	gem.Size = Vector3.new(1.5, 2.5, 1.5)
	gem.Shape = Enum.PartType.Ball -- Or use a MeshPart if available, here we'll use a stylized part
	gem.Material = Enum.Material.Neon
	gem.Color = Color3.fromRGB(255, 255, 255) -- White/Glow
	gem.Transparency = 0.3
	gem.Anchored = true
	gem.CanCollide = false

	-- Tag for collection system
	CollectionService:AddTag(gem, "CollectionItem")

	-- PointLight for glow
	local light = Instance.new("PointLight")
	light.Color = biome.Color
	light.Range = 10
	light.Brightness = 3
	light.Parent = gem

	gem.Parent = folder
end

-- 5. Main Generation Loop
for i = 1, 4 do
	local biome = BIOME_CONFIG[i]
	local levelFolder = Instance.new("Folder")
	levelFolder.Name = biome.Name
	levelFolder.Parent = templates

	createParkourBlock(biome, levelFolder)
	createLevelPlatform(biome, levelFolder)
	createStarterPad(biome, levelFolder)
	createGem(biome, levelFolder)
end

-- 6. Signal Ready
local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Parent = templates

