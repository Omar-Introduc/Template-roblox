-- CharizardFactory.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local COLORS = {
	Orange = Color3.fromRGB(251, 140, 0),
	Cream = Color3.fromRGB(255, 236, 179),
	Teal = Color3.fromRGB(0, 137, 123),
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	Fire = Color3.fromRGB(255, 61, 0)
}

local function createVoxel(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Plastic
	part.Anchored = false
	part.CanCollide = false
	part.CastShadow = true
	part.Parent = parent
	return part
end

local function weld(part1, part0, c0, c1)
	local weld = Instance.new("Motor6D")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0 or CFrame.new()
	weld.C1 = c1 or CFrame.new()
	weld.Parent = part1
	return weld
end

local function generateCharizard(templates)
	print("🔥 CharizardFactory: Constructing Charivoxel...")
	local model = Instance.new("Model")
	model.Name = "Charivoxel"

	-- Main Torso (Root)
	local torso = createVoxel("Torso", Vector3.new(3.5, 4.5, 3), COLORS.Orange, model)
	torso.Transparency = 0
	torso.Anchored = true -- Fix: Prevent falling
	model.PrimaryPart = torso

	-- Belly
	local belly = createVoxel("Belly", Vector3.new(2.8, 3.8, 0.5), COLORS.Cream, model)
	weld(belly, torso, CFrame.new(0, -0.2, 1.55))

	-- NECK & HEAD
	local neck = createVoxel("Neck", Vector3.new(1.8, 2.5, 1.8), COLORS.Orange, model)
	local _neckWeld = weld(neck, torso, CFrame.new(0, 2.2, 0.2) * CFrame.Angles(math.rad(10), 0, 0))

	local head = createVoxel("Head", Vector3.new(2.2, 2.2, 3), COLORS.Orange, model)
	local _headWeld = weld(head, neck, CFrame.new(0, 1.25, 0.3))

	-- Horns
	local hornL = createVoxel("HornL", Vector3.new(0.4, 1.5, 0.4), COLORS.Orange, model)
	weld(hornL, head, CFrame.new(-0.8, 1.1, -0.8) * CFrame.Angles(math.rad(-30), 0, 0))
	local hornR = createVoxel("HornR", Vector3.new(0.4, 1.5, 0.4), COLORS.Orange, model)
	weld(hornR, head, CFrame.new(0.8, 1.1, -0.8) * CFrame.Angles(math.rad(-30), 0, 0))

	-- Eyes
	local eyeL = createVoxel("EyeL", Vector3.new(0.4, 0.4, 0.05), COLORS.Black, model)
	weld(eyeL, head, CFrame.new(-0.8, 0.3, 1.52))
	local eyeR = createVoxel("EyeR", Vector3.new(0.4, 0.4, 0.05), COLORS.Black, model)
	weld(eyeR, head, CFrame.new(0.8, 0.3, 1.52))

	-- JAW
	local jaw = createVoxel("Jaw", Vector3.new(1.8, 0.6, 2.5), COLORS.Orange, model)
	local _jawWeld = weld(jaw, head, CFrame.new(0, -0.8, 0.5))

	-- WINGS
	local function createWing(isLeft)
		local sideMultiplier = isLeft and -1 or 1
		local wingPivot = Instance.new("Part")
		wingPivot.Name = isLeft and "WingPivotL" or "WingPivotR"
		wingPivot.Size = Vector3.new(0.1, 0.1, 0.1)
		wingPivot.Transparency = 1
		wingPivot.CanCollide = false
		wingPivot.Parent = model
		local wingWeld = weld(wingPivot, torso, CFrame.new(1.5 * sideMultiplier, 1.5, -1))

		local bone = createVoxel("WingBone", Vector3.new(4, 0.6, 0.6), COLORS.Orange, model)
		weld(bone, wingPivot, CFrame.new(2 * sideMultiplier, 0, 0))

		local membrane = createVoxel("WingMembrane", Vector3.new(3.5, 0.1, 2.5), COLORS.Teal, model)
		weld(membrane, bone, CFrame.new(-0.2 * sideMultiplier, -0.2, 1.2))
		
		return wingWeld
	end

	local _createWeld = createWing(true)
	createWing(false)

	-- TAIL
	local tail1 = createVoxel("Tail1", Vector3.new(1.5, 1.5, 2.5), COLORS.Orange, model)
	local _tail1Weld = weld(tail1, torso, CFrame.new(0, -1.5, -1.2) * CFrame.Angles(math.rad(-10), 0, 0))

	local tail2 = createVoxel("Tail2", Vector3.new(1.2, 1.2, 3), COLORS.Orange, model)
	local _tail2Weld = weld(tail2, tail1, CFrame.new(0, -0.5, -2.5))

	local tailTip = createVoxel("TailTip", Vector3.new(0.8, 0.8, 2), COLORS.Orange, model)
	local _tailTipWeld = weld(tailTip, tail2, CFrame.new(0, 0.5, -2.5) * CFrame.Angles(math.rad(20), 0, 0))

	-- Tail Fire
	local firePart = Instance.new("Part")
	firePart.Name = "FirePoint"
	firePart.Size = Vector3.new(0.1, 0.1, 0.1)
	firePart.Transparency = 1
	firePart.CanCollide = false
	firePart.Parent = model
	weld(firePart, tailTip, CFrame.new(0, 0, -1.2))

	local fire = Instance.new("ParticleEmitter")
	fire.Name = "TailFlame"
	fire.Texture = "rbxassetid://6201389270" -- Fire texture
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))
	})
	fire.Size = NumberSequence.new(1.5, 0)
	fire.Lifetime = NumberRange.new(0.3, 0.6)
	fire.Rate = 50
	fire.Speed = NumberRange.new(5, 8)
	fire.VelocitySpread = 15
	fire.Parent = firePart

	-- LAVA GLOW (Tail light)
	local fireLight = Instance.new("PointLight")
	fireLight.Color = COLORS.Fire
	fireLight.Range = 8
	fireLight.Brightness = 3
	fireLight.Parent = firePart

	-- EXTREMITIES
	-- Arms
	local armL = createVoxel("ArmL", Vector3.new(0.8, 1.8, 0.8), COLORS.Orange, model)
	weld(armL, torso, CFrame.new(-1.8, 0.5, 1) * CFrame.Angles(math.rad(-45), 0, 0))
	local armR = createVoxel("ArmR", Vector3.new(0.8, 1.8, 0.8), COLORS.Orange, model)
	weld(armR, torso, CFrame.new(1.8, 0.5, 1) * CFrame.Angles(math.rad(-45), 0, 0))

	-- Legs
	local legL = createVoxel("LegL", Vector3.new(1.5, 2.5, 2), COLORS.Orange, model)
	weld(legL, torso, CFrame.new(-1.6, -2.5, 0.5))
	local legR = createVoxel("LegR", Vector3.new(1.5, 2.5, 2), COLORS.Orange, model)
	weld(legR, torso, CFrame.new(1.6, -2.5, 0.5))

	-- Tag for Client Visuals
	CollectionService:AddTag(model, "Charivoxel")
	
	-- Finalize
	model.Parent = templates
	templates:SetAttribute("CharizardReady", true)
	print("✅ CharizardFactory: Voxel model ready in Templates.")
end

local templates = ReplicatedStorage:WaitForChild("Templates", 10)
if templates then
	generateCharizard(templates)
end
