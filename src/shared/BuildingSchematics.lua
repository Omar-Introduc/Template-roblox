local GeometryLib = require(script.Parent.GeometryLib)

local BuildingSchematics = {}

-- Palette
local COLORS = {
	Brown = Color3.fromRGB(139, 69, 19),
	DarkBrown = Color3.fromRGB(101, 67, 33),
	Beige = Color3.fromRGB(245, 245, 220),
	Tan = Color3.fromRGB(210, 180, 140),
	RedOxide = Color3.fromRGB(165, 42, 42),
	Steel = Color3.fromRGB(128, 128, 128),
	Glass = Color3.fromRGB(173, 216, 230),
	Gold = Color3.fromRGB(255, 215, 0)
}

local MATS = {
	Wood = Enum.Material.Wood,
	Planks = Enum.Material.WoodPlanks,
	Concrete = Enum.Material.Concrete,
	Metal = Enum.Material.Metal,
	Neon = Enum.Material.Neon
}

-- Standard dimensions
local FLOOR_HEIGHT = 12
local WALL_THICKNESS = 1

local function buildWalls(cframe, size, color, material, parent)
	-- Back
	GeometryLib.CreatePart({
		Name = "BackWall",
		Size = Vector3.new(size.X, size.Y, WALL_THICKNESS),
		CFrame = cframe * CFrame.new(0, size.Y/2, size.Z/2 - WALL_THICKNESS/2),
		Color = color,
		Material = material,
		Parent = parent
	})
	-- Left
	GeometryLib.CreatePart({
		Name = "LeftWall",
		Size = Vector3.new(WALL_THICKNESS, size.Y, size.Z - WALL_THICKNESS * 2),
		CFrame = cframe * CFrame.new(-size.X/2 + WALL_THICKNESS/2, size.Y/2, 0),
		Color = color,
		Material = material,
		Parent = parent
	})
	-- Right
	GeometryLib.CreatePart({
		Name = "RightWall",
		Size = Vector3.new(WALL_THICKNESS, size.Y, size.Z - WALL_THICKNESS * 2),
		CFrame = cframe * CFrame.new(size.X/2 - WALL_THICKNESS/2, size.Y/2, 0),
		Color = color,
		Material = material,
		Parent = parent
	})
end

local function buildFlatRoof(cframe, size, color, parent)
	GeometryLib.CreatePart({
		Name = "Roof",
		Size = Vector3.new(size.X + 2, 1, size.Z + 2),
		CFrame = cframe * CFrame.new(0, size.Y + 0.5, 0),
		Color = color,
		Material = MATS.Wood,
		Parent = parent
	})
end

