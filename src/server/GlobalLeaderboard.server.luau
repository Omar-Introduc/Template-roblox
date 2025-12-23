local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MaxStageStore = DataStoreService:GetOrderedDataStore("GlobalMaxStage_v1")
local REFRESH_RATE = 60 -- Seconds
local BOARD_POSITION = Vector3.new(-15, 12, 12) -- Balanced placement in lobby

-- 1. Create the Physical Leaderboard Part
local function createPhysicalBoard()
	local board = Instance.new("Part")
	board.Name = "LeaderboardBoard"
	board.Size = Vector3.new(12, 10, 0.5)
	board.Position = BOARD_POSITION
	-- Rotate to face center
	board.CFrame = CFrame.lookAt(board.Position, Vector3.new(0, board.Position.Y, 0))
	board.Anchored = true
	board.Color = Color3.fromRGB(40, 40, 40)
	board.Material = Enum.Material.Glass
	board.Parent = workspace

	-- Festive Border Lights
	local border = Instance.new("SelectionBox")
	border.Adornee = board
	border.LineThickness = 0.1
	border.Color3 = Color3.fromRGB(255, 0, 0)
	border.Parent = board

	task.spawn(function()
		while true do
			border.Color3 = Color3.fromRGB(255, 0, 0)
			task.wait(1)
			border.Color3 = Color3.fromRGB(0, 255, 0)
			task.wait(1)
		end
	end)

	local sgui = Instance.new("SurfaceGui")
	sgui.Name = "LeaderboardGui"
	sgui.Face = Enum.NormalId.Front
	sgui.CanvasSize = Vector2.new(600, 500)
	sgui.Parent = board

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.Parent = sgui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.2, 0)
	title.Text = "🎅 SANTAS LEGENDARIOS - TOP GLOBAL 🎅"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	title.Parent = container

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.new(1, 0, 0.8, 0)
	list.Position = UDim2.fromScale(0, 0.2)
	list.BackgroundTransparency = 1
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.ScrollBarThickness = 0
	list.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = list

	return list
end

local leaderboardList = createPhysicalBoard()

-- 2. Update Leaderboard Display
local function updateDisplay(data)
	-- Clear old entries
	for _, child in ipairs(leaderboardList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for rank, entry in ipairs(data) do
		local userId = entry.key
		local stage = entry.value
		local name = "Desconocido"
		
		local success, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if success then name = result end

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -20, 0, 40)
		frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		frame.BackgroundTransparency = 0.5
		frame.BorderSizePixel = 0
		frame.Parent = leaderboardList
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
		rankLabel.Text = "#" .. rank
		rankLabel.TextColor3 = (rank <= 3) and Color3.fromRGB(255, 215, 0) or Color3.new(1, 1, 1)
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.TextScaled = true
		rankLabel.BackgroundTransparency = 1
		rankLabel.Parent = frame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
		nameLabel.Position = UDim2.fromScale(0.15, 0)
		nameLabel.Text = name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextScaled = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = frame

		local stageLabel = Instance.new("TextLabel")
		stageLabel.Size = UDim2.new(0.3, 0, 1, 0)
		stageLabel.Position = UDim2.fromScale(0.7, 0)
		stageLabel.Text = "LVL " .. stage
		stageLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
		stageLabel.Font = Enum.Font.GothamBold
		stageLabel.TextScaled = true
		stageLabel.BackgroundTransparency = 1
		stageLabel.Parent = frame
	end
end

-- 3. Data Store Management
local function refreshLeaderboard()
	print("📊 [LEADERBOARD] Refreshing global scores...")
	local success, pages = pcall(function()
		return MaxStageStore:GetSortedAsync(false, 10)
	end)

	if success then
		local topTen = pages:GetCurrentPage()
		updateDisplay(topTen)
	else
		warn("❌ [LEADERBOARD] Error fetching global data: " .. tostring(pages))
	end
end

local function savePlayerScore(player)
	local stage = player:GetAttribute("Stage") or 0
	if stage > 0 then
		pcall(function()
			MaxStageStore:SetAsync(tostring(player.UserId), stage)
		end)
	end
end

-- Listeners
Players.PlayerRemoving:Connect(savePlayerScore)

-- Main Loop
task.spawn(function()
	while true do
		-- Periodic save for active players
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerScore(player)
		end
		
		refreshLeaderboard()
		task.wait(REFRESH_RATE)
	end
end)
