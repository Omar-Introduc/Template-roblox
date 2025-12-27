local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Configuration Settings
local CONFIG = {
	ASSET_PATH = "juego1",
	MAX_PLATFORMS = 50,
	START_HEIGHT = 10,  -- Default if no Lobby exists
	BASE_GAP = 4,
	GAP_INCREMENT = 0.5,
	INCREMENT_STEP = 5,
}

local THEME_COLORS = {
	Concrete = Color3.fromHex("#444444"),
	Basalt = Color3.fromHex("#2a2a2a"),
	Wood = Color3.fromHex("#5D4037"),
	Fabric = Color3.fromHex("#D7CCC8"),
	Plastic = Color3.fromHex("#3E2723"),
	Black = Color3.new(0, 0, 0)
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

local function applyTheme(model, difficultyIndex)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			pcall(function() part.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end)
			
			local name = part.Name
			if name:match("Suelo") or name:match("Piso") or name:match("Base") then
				part.Material = Enum.Material.Concrete
				part.Color = THEME_COLORS.Concrete
			elseif name:match("Roca") or name:match("Piedra") then
				part.Material = Enum.Material.Basalt
				part.Color = THEME_COLORS.Basalt
			elseif name:match("Madera") or name:match("Puente") or name:match("Viga") then
				part.Material = Enum.Material.Wood
				part.Color = THEME_COLORS.Wood
			elseif name:match("Cartel") then
				part.Material = Enum.Material.Fabric
				part.Color = THEME_COLORS.Fabric
			elseif name:match("Borde") then
				part.Material = Enum.Material.Plastic
				part.Color = THEME_COLORS.Plastic
			elseif name:match("PlataformaPrincipal") then
				part.Material = Enum.Material.Neon
				if difficultyIndex then
					local progress = math.clamp((difficultyIndex - 1) / (CONFIG.MAX_PLATFORMS - 1), 0, 1)
					part.Color = Color3.fromHSV(0.33 * (1 - progress), 1, 1)
				end
			end
		end
	end
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
	applyTheme(model, index)

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
				for _, p in ipairs(model:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Color = THEME_COLORS.Black
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
	print("🚀 Iniciando generación de nivel...")
	
	-- Cleanup Level (but keep the Lobby if it's there)
	local existingLevel = workspace:FindFirstChild("Level_1")
	if existingLevel then existingLevel:Destroy() end

	local levelContainer = Instance.new("Folder")
	levelContainer.Name = "Level_1"
	levelContainer.Parent = workspace

	-- Check if Lobby is already in Workspace (Established Position)
	local lobby = workspace:FindFirstChild("Lobby")
	local currentBaseHeight = CONFIG.START_HEIGHT

	if not lobby then
		local realLobby = findAsset(gameAssets, "Lobby")
		if realLobby then
			lobby = realLobby:Clone()
			lobby.Name = "Lobby"
			lobby:PivotTo(CFrame.new(0, CONFIG.START_HEIGHT, 0))
			lobby.Parent = workspace
			applyTheme(lobby, nil)
		end
	else
		print("📦 Usando Lobby establecido en Workspace.")
		currentBaseHeight = lobby:GetPivot().Position.Y
	end

	local realPlatform = findAsset(gameAssets, "Plataforma_Level1")
	if not (lobby and realPlatform) then
		warn("❌ CRITICAL: No se pudo encontrar Lobby o Plataforma_Level1")
		return
	end

	-- 🎯 Analyze Geometry
	local struct1, struct2 = nil, nil
	for _, p in ipairs(lobby:GetDescendants()) do
		local n = p.Name:lower()
		if n == "estructura1" then struct1 = p elseif n == "estructura2" then struct2 = p end
	end
	
	local pathDirection = Vector3.new(0, 0, 1)
	local startPoint = Vector3.new(0, currentBaseHeight, 0)
	local rotationAnglePath = 0

	if struct1 and struct2 then
		startPoint = Vector3.new((struct1.Position.X + struct2.Position.X)/2, currentBaseHeight, (struct1.Position.Z + struct2.Position.Z)/2)
		local widthVector = (struct2.Position - struct1.Position).Unit
		pathDirection = widthVector:Cross(Vector3.new(0, 1, 0))
		
		-- Outward Sanity Check
		local lobbyPos = lobby:GetPivot().Position
		local outward = (startPoint - Vector3.new(lobbyPos.X, currentBaseHeight, lobbyPos.Z)).Unit
		if pathDirection:Dot(outward) < 0 then pathDirection = -pathDirection end
		
		rotationAnglePath = math.atan2(pathDirection.X, pathDirection.Z)
	end

	-- 📐 Platform Settings
	local _, platformOrigSize = realPlatform:GetBoundingBox()
	local internalRotation = (platformOrigSize.X > platformOrigSize.Z) and 0 or math.rad(90)
	local basePlatformRotation = rotationAnglePath + internalRotation
	local finalDepth = math.min(platformOrigSize.X, platformOrigSize.Z)

	-- 🏃 Spawn Platforms
	local currentDistance = 0
	for i = 1, CONFIG.MAX_PLATFORMS do
		local currentGap = CONFIG.BASE_GAP + (math.floor((i - 1) / CONFIG.INCREMENT_STEP) * CONFIG.GAP_INCREMENT)
		currentDistance += currentGap + (finalDepth / 2)
		
		local targetPos = startPoint + (pathDirection * currentDistance)
		local platformCFrame = CFrame.new(targetPos) * CFrame.Angles(0, basePlatformRotation, 0)
		
		spawnPlatform(i, platformCFrame, realPlatform, levelContainer)
		currentDistance += (finalDepth / 2)
	end
	
	print("✨ Generación completada con éxito!")
end

task.spawn(generateLevel)
