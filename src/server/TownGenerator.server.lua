local GeometryLib = require(game.ReplicatedStorage.GeometryLib)
local BuildingSchematics = require(game.ReplicatedStorage.BuildingSchematics)

-- Configuration
local TOWN_CONFIG = {
	TownLength = 300,
	StreetWidth = 30,
	PlotWidth = 35,
	BoardwalkWidth = 8,
	Seed = tick()
}

local RNG = Random.new(TOWN_CONFIG.Seed)

local function generateTown()
	-- Cleanup previous generation
	if workspace:FindFirstChild("Ciudadela") then
		workspace.Ciudadela:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Ciudadela"
	folder.Parent = workspace

	-- 1. Create Main Street (Dirt Road)
	local road = GeometryLib.CreatePart({
		Name = "MainStreet",
		Size = Vector3.new(TOWN_CONFIG.StreetWidth, 1, TOWN_CONFIG.TownLength),
		CFrame = CFrame.new(0, 0, 0),
		Color = Color3.fromRGB(105, 75, 55), -- Dirt brown
		Material = Enum.Material.Slate, -- Rough texture
		Parent = folder
	})

	-- 2. Boardwalks
	local boardwalkLength = TOWN_CONFIG.TownLength
	local boardwalkOffset = TOWN_CONFIG.StreetWidth/2 + TOWN_CONFIG.BoardwalkWidth/2

	local leftBoardwalk = GeometryLib.CreatePart({
		Name = "LeftBoardwalk",
		Size = Vector3.new(TOWN_CONFIG.BoardwalkWidth, 1.5, boardwalkLength), -- Slightly elevated
		CFrame = CFrame.new(-boardwalkOffset, 0.25, 0),
		Color = Color3.fromRGB(160, 130, 90),
		Material = Enum.Material.WoodPlanks,
		Parent = folder
	})

	local rightBoardwalk = GeometryLib.CreatePart({
		Name = "RightBoardwalk",
		Size = Vector3.new(TOWN_CONFIG.BoardwalkWidth, 1.5, boardwalkLength),
		CFrame = CFrame.new(boardwalkOffset, 0.25, 0),
		Color = Color3.fromRGB(160, 130, 90),
		Material = Enum.Material.WoodPlanks,
		Parent = folder
	})

	-- 3. Building Placement
	-- We iterate along the Z axis from -Length/2 to Length/2
	local zStart = -TOWN_CONFIG.TownLength/2 + TOWN_CONFIG.PlotWidth/2
	local zEnd = TOWN_CONFIG.TownLength/2 - TOWN_CONFIG.PlotWidth/2

	local buildingTypes = {"Saloon", "Sheriff", "Bank", "GeneralStore"}

	-- Building Offset from center (Street/2 + Boardwalk + BuildingDepthOffset)
	-- We assume buildings align their front to the boardwalk.
	-- The schematics build around the center, so we need to push them back.
	local buildingZOffset = TOWN_CONFIG.StreetWidth/2 + TOWN_CONFIG.BoardwalkWidth + 10 -- Approx 10 studs back

	for z = zStart, zEnd, TOWN_CONFIG.PlotWidth do

		-- Attempt Left Side (at -X)
		-- Needs to face +X (Right) to look at the street
		if RNG:NextNumber() > 0.2 then -- 80% chance to place a building
			local typeName = buildingTypes[RNG:NextInteger(1, #buildingTypes)]
			local cf = CFrame.new(-buildingZOffset, 1, z) * CFrame.Angles(0, math.rad(-90), 0)
			BuildingSchematics[typeName](cf, folder)
		end

		-- Attempt Right Side (at +X)
		-- Needs to face -X (Left) to look at the street
		if RNG:NextNumber() > 0.2 then
			local typeName = buildingTypes[RNG:NextInteger(1, #buildingTypes)]
			local cf = CFrame.new(buildingZOffset, 1, z) * CFrame.Angles(0, math.rad(90), 0)
			BuildingSchematics[typeName](cf, folder)
		end
	end

	print("Western Town Generation Complete!")
end

-- Run
generateTown()
