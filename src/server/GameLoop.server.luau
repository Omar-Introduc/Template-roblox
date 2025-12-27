local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Configuration Settings
local CONFIG = {
	ASSET_PATH = "juego1",
	MAX_PLATFORMS = 50,
	START_HEIGHT = 10,
	BASE_GAP = 4,
	GAP_INCREMENT = 0.5,
	INCREMENT_STEP = 5,
}

-- 2. Wait for Assets
local assetFolder = ReplicatedStorage:WaitForChild("asset", 10)
local gameAssets = assetFolder and assetFolder:WaitForChild(CONFIG.ASSET_PATH, 10)

if not gameAssets then
	warn("CRITICAL: Assets not found in ReplicatedStorage.asset." .. CONFIG.ASSET_PATH)
	return
end

-- 3. Helper Functions
local function findAsset(parent, name)
	local found = parent:FindFirstChild(name)
	if found then return found end
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Folder") or child:IsA("Model") then
			found = findAsset(child, name)
			if found then return found end
		end
	end
	return nil
end

local function createCountdown(parent)
	local bb = Instance.new("BillboardGui")
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
	text.Parent = bb
	bb.Parent = parent
	return bb, text
end

local function spawnPlatform(index, cframe, template, parent)
	local model = template:Clone()
	model.Name = "Salto_" .. index
	model:PivotTo(cframe)
	model.Parent = parent

	local mainPart = nil
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name:match("PlataformaPrincipal") then 
			mainPart = p 
			break 
		end
	end
	if not mainPart then 
		mainPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) 
	end

	if mainPart then
		local triggered = false
		mainPart.Touched:Connect(function(hit)
			if triggered then return end
			if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
				triggered = true
				local bb, textLabel = createCountdown(mainPart)
				for i = 3, 1, -1 do
					textLabel.Text = tostring(i)
					task.wait(1)
				end
				bb:Destroy()

				-- Fall logic
				for _, p in ipairs(model:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Color = Color3.new(0, 0, 0) -- Turn black
						p.Anchored = false
						p.CanCollide = false
					end
				end

				task.delay(2, function() 
					if model then model:Destroy() end 
				end)
				task.delay(5, function() 
					spawnPlatform(index, cframe, template, parent) 
				end)
			end
		end)
	end
end

-- 4. Main Level Generation
local function generateLevel()
	print("🚀 Iniciando generación de nivel simplificada...")
	
	-- Cleanup Level
	local existingLevel = workspace:FindFirstChild("Level_1")
	if existingLevel then existingLevel:Destroy() end

	local levelContainer = Instance.new("Folder")
	levelContainer.Name = "Level_1"
	levelContainer.Parent = workspace

	-- Setup Lobby
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		local realLobby = findAsset(gameAssets, "Lobby")
		if realLobby then
			lobby = realLobby:Clone()
			lobby.Name = "Lobby"
			-- lobby:PivotTo(CFrame.new(0, CONFIG.START_HEIGHT, 0)) -- Removed to respect saved asset position
			lobby.Parent = workspace
		end
	else
		print("📦 Usando Lobby establecido en Workspace.")
	end

	local realPlatform = findAsset(gameAssets, "Plataforma_Level1")
	if not (lobby and realPlatform) then
		warn("❌ CRITICAL: No se pudo encontrar Lobby o Plataforma_Level1")
		return
	end
	
	-- Simplified Generation Logic
	-- Assume generation direction is forward (Z+) relative to Lobby
	local lobbyCF, lobbySize = lobby:GetBoundingBox()
	local pathDirection = lobbyCF.LookVector

	-- Flatten direction to horizontal plane and normalize
	pathDirection = Vector3.new(pathDirection.X, 0, pathDirection.Z)
	if pathDirection.Magnitude < 0.001 then
		pathDirection = Vector3.new(0, 0, 1) -- Default to Z+ if invalid
	else
		pathDirection = pathDirection.Unit
	end

	-- Determine start offset based on Lobby size
	local startDistance = lobbySize.Z / 2

	-- Platform dimensions
	local _, platformSize = realPlatform:GetBoundingBox()
	local platformDepth = platformSize.Z

	local currentDistance = startDistance
	local startPoint = lobbyCF.Position

	for i = 1, CONFIG.MAX_PLATFORMS do
		-- Calculate Gap
		local currentGap = CONFIG.BASE_GAP + (math.floor((i - 1) / CONFIG.INCREMENT_STEP) * CONFIG.GAP_INCREMENT)
		
		-- Move cursor forward by gap
		currentDistance += currentGap

		-- Add half of platform depth to center it
		currentDistance += (platformDepth / 2)

		-- Calculate Position
		local targetPos = startPoint + (pathDirection * currentDistance)
		local platformCFrame = CFrame.new(targetPos) * lobbyCF.Rotation -- Maintain Lobby's orientation
		
		spawnPlatform(i, platformCFrame, realPlatform, levelContainer)

		-- Advance cursor by the other half of platform depth for next iteration
		currentDistance += (platformDepth / 2)
	end
	
	print("✨ Generación completada con éxito!")
end

task.spawn(generateLevel)
