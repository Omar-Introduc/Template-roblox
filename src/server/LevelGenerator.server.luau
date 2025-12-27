--[[
    LevelGenerator.server.luau
    Generates a procedural parkour level based on user specifications.

    Requirements:
    - Lobby at 0, 10, 0. Material: Concrete, Color: (60,60,60).
    - 50 Platforms in a line (Z-axis).
    - Platform Gap: Starts at 4, increases by 0.5 every 5 platforms.
    - Platform Color: Gradient Green -> Yellow -> Red.
    - Falling Mechanic: Touch -> Countdown -> Black/Unanchor -> Destroy -> Respawn.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local ASSETS_FOLDER = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Juego1")
local LOBBY_TEMPLATE = ASSETS_FOLDER:WaitForChild("Lobby")
local PLATFORM_TEMPLATE = ASSETS_FOLDER:WaitForChild("Plataforma")

local TOTAL_PLATFORMS = 50
local BASE_GAP = 4
local GAP_INCREMENT = 0.5
local GAP_INCREMENT_INTERVAL = 5

local COLOR_START = Color3.fromRGB(0, 255, 0)   -- Green
local COLOR_MID   = Color3.fromRGB(255, 255, 0) -- Yellow
local COLOR_END   = Color3.fromRGB(255, 0, 0)   -- Red

local LOBBY_POS = Vector3.new(0, 10, 0)
local LOBBY_COLOR = Color3.fromRGB(60, 60, 60)

-- State
local platformDebounces = {} -- Tracks currently active falling platforms to prevent double triggers

-- Forward declaration
local spawnPlatform

-- Helper Functions

local function getPlatformColor(index, total)
	-- Returns a color interpolated from Green -> Yellow -> Red based on index
	local midPoint = math.floor(total / 2)

	if index <= midPoint then
		local alpha = (index - 1) / (midPoint - 1)
		-- Lerp from Start to Mid
		return COLOR_START:Lerp(COLOR_MID, alpha)
	else
		local alpha = (index - midPoint) / (total - midPoint)
		-- Lerp from Mid to End
		return COLOR_MID:Lerp(COLOR_END, alpha)
	end
end

local function createCountdownUI()
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Text = ""
	label.Parent = billboard

	return billboard
end

local function handleFallingPlatform(platform, originalCFrame, originalColor, index, gap, previousZ)
	-- Debounce check
	if platformDebounces[platform] then return end

	local humanoidRootPart = nil
	-- Note: The .Touched event provides the hit part. We verify it's a player, but strictly speaking
	-- the prompt implies "Al tocar" (When touched), so we trigger on any touch that might be a player.
	-- Usually we check for Humanoid.

	platform.Touched:Connect(function(hit)
		if platformDebounces[platform] then return end
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")

		if humanoid then
			platformDebounces[platform] = true

			-- Create UI
			local ui = createCountdownUI()
			ui.Parent = platform
			local label = ui.TextLabel

			-- Countdown
			for i = 3, 1, -1 do
				label.Text = tostring(i)
				task.wait(1)
			end

			-- The Fall
			label.Text = "!!"
			platform.Color = Color3.new(0, 0, 0) -- Black
			platform.Anchored = false

			-- Destroy after 2 seconds falling
			task.delay(2, function()
				if platform and platform.Parent then
					platform:Destroy()
				end
				platformDebounces[platform] = nil -- Clear reference

				-- Regeneration: 5 seconds after destruction
				task.delay(5, function()
					spawnPlatform(index, gap, previousZ)
				end)
			end)
		end
	end)
end

spawnPlatform = function(index, gap, previousZ)
	local platform = PLATFORM_TEMPLATE:Clone()
	platform.Name = "Platform_" .. index

	-- Calculate Position
	-- Z = PrevZ + PrevSize/2 + Gap + ThisSize/2
	-- Assuming uniform size for simplicity or using actual size.
	-- Note: previousZ is the CENTER of the previous platform (or lobby edge if we want to be precise).
	-- Let's assume previousZ is the Center position of the previous object.

	local prevSizeZ = (index == 1) and LOBBY_TEMPLATE.Size.Z or PLATFORM_TEMPLATE.Size.Z
	local currentSizeZ = platform.Size.Z

	local zPos = previousZ + (prevSizeZ / 2) + gap + (currentSizeZ / 2)

	platform.CFrame = CFrame.new(0, 10, zPos)
	platform.Material = Enum.Material.Plastic -- or Neon
	platform.Color = getPlatformColor(index, TOTAL_PLATFORMS)
	-- Note: CollisionFidelity cannot be set at runtime.
	-- Ensure assets are set to PreciseConvexDecomposition in Studio.
	platform.Anchored = true
	platform.Parent = workspace

	-- Setup Falling Mechanic
	handleFallingPlatform(platform, platform.CFrame, platform.Color, index, gap, previousZ)

	return zPos
end

local function setupLobby()
	local lobby = LOBBY_TEMPLATE:Clone()
	lobby.Name = "LobbyStart"
	lobby.CFrame = CFrame.new(LOBBY_POS)
	lobby.Material = Enum.Material.Concrete
	lobby.Color = LOBBY_COLOR
	-- Note: CollisionFidelity cannot be set at runtime.
	-- Ensure assets are set to PreciseConvexDecomposition in Studio.
	lobby.Anchored = true
	lobby.Parent = workspace

	return lobby
end

local function generateLevel()
	print("🚀 Starting Level Generation...")

	local lobby = setupLobby()
	local currentZ = lobby.Position.Z

	for i = 1, TOTAL_PLATFORMS do
		-- Calculate Gap
		-- Starts at 4. Increases 0.5 every 5 platforms.
		-- (i-1)//5 gives 0 for 1-5, 1 for 6-10, etc.
		local difficultyMultiplier = math.floor((i - 1) / GAP_INCREMENT_INTERVAL)
		local currentGap = BASE_GAP + (difficultyMultiplier * GAP_INCREMENT)

		currentZ = spawnPlatform(i, currentGap, currentZ)
	end

	print("✅ Level Generated with " .. TOTAL_PLATFORMS .. " platforms.")
end

-- Run
generateLevel()
