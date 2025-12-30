-- src/client/GlobalLeaderboardController.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local _Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Events")
local GetTopPlayers = Events:WaitForChild("GetTopPlayers")

local REFRESH_INTERVAL = 60 -- Segundos para actualizar

local function updateBoard(board: BasePart)
	local sg = board:FindFirstChild("LeaderboardUI")
	if not sg then
		sg = Instance.new("SurfaceGui")
		sg.Name = "LeaderboardUI"
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.Adornee = board
		sg.Parent = board
	end

	sg:ClearAllChildren()

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = sg

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = "TOP 10 GLOBALES (CR)"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 35
	title.Parent = mainFrame

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = mainFrame

	local content = Instance.new("Frame")
	content.Size = UDim2.new(0.9, 0, 0.8, 0)
	content.Position = UDim2.new(0.05, 0, 0.2, 0)
	content.BackgroundTransparency = 1
	content.Parent = mainFrame

	local contentList = Instance.new("UIListLayout")
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = content

	-- Fetch Data
	local success, response = pcall(function()
		return GetTopPlayers:InvokeServer()
	end)

	if success and typeof(response) == "table" then
		local topPlayers = response.Top or {}
		local personal = response.Personal or {Rank = "---", Score = 0}

		for i, data in ipairs(topPlayers) do
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1, 0, 0.1, 0)
			row.BackgroundTransparency = 1
			row.Font = Enum.Font.FredokaOne
			row.Text = string.format("#%d - %s: %d CR", i, data.Name, data.Score)
			row.TextColor3 = (i == 1) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
			row.TextSize = 25
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Parent = content
		end

		-- SECCIÓN PERSONAL AL FINAL
		local personalLine = Instance.new("Frame")
		personalLine.Size = UDim2.new(1, 0, 0.01, 0)
		personalLine.Position = UDim2.new(0, 0, 1.05, 0)
		personalLine.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		personalLine.BorderSizePixel = 0
		personalLine.Parent = content

		local pRow = Instance.new("TextLabel")
		pRow.Size = UDim2.new(1, 0, 0.15, 0)
		pRow.Position = UDim2.new(0, 0, 1.1, 0)
		pRow.BackgroundTransparency = 1
		pRow.Font = Enum.Font.FredokaOne
		pRow.Text = string.format("TU RANGO: #%s | %d CR", tostring(personal.Rank), personal.Score)
		pRow.TextColor3 = Color3.fromRGB(0, 255, 255)
		pRow.TextSize = 28
		pRow.TextXAlignment = Enum.TextXAlignment.Center
		pRow.Parent = content
	else
		local err = Instance.new("TextLabel")
		err.Size = UDim2.new(1, 0, 0.5, 0)
		err.Text = "Cargando datos..."
		err.TextColor3 = Color3.new(1,1,1)
		err.Parent = content
	end
end

local function init()
	local boards = CollectionService:GetTagged("LeaderboardTag")
	for _, board in ipairs(boards) do
		if board:IsA("BasePart") then
			task.spawn(function()
				while board and board.Parent do
					updateBoard(board)
					task.wait(REFRESH_INTERVAL)
				end
			end)
		end
	end
end

init()

CollectionService:GetInstanceAddedSignal("LeaderboardTag"):Connect(function(instance)
	if instance:IsA("BasePart") then
		updateBoard(instance)
	end
end)
