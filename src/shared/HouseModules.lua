local TweenService = game:GetService("TweenService")

local HouseModules = {}

-- Constants
local DOOR_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SOUND_ID_DOORBELL = "rbxassetid://1355418873" -- Generic doorbell/ding sound

-- Helper to create parts
local function createPart(name, size, cframe, material, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Material = material
	part.Color = color
	part.Anchored = true
	part.Parent = parent
	return part
end

-- Interaction Logic: Door
function HouseModules.SetupDoor(doorModel)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open/Close"
	prompt.ObjectText = "Front Door"
	prompt.RequiresLineOfSight = false
	prompt.Parent = doorModel.PrimaryPart or doorModel:FindFirstChildWhichIsA("BasePart")

	local isOpen = false
	local closedPivot = doorModel:GetPivot()
	-- Rotate 90 degrees around Y axis for open position
	local openPivot = closedPivot * CFrame.Angles(0, math.rad(90), 0)

	prompt.Triggered:Connect(function()
		isOpen = not isOpen
		local targetPivot = isOpen and openPivot or closedPivot

		-- To tween a Pivot, we must tween the PrimaryPart's CFrame to the location
		-- that results in the model's Pivot being at 'targetPivot'.
		-- Formula: PartCFrame = TargetPivot * PivotOffset:Inverse()

		local targetCFrame = targetPivot * doorModel.PrimaryPart.PivotOffset:Inverse()

		local tween = TweenService:Create(doorModel.PrimaryPart, DOOR_TWEEN_INFO, {CFrame = targetCFrame})
		tween:Play()
	end)
end

-- Interaction Logic: Light
function HouseModules.SetupLight(switchPart, lampPart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Toggle Light"
	prompt.ObjectText = "Light Switch"
	prompt.Parent = switchPart

	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 20
	light.Enabled = false
	light.Parent = lampPart

	local isOn = false
	local offColor = lampPart.Color

	prompt.Triggered:Connect(function()
		isOn = not isOn
		light.Enabled = isOn

		if isOn then
			lampPart.Material = Enum.Material.Neon
			lampPart.Color = Color3.fromRGB(255, 255, 200)
		else
			lampPart.Material = Enum.Material.Glass
			lampPart.Color = offColor
		end
	end)
end

-- Interaction Logic: Doorbell
function HouseModules.SetupDoorbell(buttonPart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ring"
	prompt.ObjectText = "Doorbell"
	prompt.Parent = buttonPart

	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID_DOORBELL
	sound.Volume = 1
	sound.Parent = buttonPart

	prompt.Triggered:Connect(function()
		sound:Play()
	end)
end

-- Main Build Function
function HouseModules.BuildHouse(originCFrame)
	local houseModel = Instance.new("Model")
	houseModel.Name = "ModernHouse"

	-- Dimensions
	local floorSize = Vector3.new(30, 1, 30)
	local wallHeight = 12
	local wallThickness = 1

	-- 1. Floor (Wood)
	createPart(
		"Floor",
		floorSize,
		originCFrame * CFrame.new(0, 0, 0),
		Enum.Material.WoodPlanks,
		Color3.fromRGB(139, 105, 20),
		houseModel
	)

	-- 2. Walls (Concrete)
	-- Back Wall
	createPart(
		"BackWall",
		Vector3.new(floorSize.X, wallHeight, wallThickness),
		originCFrame * CFrame.new(0, wallHeight/2, -floorSize.Z/2 + wallThickness/2),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)

	-- Left Wall
	createPart(
		"LeftWall",
		Vector3.new(wallThickness, wallHeight, floorSize.Z),
		originCFrame * CFrame.new(-floorSize.X/2 + wallThickness/2, wallHeight/2, 0),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)

	-- Right Wall (With Window Hole logic - simplified by using 2 parts)
	-- Lower part
	createPart(
		"RightWall_Lower",
		Vector3.new(wallThickness, 4, floorSize.Z),
		originCFrame * CFrame.new(floorSize.X/2 - wallThickness/2, 2, 0),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)
	-- Upper part
	createPart(
		"RightWall_Upper",
		Vector3.new(wallThickness, 4, floorSize.Z),
		originCFrame * CFrame.new(floorSize.X/2 - wallThickness/2, wallHeight - 2, 0),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)
	-- Side columns for window
	createPart(
		"RightWall_Col1",
		Vector3.new(wallThickness, 4, 10),
		originCFrame * CFrame.new(floorSize.X/2 - wallThickness/2, wallHeight/2, -10),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)
	createPart(
		"RightWall_Col2",
		Vector3.new(wallThickness, 4, 10),
		originCFrame * CFrame.new(floorSize.X/2 - wallThickness/2, wallHeight/2, 10),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)

	-- Window Glass
	local window = createPart(
		"Window",
		Vector3.new(wallThickness/2, 4, 10),
		originCFrame * CFrame.new(floorSize.X/2 - wallThickness/2, wallHeight/2, 0),
		Enum.Material.Glass,
		Color3.fromRGB(200, 240, 255),
		houseModel
	)
	window.Transparency = 0.5

	-- Front Wall (With Door Gap)
	-- Left of door
	createPart(
		"FrontWall_L",
		Vector3.new(12, wallHeight, wallThickness),
		originCFrame * CFrame.new(-9, wallHeight/2, floorSize.Z/2 - wallThickness/2),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)
	-- Right of door
	createPart(
		"FrontWall_R",
		Vector3.new(12, wallHeight, wallThickness),
		originCFrame * CFrame.new(9, wallHeight/2, floorSize.Z/2 - wallThickness/2),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)
	-- Above door
	createPart(
		"FrontWall_Top",
		Vector3.new(6, wallHeight - 8, wallThickness),
		originCFrame * CFrame.new(0, 8 + (wallHeight-8)/2, floorSize.Z/2 - wallThickness/2),
		Enum.Material.Concrete,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)

	-- 3. Roof (Flat)
	createPart(
		"Roof",
		Vector3.new(32, 1, 32),
		originCFrame * CFrame.new(0, wallHeight + 0.5, 0),
		Enum.Material.Concrete,
		Color3.fromRGB(50, 50, 50),
		houseModel
	)

	-- 4. Door Generation
	local doorModel = Instance.new("Model")
	doorModel.Name = "FrontDoorModel"
	doorModel.Parent = houseModel

	local doorSize = Vector3.new(6, 8, 0.5)
	local doorPos = originCFrame * CFrame.new(0, 4, floorSize.Z/2 - wallThickness/2)

	local doorPart = createPart(
		"Door",
		doorSize,
		doorPos,
		Enum.Material.Wood,
		Color3.fromRGB(100, 60, 20),
		doorModel
	)
	-- Move pivot to the left side of the door for correct swinging
	-- The door center is at 0. Left edge is at -3.
	-- We want the Pivot to be at the hinge location.
	local hingeOffset = CFrame.new(-doorSize.X/2, 0, 0)
	doorPart.PivotOffset = hingeOffset

	-- Important: For Pivot tweening to work on a single part model, we set PrimaryPart
	doorModel.PrimaryPart = doorPart

	-- Apply Door Interaction
	HouseModules.SetupDoor(doorModel)

	-- 5. Lighting Generation
	-- Lamp on ceiling
	local lamp = createPart(
		"CeilingLamp",
		Vector3.new(4, 0.5, 4),
		originCFrame * CFrame.new(0, wallHeight - 0.5, 0),
		Enum.Material.Glass,
		Color3.fromRGB(200, 200, 200),
		houseModel
	)

	-- Switch on wall (Inside, near door)
	local switch = createPart(
		"LightSwitch",
		Vector3.new(0.5, 1, 0.2),
		originCFrame * CFrame.new(-4, 4, floorSize.Z/2 - wallThickness - 0.1),
		Enum.Material.Plastic,
		Color3.fromRGB(255, 0, 0),
		houseModel
	)

	-- Apply Light Interaction
	HouseModules.SetupLight(switch, lamp)

	-- 6. Doorbell Generation
	local doorbell = createPart(
		"DoorbellButton",
		Vector3.new(0.5, 0.5, 0.2),
		originCFrame * CFrame.new(4, 4, floorSize.Z/2 + 0.1), -- Outside
		Enum.Material.Plastic,
		Color3.fromRGB(255, 255, 0),
		houseModel
	)

	-- Apply Doorbell Interaction
	HouseModules.SetupDoorbell(doorbell)

	houseModel.Parent = workspace
	return houseModel
end

return HouseModules
