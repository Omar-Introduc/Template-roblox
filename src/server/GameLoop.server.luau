local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Module Import
-- Assuming Logger is in ReplicatedStorage.Shared as per standard framework structure
local Logger
local success, result = pcall(function()
	-- Add timeout to prevent infinite yield if Shared folder is missing
	return require(ReplicatedStorage:WaitForChild("Shared", 2):WaitForChild("Logger", 2))
end)

if success then
	Logger = result
else
	-- Fallback logger if module is missing
	Logger = {
		Info = function(msg) print("[INFO] " .. msg) end,
		Warn = function(msg) warn("[WARN] " .. msg) end,
		Critical = function(msg) warn("[CRITICAL] " .. msg) end,
		Error = function(msg) warn("[ERROR] " .. msg) end
	}
end

-- Constants
local CONFIG = {
	ASSET_PATH = "juego1",
	GAP = 6, -- Distance between platforms (studs)
	START_DISTANCE = 12, -- Distance from Lobby to first platform
	LOBBY_HEIGHT = 10,
	COUNTDOWN_TIME = 3,
	FALL_DELAY = 2
}

-- Asset Retrieval
local assetFolder = ReplicatedStorage:WaitForChild("asset"):WaitForChild(CONFIG.ASSET_PATH)

local function getAsset(name)
	local asset = assetFolder:FindFirstChild(name)
	if not asset then
		Logger.Critical("Asset not found: " .. name)
	end
	return asset
end

-- State
local currentPlatformCount = 0
local platformTemplate = getAsset("Plataforma_Level1")
local lobbyTemplate = getAsset("Lobby")

if not platformTemplate or not lobbyTemplate then
	Logger.Critical("Essential assets missing. GameLoop stopped.")
	return
end

-- Forward declaration
local setupPlatform

-- Helper: Create Visual Countdown
local function createCountdown(parentPart)
	local bb = Instance.new("BillboardGui")
	bb.Name = "CountdownGui"
	bb.Size = UDim2.new(0, 100, 0, 100)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Text = tostring(CONFIG.COUNTDOWN_TIME)
	text.Parent = bb

	bb.Parent = parentPart
	return bb, text
end

-- Core Logic: Spawn Next Platform
local function spawnNextPlatform(previousPlatform)
	-- Determine position
	local prevCF = previousPlatform:GetPivot()
	local _, prevSize = previousPlatform:GetBoundingBox()
	local _, nextSize = platformTemplate:GetBoundingBox()
	
	-- Calculate forward offset (Global Z axis positive)
	-- "sumando el Gap + tamaño del modelo"
	-- Distance from center to center = (PrevSize/2) + GAP + (NextSize/2)
	local offsetZ = (prevSize.Z / 2) + CONFIG.GAP + (nextSize.Z / 2)
	local nextPos = prevCF.Position + Vector3.new(0, 0, offsetZ)
	
	-- Instantiate
	currentPlatformCount += 1
	local newPlatform = platformTemplate:Clone()
	newPlatform.Name = "Plataforma_" .. currentPlatformCount

    -- Preserve template rotation
    local templateRotation = platformTemplate:GetPivot().Rotation
	newPlatform:PivotTo(CFrame.new(nextPos) * templateRotation)
	newPlatform.Parent = workspace

    return newPlatform
end

-- Helper: Spawn Shop Board
local function spawnShop(lobby)
	if workspace:FindFirstChild("ShopBoard") then workspace.ShopBoard:Destroy() end

	local cf = lobby:GetPivot()
	local _, size = lobby:GetBoundingBox()

	local shopBoard = Instance.new("Part")
	shopBoard.Name = "ShopBoard"
	shopBoard.Size = Vector3.new(24, 16, 1)
	shopBoard.Anchored = true
	shopBoard.CanCollide = true
	shopBoard.Transparency = 1 -- Invisible board, GUI handles visuals

	-- Position: Left side of the lobby, facing center
	-- Corner position: Back Left relative to the spawn direction (Z+)
	-- We place it slightly inside the boundary to avoid clipping with walls
	local offset = Vector3.new((-size.X / 2) + 2, 8, 0) -- 8 studs up from center height

	-- Face towards positive X (center)
	shopBoard.CFrame = cf * CFrame.new(offset) * CFrame.Angles(0, math.rad(-90), 0)

	shopBoard.Parent = workspace
	Logger.Info("ShopBoard spawned.")
end

