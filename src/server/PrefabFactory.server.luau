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

-- 2. Create ParkourBlock Prefab
local function createParkourBlock()
	local block = Instance.new("Part")
	block.Name = "ParkourBlock"
	block.Size = Vector3.new(10, 1, 10)
	block.Material = Enum.Material.Glass
	block.BrickColor = BrickColor.new("Institutional white")
	block.Anchored = true

	-- Tags and Attributes
	CollectionService:AddTag(block, "Crystal")
	block:SetAttribute("IgnoreTouches", true)

	-- SurfaceGui
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
	label.TextColor3 = Color3.new(1, 0, 0) -- Red
	label.TextStrokeTransparency = 0.5
	label.Text = "0.0"
	label.Parent = surfaceGui

	block.Parent = templates
end

-- 3. Create LevelPlatform Prefab
local function createLevelPlatform()
	local platform = Instance.new("Part")
	platform.Name = "LevelPlatform"
	platform.Size = Vector3.new(20, 2, 20)
	platform.Material = Enum.Material.Neon
	platform.Anchored = true
	platform.BrickColor = BrickColor.new("Medium stone grey") -- Default

	platform.Parent = templates
end

-- 4. Create StarterPad Prefab
local function createStarterPad()
	local pad = Instance.new("Part")
	pad.Name = "StarterPad"
	pad.Size = Vector3.new(4, 1, 4)
	pad.BrickColor = BrickColor.new("Gold")
	pad.Material = Enum.Material.Neon
	pad.Anchored = true

	pad.Parent = templates
end

createParkourBlock()
createLevelPlatform()
createStarterPad()

-- 5. Signal Ready
local readyVal = Instance.new("StringValue")
readyVal.Name = "FactoryReady"
readyVal.Parent = templates
