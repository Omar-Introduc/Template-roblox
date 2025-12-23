local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration constants for the tree (shared with the function)
local TRUNK_COLOR = Color3.fromRGB(54, 41, 37)
local LANTERN_COLOR = Color3.fromRGB(255, 230, 230)

local function createMasterSakuraTree(templates)
	print("🌸 SakuraFactory: Generating Master Sakura Tree...")
	local model = Instance.new("Model")
	model.Name = "MasterSakuraTree"

	-- 1. Trunk Construction (Organic Curve - 6 segments)
	local lastCF = CFrame.new(0, 0, 0)
	local segments = 6
	local segHeight = 2.5
	local trunkParts = {}

	for i = 1, segments do
		local part = Instance.new("Part")
		part.Name = "TrunkSegment_" .. i
		part.Size = Vector3.new(2.2 - (i * 0.2), segHeight + 0.1, 2.2 - (i * 0.2))
		
		-- Simple curve logic
		local angle = math.rad(math.sin(i * 0.8) * 12)
		local newCF = lastCF * CFrame.new(0, segHeight, 0) * CFrame.Angles(angle, 0, angle * 0.5)
		
		part.CFrame = newCF * CFrame.new(0, -segHeight/2, 0)
		part.Color = TRUNK_COLOR
		part.Material = Enum.Material.Wood
		part.Anchored = true
		part.Parent = model
		
		table.insert(trunkParts, part)
		lastCF = newCF
	end
	
	model.PrimaryPart = trunkParts[1]

	-- Note: branchPositions removed as layers are generated relative to lastCF

	-- 3. Canopy (Christmas Pine Transformation)
	local canopyFolder = Instance.new("Folder")
	canopyFolder.Name = "Canopy"
	canopyFolder.Parent = model

	local ORNAMENT_COLORS = {
		Color3.fromRGB(255, 0, 0), -- Red
		Color3.fromRGB(255, 215, 0), -- Gold
		Color3.fromRGB(0, 255, 0), -- Green
		Color3.fromRGB(0, 100, 255) -- Blue
	}

	local function generatePineLayer(originCF, numClusters, radius, yOffset)
		local random = Random.new()
		
		for i = 1, numClusters do
			-- Fibonacci Sphere algorithm for distribution
			local offset = 0.5
			local phi = math.acos(1 - 2 * (i + offset) / (numClusters + 2 * offset))
			local theta = math.pi * (1 + 5^0.5) * (i + offset)
			
			local x = math.cos(theta) * math.sin(phi)
			local z = math.sin(theta) * math.sin(phi)
			local y = math.cos(phi)
			
			-- Flatten Y to create a layer-like look
			y = y * 0.3
			
			local clusterPos = originCF.Position + Vector3.new(x * radius, y + yOffset, z * radius)
			
			local cluster = Instance.new("Part")
			cluster.Name = "PineCluster"
			cluster.Shape = Enum.PartType.Ball
			cluster.Size = Vector3.new(radius * 0.6, radius * 0.4, radius * 0.6)
			cluster.Position = clusterPos
			cluster.Rotation = Vector3.new(random:NextNumber(0, 360), random:NextNumber(0, 360), random:NextNumber(0, 360))
			
			-- Performance & Visuals
			cluster.CastShadow = false
			cluster.CanCollide = false
			cluster.Anchored = true
			cluster.Color = Color3.fromRGB(34, 139, 34) -- Forest Green base
			cluster.Material = Enum.Material.Snow -- Snowy finish
			cluster.Parent = canopyFolder
			
			-- Random Ornaments
			if math.random() < 0.2 then
				local ornament = Instance.new("Part")
				ornament.Name = "Ornament"
				ornament.Shape = Enum.PartType.Ball
				ornament.Size = Vector3.new(0.4, 0.4, 0.4)
				ornament.Position = clusterPos + (Vector3.new(x, y, z).Unit * (radius * 0.3))
				ornament.Color = ORNAMENT_COLORS[math.random(1, #ORNAMENT_COLORS)]
				ornament.Material = Enum.Material.Neon
				ornament.Anchored = true
				ornament.Parent = canopyFolder
			end

			-- Periodic Snowflakes
			if i % 10 == 0 then
				local particles = Instance.new("ParticleEmitter")
				particles.Name = "SnowFlakes"
				particles.Texture = "rbxassetid://242211797"
				particles.Color = ColorSequence.new(Color3.new(1, 1, 1))
				particles.Size = NumberSequence.new(0.2, 0.5)
				particles.Lifetime = NumberRange.new(2, 4)
				particles.Rate = 2
				particles.Speed = NumberRange.new(1, 3)
				particles.Acceleration = Vector3.new(0, -0.5, 0)
				particles.Parent = cluster
			end
		end
	end

	-- 4. Build Layers (Bottom to Top - Conical)
	local trunkTop = lastCF
	generatePineLayer(trunkTop * CFrame.new(0, -6, 0), 30, 10, 0) -- Bottom
	generatePineLayer(trunkTop * CFrame.new(0, -2, 0), 25, 8, 0)  -- Mid-Bottom
	generatePineLayer(trunkTop * CFrame.new(0, 2, 0), 20, 6, 0)   -- Mid-Top
	generatePineLayer(trunkTop * CFrame.new(0, 5, 0), 12, 3.5, 0) -- Top

	-- 5. Christmas Star
	local starPos = trunkTop.Position + Vector3.new(0, 7.5, 0)
	local star = Instance.new("Part")
	star.Name = "ChristmasStar"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.new(1.5, 1.5, 1.5)
	star.Position = starPos
	star.Color = Color3.fromRGB(255, 255, 0)
	star.Material = Enum.Material.Neon
	star.Anchored = true
	star.Parent = model

	local starLight = Instance.new("PointLight")
	starLight.Range = 20
	starLight.Brightness = 5
	starLight.Color = Color3.fromRGB(255, 230, 100)
	starLight.Parent = star

	-- 4. Premium Lanterns
	local function createLantern(attachPart, offset)
		local lanternModel = Instance.new("Model")
		lanternModel.Name = "SakuraLantern"
		lanternModel.Parent = model
		
		local rope = Instance.new("Part")
		rope.Size = Vector3.new(0.1, 2, 0.1)
		rope.Position = attachPart.Position + offset + Vector3.new(0, 1, 0)
		rope.Color = Color3.new(0, 0, 0)
		rope.Anchored = true
		rope.Parent = lanternModel
		
		local body = Instance.new("Part")
		body.Shape = Enum.PartType.Cylinder
		body.Size = Vector3.new(1.8, 1, 1) -- Height is Y in cylinder
		body.CFrame = CFrame.new(attachPart.Position + offset) * CFrame.Angles(0, 0, math.rad(90))
		body.Color = LANTERN_COLOR
		body.Material = Enum.Material.Neon
		body.Anchored = true
		body.Parent = lanternModel
		
		local light = Instance.new("PointLight")
		light.Range = 15
		light.Brightness = 3
		light.Color = Color3.fromRGB(255, 180, 180)
		light.Parent = body
		
		-- Small decorative caps
		local cap1 = Instance.new("Part")
		cap1.Size = Vector3.new(0.2, 1.1, 1.1)
		cap1.CFrame = body.CFrame * CFrame.new(0.9, 0, 0)
		cap1.Color = TRUNK_COLOR
		cap1.Anchored = true
		cap1.Parent = lanternModel
		
		local cap2 = cap1:Clone()
		cap2.CFrame = body.CFrame * CFrame.new(-0.9, 0, 0)
		cap2.Parent = lanternModel
	end

	createLantern(trunkParts[#trunkParts], Vector3.new(4, -2, 2))
	createLantern(trunkParts[#trunkParts], Vector3.new(-4, -3, -1))
	createLantern(trunkParts[#trunkParts-1], Vector3.new(0, -4, 5))

	-- 5. No movement requested (Animation tag removed)

	model.Parent = templates
	print("✅ SakuraFactory: Master Sakura Tree created successfully.")
end

-- Start initialization
local templates = ReplicatedStorage:WaitForChild("Templates", 10)
if templates then
	createMasterSakuraTree(templates)
else
	warn("❌ SakuraFactory: Could not find Templates folder!")
end