-- Core Logic: Setup Platform Behavior
function setupPlatform(platform)
	local mainPart = platform.PrimaryPart or platform:FindFirstChildWhichIsA("BasePart", true)
	if not mainPart then
		Logger.Warn("Platform " .. platform.Name .. " has no PrimaryPart!")
		return
	end
	
	-- Use an attribute to track if already triggered to avoid multiple spawns
	platform:SetAttribute("Triggered", false)

	local connection
	connection = mainPart.Touched:Connect(function(hit)
		if platform:GetAttribute("Triggered") then return end
		if not hit.Parent or not hit.Parent:FindFirstChild("Humanoid") then return end
		
		-- 1. Triggered
		platform:SetAttribute("Triggered", true)
		Logger.Info("Player touched: " .. platform.Name)
		
		-- 2. Spawn Next Immediately (Chain Generation)
		local nextPlat = spawnNextPlatform(platform)
		if nextPlat then
			setupPlatform(nextPlat)
		end

		-- 3. Countdown
		local bb, textLabel = createCountdown(mainPart)
		for i = CONFIG.COUNTDOWN_TIME, 1, -1 do
			textLabel.Text = tostring(i)
			task.wait(1)
		end
		if bb then bb:Destroy() end

		-- 4. Fall and Destroy
		for _, part in ipairs(platform:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = Color3.new(0, 0, 0) -- Turn Black
				part.Anchored = false
				part.CanCollide = false
			end
		end
		
		Debris:AddItem(platform, CONFIG.FALL_DELAY) -- Destroy shortly after falling
        connection:Disconnect()
	end)
end

-- Initialization
local function initGame()
	Logger.Info("Starting Procedural Infinite Jump GameLoop...")
	
	-- Cleanup Environment
	if workspace:FindFirstChild("Baseplate") then workspace.Baseplate:Destroy() end

    -- Remove old levels/platforms/lobbies
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:match("Plataforma") or child.Name:match("Level") or child.Name == "Lobby" then
            child:Destroy()
        end
    end

    -- Spawn Lobby
    local lobby = lobbyTemplate:Clone()
    lobby.Name = "Lobby"
    lobby.Parent = workspace
    lobby:PivotTo(CFrame.new(0, CONFIG.LOBBY_HEIGHT, 0))

    -- Spawn Shop
    spawnShop(lobby)

    -- Spawn First Platform
    -- "distance fija (ej. 12 studs) del Lobby"
    local lobbyCF = lobby:GetPivot()
    local _, lobbySize = lobby:GetBoundingBox()
    local _, platSize = platformTemplate:GetBoundingBox()

    -- Calculate position for first platform (Global Z +)
    local offsetZ = (lobbySize.Z / 2) + CONFIG.START_DISTANCE + (platSize.Z / 2)
    local firstPos = lobbyCF.Position + Vector3.new(0, 0, offsetZ)

    local firstPlatform = platformTemplate:Clone()
    firstPlatform.Name = "Plataforma_1"
    local templateRotation = platformTemplate:GetPivot().Rotation
    firstPlatform:PivotTo(CFrame.new(firstPos) * templateRotation)
    firstPlatform.Parent = workspace

    currentPlatformCount = 1
    setupPlatform(firstPlatform)
    Logger.Info("Game Initialized. Plataforma_1 spawned.")
end

-- Backup / Watchdog Loop
-- "Si el juego se queda vacío (reinicio del ciclo)"
task.spawn(function()
    while true do
        task.wait(2)
        local platformCount = 0
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:match("Plataforma_") then
                platformCount += 1
            end
        end

        if platformCount == 0 then
            Logger.Warn("No platforms detected. Regenerating initial platform...")

            -- Ensure Lobby exists (if it was destroyed for some reason, though unlikely)
            local lobby = workspace:FindFirstChild("Lobby")
             if lobby then
                 local lobbyCF = lobby:GetPivot()
                 local _, lobbySize = lobby:GetBoundingBox()
                 local _, platSize = platformTemplate:GetBoundingBox()

                 local offsetZ = (lobbySize.Z / 2) + CONFIG.START_DISTANCE + (platSize.Z / 2)
                 local firstPos = lobbyCF.Position + Vector3.new(0, 0, offsetZ)

                 local firstPlatform = platformTemplate:Clone()
                 firstPlatform.Name = "Plataforma_1"
                 local templateRotation = platformTemplate:GetPivot().Rotation
                 firstPlatform:PivotTo(CFrame.new(firstPos) * templateRotation)
                 firstPlatform.Parent = workspace

                 currentPlatformCount = 1
                 setupPlatform(firstPlatform)
             else
                 -- Full init if lobby is gone too
                 initGame()
             end
        end
    end
end)

-- Start the game
initGame()