function BuildingSchematics.Saloon(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "Saloon"
	model.Parent = parent

	local size = Vector3.new(24, FLOOR_HEIGHT * 2, 20) -- 2 floors

	-- Main structure
	buildWalls(cframe, size, COLORS.DarkBrown, MATS.Planks, model)
	buildFlatRoof(cframe, size, COLORS.Brown, model)

	-- Front Facade (False Front)
	GeometryLib.CreatePart({
		Name = "Facade",
		Size = Vector3.new(size.X, size.Y + 4, WALL_THICKNESS),
		CFrame = cframe * CFrame.new(0, (size.Y + 4)/2, -size.Z/2 + WALL_THICKNESS/2),
		Color = COLORS.DarkBrown,
		Material = MATS.Planks,
		Parent = model
	})

	-- Balcony
	local balconyDepth = 6
	local balconyY = FLOOR_HEIGHT

	GeometryLib.CreatePart({
		Name = "BalconyFloor",
		Size = Vector3.new(size.X, 1, balconyDepth),
		CFrame = cframe * CFrame.new(0, balconyY, -size.Z/2 - balconyDepth/2),
		Color = COLORS.Brown,
		Material = MATS.Wood,
		Parent = model
	})

	-- Posts
	for i = -1, 1, 2 do
		GeometryLib.CreatePart({
			Name = "Post",
			Size = Vector3.new(1, FLOOR_HEIGHT, 1),
			CFrame = cframe * CFrame.new(i * (size.X/2 - 1), balconyY/2, -size.Z/2 - balconyDepth + 1),
			Color = COLORS.Brown,
			Material = MATS.Wood,
			Parent = model
		})
		GeometryLib.CreatePart({
			Name = "PostUpper",
			Size = Vector3.new(1, FLOOR_HEIGHT, 1),
			CFrame = cframe * CFrame.new(i * (size.X/2 - 1), balconyY + FLOOR_HEIGHT/2, -size.Z/2 - balconyDepth + 1),
			Color = COLORS.Brown,
			Material = MATS.Wood,
			Parent = model
		})
	end

	-- Swinging Doors
	local doorW, doorH = 3, 5
	for i = -1, 1, 2 do
		GeometryLib.CreatePart({
			Name = "SwingingDoor",
			Size = Vector3.new(doorW, doorH, 0.5),
			CFrame = cframe * CFrame.new(i * doorW/1.8, doorH/2 + 1, -size.Z/2 - 0.5) * CFrame.Angles(0, math.rad(i * 15), 0),
			Color = COLORS.Tan,
			Material = MATS.Wood,
			Parent = model
		})
	end

	-- Sign
	GeometryLib.CreatePart({
		Name = "Sign",
		Size = Vector3.new(12, 3, 0.5),
		CFrame = cframe * CFrame.new(0, size.Y + 1, -size.Z/2 - 0.5),
		Color = COLORS.Tan,
		Material = MATS.Wood,
		Parent = model
	})
end

function BuildingSchematics.Sheriff(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "Sheriff"
	model.Parent = parent

	local size = Vector3.new(18, FLOOR_HEIGHT, 16)

	buildWalls(cframe, size, COLORS.Beige, MATS.Wood, model)
	buildFlatRoof(cframe, size, COLORS.Brown, model)

	-- Front Facade
	GeometryLib.CreatePart({
		Name = "Facade",
		Size = Vector3.new(size.X, size.Y, WALL_THICKNESS),
		CFrame = cframe * CFrame.new(0, size.Y/2, -size.Z/2 + WALL_THICKNESS/2),
		Color = COLORS.Beige,
		Material = MATS.Wood,
		Parent = model
	})

	-- Cell bars window
	local winSize = 4
	local winCF = cframe * CFrame.new(size.X/4, size.Y/2, -size.Z/2)
	GeometryLib.CreatePart({
		Name = "WindowFrame",
		Size = Vector3.new(winSize, winSize, 1),
		CFrame = winCF,
		Color = COLORS.DarkBrown,
		Material = MATS.Wood,
		Parent = model
	})

	-- Bars
	for i = -1, 1 do
		GeometryLib.CreatePart({
			Name = "Bar",
			Size = Vector3.new(0.3, winSize, 0.3),
			CFrame = winCF * CFrame.new(i, 0, 0),
			Color = COLORS.Steel,
			Material = MATS.Metal,
			Parent = model
		})
	end

	-- Star
	GeometryLib.CreatePart({
		Name = "Star",
		Size = Vector3.new(2, 2, 0.5),
		CFrame = cframe * CFrame.new(-size.X/4, size.Y - 3, -size.Z/2 - 0.5),
		Color = COLORS.Gold,
		Material = MATS.Neon,
		Parent = model,
		Shape = Enum.PartType.Ball -- Simplified low poly star
	})
end

function BuildingSchematics.Bank(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "Bank"
	model.Parent = parent

	local size = Vector3.new(22, FLOOR_HEIGHT * 1.5, 24)

	-- Robust walls
	buildWalls(cframe, size, COLORS.RedOxide, MATS.Concrete, model)
	buildFlatRoof(cframe, size, COLORS.DarkBrown, model)

	-- Front
	GeometryLib.CreatePart({
		Name = "Front",
		Size = Vector3.new(size.X, size.Y, WALL_THICKNESS),
		CFrame = cframe * CFrame.new(0, size.Y/2, -size.Z/2 + WALL_THICKNESS/2),
		Color = COLORS.RedOxide,
		Material = MATS.Concrete,
		Parent = model
	})

	-- Columns
	local colW = 2
	for i = -1, 1, 2 do
		GeometryLib.CreatePart({
			Name = "Column",
			Size = Vector3.new(colW, size.Y, colW),
			CFrame = cframe * CFrame.new(i * (size.X/2 - colW/2), size.Y/2, -size.Z/2 - colW/2),
			Color = COLORS.Beige,
			Material = MATS.Concrete,
			Parent = model
		})
	end
end

function BuildingSchematics.GeneralStore(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "GeneralStore"
	model.Parent = parent

	local size = Vector3.new(20, FLOOR_HEIGHT, 20)

	buildWalls(cframe, size, COLORS.Tan, MATS.Wood, model)
	buildFlatRoof(cframe, size, COLORS.Brown, model)

	-- Front Facade with overhang
	local overhangDepth = 6
	GeometryLib.CreatePart({
		Name = "Overhang",
		Size = Vector3.new(size.X, 1, overhangDepth),
		CFrame = cframe * CFrame.new(0, size.Y - 2, -size.Z/2 - overhangDepth/2),
		Color = COLORS.Brown,
		Material = MATS.Wood,
		Parent = model
	})

	-- Front Wall
	GeometryLib.CreatePart({
		Name = "Front",
		Size = Vector3.new(size.X, size.Y, WALL_THICKNESS),
		CFrame = cframe * CFrame.new(0, size.Y/2, -size.Z/2 + WALL_THICKNESS/2),
		Color = COLORS.Tan,
		Material = MATS.Wood,
		Parent = model
	})

	-- Crates
	local rng = Random.new()
	for i = 1, 4 do
		local s = rng:NextNumber(1.5, 2.5)
		GeometryLib.CreatePart({
			Name = "Crate",
			Size = Vector3.new(s, s, s),
			CFrame = cframe * CFrame.new(rng:NextNumber(-6, 6), s/2, -size.Z/2 - rng:NextNumber(1, 4)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			Color = COLORS.Brown,
			Material = MATS.Planks,
			Parent = model
		})
	end
end

return BuildingSchematics
