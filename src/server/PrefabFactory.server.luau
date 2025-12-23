local ServerStorage = game:GetService("ServerStorage")

local templatesFolder = Instance.new("Folder")
templatesFolder.Name = "Templates"
templatesFolder.Parent = ServerStorage

-- 1. Generate ParkourBlock
local block = Instance.new("Part")
block.Name = "ParkourBlock"
block.Size = Vector3.new(10, 1, 10)
block.Material = Enum.Material.Neon
block.Anchored = true
-- SurfaceGui
local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Face = Enum.NormalId.Top
surfaceGui.Parent = block
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 0, 0)
label.TextStrokeTransparency = 0.5
label.Text = "5.0"
label.Parent = surfaceGui
block.Parent = templatesFolder

-- 2. Generate LevelPlatform (Circular)
local platform = Instance.new("Part")
platform.Name = "LevelPlatform"
platform.Shape = Enum.PartType.Cylinder
-- For a Cylinder, X is length (height of cylinder), Y/Z are diameter.
-- We want a platform 20x20 diameter, height 1.
-- So Size should be (1, 20, 20).
platform.Size = Vector3.new(1, 20, 20)
platform.Material = Enum.Material.Neon
platform.Anchored = true
-- Rotate so the circular face (on X axis) faces up (Y axis).
-- Rotate 90 degrees around Z axis.
platform.CFrame = CFrame.Angles(0, 0, math.rad(90))
platform.Parent = templatesFolder

-- 3. Generate StarterPad
local pad = Instance.new("Part")
pad.Name = "StarterPad"
pad.Size = Vector3.new(4, 1, 4)
pad.Material = Enum.Material.Neon
pad.BrickColor = BrickColor.new("Gold")
pad.Anchored = true
pad.Parent = templatesFolder
