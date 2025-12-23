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

-- Biome Configuration
local BIOME_CONFIGS = {
	[1] = { -- Neon Forest
		Name = "Level1",
		BlockMaterial = Enum.Material.Wood,
		BlockColor = BrickColor.new("Lime green"),
		PlatformColor = BrickColor.new("Forest green"),
		PlatformMaterial = Enum.Material.Grass,
		ParticleTexture = "rbxassetid://296874871", -- Soft Glow (Simulating pollen/leaves)
		ParticleColor = ColorSequence.new(Color3.fromRGB(50, 255, 50)),
		ParticleSpeed = NumberRange.new(2, 4),
		ParticleSpread = Vector2.new(180, 0), -- Horizontal spread
	},
	[2] = { -- Electric Ocean
		Name = "Level2",
		BlockMaterial = Enum.Material.Glass,
		BlockColor = BrickColor.new("Electric blue"),
		PlatformColor = BrickColor.new("Deep blue"),
		PlatformMaterial = Enum.Material.Glass,
		ParticleTexture = "rbxassetid://243660364", -- Smoke/Bubbles
		ParticleColor = ColorSequence.new(Color3.fromRGB(0, 150, 255)),
		ParticleSpeed = NumberRange.new(3, 5),
		ParticleSpread = Vector2.new(20, 20),
	},
	[3] = { -- Lava Underworld
		Name = "Level3",
		BlockMaterial = Enum.Material.CrackedLava,
		BlockColor = BrickColor.new("Bright red"),
		PlatformColor = BrickColor.new("Cocoa"),
		PlatformMaterial = Enum.Material.CrackedLava,
		ParticleTexture = "rbxassetid://242954639", -- Fire
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 80, 0)),
		ParticleSpeed = NumberRange.new(5, 8),
		ParticleSpread = Vector2.new(15, 15),
	},
	[4] = { -- Galactic Void
		Name = "Level4",
		BlockMaterial = Enum.Material.Neon,
		BlockColor = BrickColor.new("Royal purple"),
		PlatformColor = BrickColor.new("Black"),
		PlatformMaterial = Enum.Material.Neon,
		ParticleTexture = "rbxassetid://132156827", -- Star
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 150))
		}),
		ParticleSpeed = NumberRange.new(1, 2),
		ParticleSpread = Vector2.new(360, 360),
	}
}

local function createLevelFolder(name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = templates
	return folder
end

local function createParkourBlock(parent, config)
	local block = Instance.new("Part")
	block.Name = "ParkourBlock"
	block.Size = Vector3.new(10, 1, 10)
	block.Material = config.BlockMaterial
	block.BrickColor = config.BlockColor
	block.Anchored = true
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth

	-- Tags and Attributes
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	-- Particle Emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.ParticleTexture
	emitter.Color = config.ParticleColor
	emitter.Rate = 10
	emitter.Lifetime = NumberRange.new(1.5, 3)
	emitter.Speed = config.ParticleSpeed
	emitter.SpreadAngle = config.ParticleSpread
	emitter.LightEmission = 0.6
	emitter.LockedToPart = false
	emitter.Parent = block

	-- SurfaceGui for Countdown
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
	label.TextColor3 = Color3.new(1, 1, 1) -- White text for contrast
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Text = "0.0"
	label.Parent = surfaceGui

	block.Parent = parent
end

local function createLevelPlatform(parent, config)
	local platform = Instance.new("Part")
	platform.Name = "LevelPlatform"
	platform.Shape = Enum.PartType.Cylinder
	platform.Size = Vector3.new(1, 20, 20)
	-- Rotate 90 degrees on Z so the flat face is up (Y-axis)
	platform.CFrame = CFrame.Angles(0, 0, math.rad(90))
	platform.Material = config.PlatformMaterial
	platform.BrickColor = config.PlatformColor
	platform.Anchored = true
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth

	platform.Parent = parent
end

local function createStarterPad(parent, config)
	local pad = Instance.new("Part")
	pad.Name = "StarterPad"
	pad.Size = Vector3.new(4, 1, 4)
	pad.BrickColor = config.BlockColor
	pad.Material = Enum.Material.Neon
	pad.Anchored = true
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth

	pad.Parent = parent
end

-- Generate Biome Sets
for i = 1, 4 do
	local config = BIOME_CONFIGS[i]
	local levelFolder = createLevelFolder(config.Name)
	createParkourBlock(levelFolder, config)
	createLevelPlatform(levelFolder, config)
	createStarterPad(levelFolder, config)
end

-- Signal Ready
local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Parent = templates
