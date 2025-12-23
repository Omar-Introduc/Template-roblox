local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Debris = game:GetService("Debris")

local COLORS = {
	Wood = Color3.fromHex("#8B4513"),
	Sakura1 = Color3.fromHex("#FFB7C5"),
	Sakura2 = Color3.fromHex("#FF69B4"),
	Sakura3 = Color3.fromHex("#FFC0CB"),
	Grass = Color3.fromHex("#4CAF50"),
	Stone = Color3.fromRGB(128, 128, 128)
}

local function box(name, size, pos, color, parent, rotation)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CastShadow = true
	part.Anchored = true
	part.CanCollide = false
	part.Position = pos
	if rotation then
		part.Rotation = rotation
	end
	part.Parent = parent
	return part
end

local function createMasterSakuraTree(templates)
	print("🌸 SakuraFactory: Generating SakuraVoxel (Tokyo Edition)...")
	local model = Instance.new("Model")
	model.Name = "MasterSakuraTree"

	local treeRoot = Instance.new("Part")
	treeRoot.Name = "Root"
	treeRoot.Size = Vector3.new(0.1, 0.1, 0.1)
	treeRoot.Transparency = 1
	treeRoot.Anchored = true
	treeRoot.CanCollide = false
	treeRoot.Position = Vector3.new(0, 0, 0)
	treeRoot.Parent = model
	model.PrimaryPart = treeRoot

	-- 1. Zen Garden Base
	local groundGroup = Instance.new("Model", model)
	groundGroup.Name = "ZenGarden"
	-- Base grass (Scaled to 30 as requested)
	box("GrassBase", Vector3.new(30, 2, 30), Vector3.new(0, -5, 0), COLORS.Grass, groundGroup)
	-- Stones
	local random = Random.new()
	for i = 1, 8 do
		local stonePos = Vector3.new(random:NextNumber(-12, 12), -4.5, random:NextNumber(-12, 12))
		box("ZenStone", Vector3.new(2.5, 1.5, 2.5), stonePos, COLORS.Stone, groundGroup)
	end

	-- 2. TRUNK (Organic Voxel Curve - SCALED UP)
	local trunkGroup = Instance.new("Model", model)
	trunkGroup.Name = "Trunk"
	
	-- Base Trunk (Thicker and Taller)
	local _t1 = box("Trunk1", Vector3.new(4, 8, 4), Vector3.new(0, 0, 0), COLORS.Wood, trunkGroup)
	-- Mid Trunk
	local _t2 = box("Trunk2", Vector3.new(3, 6, 3), Vector3.new(0.5, 6, 0.5), COLORS.Wood, trunkGroup, Vector3.new(0, 0, -5))
	-- Top Trunk
	local _t3 = box("Trunk3", Vector3.new(2, 6, 2), Vector3.new(1, 11, 1), COLORS.Wood, trunkGroup, Vector3.new(0, 0, -10))

	-- 3. BRANCHES (Scaled Positions)
	local _branchL = box("BranchL", Vector3.new(2, 6, 2), Vector3.new(-3, 8, 1), COLORS.Wood, trunkGroup, Vector3.new(0, 0, 45))
	local _branchR = box("BranchR", Vector3.new(1.5, 5, 1.5), Vector3.new(3, 9, 1), COLORS.Wood, trunkGroup, Vector3.new(0, 0, -35))

	-- 4. FOLLIAGE (Voxel Cloud Clusters)
	local foliageGroup = Instance.new("Model", model)
	foliageGroup.Name = "Foliage"

	local function createCluster(x, y, z, s, color)
		local leaf = box("SakuraLeaf", Vector3.new(s, s*0.8, s), Vector3.new(x, y, z), color, foliageGroup)
		box("SakuraLeafDetail1", Vector3.new(s*0.6, s*0.4, s*0.6), Vector3.new(x + s*0.4, y + s*0.3, z + s*0.4), color, foliageGroup)
		box("SakuraLeafDetail2", Vector3.new(s*0.5, s*0.5, s*0.5), Vector3.new(x - s*0.3, y - s*0.2, z - s*0.3), color, foliageGroup)
		
		-- Three.js style internal glow
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 0.5
		light.Range = s * 2
		light.Parent = leaf
	end

	-- Distribution Scaled Up to Y ~12-18
	-- Main Canopy
	createCluster(1, 16, 1, 6, COLORS.Sakura1)
	createCluster(0, 15, -2, 5, COLORS.Sakura2)
	createCluster(-1, 16, 2, 5.5, COLORS.Sakura3)

	-- Branch Canopy Left
	createCluster(-5, 12, 1, 4.5, COLORS.Sakura2)
	createCluster(-6, 13, 2, 3.5, COLORS.Sakura1)

	-- Branch Canopy Right
	createCluster(5, 13, 1, 4.5, COLORS.Sakura1)
	createCluster(4, 12, -2, 4, COLORS.Sakura3)

	-- 5. PETAL RAIN (Voxel Particle system)
	local petalEmitterPart = Instance.new("Part")
	petalEmitterPart.Name = "PetalEmitter"
	petalEmitterPart.Size = Vector3.new(25, 1, 25)
	petalEmitterPart.Transparency = 1
	petalEmitterPart.Anchored = true
	petalEmitterPart.CanCollide = false
	petalEmitterPart.Position = Vector3.new(0, 25, 0)
	petalEmitterPart.Parent = model

	local petalEmitter = Instance.new("ParticleEmitter")
	petalEmitter.Name = "VoxelPetals"
	petalEmitter.Texture = "rbxassetid://15444645258" -- Small square voxel texture
	petalEmitter.Color = ColorSequence.new(COLORS.Sakura3)
	petalEmitter.Size = NumberSequence.new(0.2, 0.5)
	petalEmitter.Lifetime = NumberRange.new(5, 10)
	petalEmitter.Rate = 15
	petalEmitter.Speed = NumberRange.new(2, 5)
	petalEmitter.VelocitySpread = 180
	petalEmitter.Rotation = NumberRange.new(0, 360)
	petalEmitter.RotSpeed = NumberRange.new(50, 100)
	petalEmitter.Acceleration = Vector3.new(1, -2, 0.5) -- Simulated Wind
	petalEmitter.Parent = petalEmitterPart

	templates:SetAttribute("SakuraReady", true)
	model.Parent = templates
	print("✅ SakuraFactory: Voxel Sakura Tree (Tokyo Edition) ready in Templates.")
end

local templates = ReplicatedStorage:WaitForChild("Templates", 10)
if templates then
	createMasterSakuraTree(templates)
end
