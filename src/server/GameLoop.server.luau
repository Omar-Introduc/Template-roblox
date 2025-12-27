local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Configuration Settings
local CONFIG = {
	ASSET_PATH = "juego1",
	MAX_PLATFORMS = 50,
	BASE_GAP = 12,
	GAP_INCREMENT = 0.5,
	INCREMENT_STEP = 5,
	START_HEIGHT = 10,
	REGENERATE_LEVEL = false, -- 🚩 SET TO FALSE TO KEEP MANUAL CHANGES
}

local THEME_COLORS = {
	Concrete = Color3.fromHex("#444444"),
	Basalt = Color3.fromHex("#2a2a2a"),
	Wood = Color3.fromHex("#5D4037"),
	Fabric = Color3.fromHex("#D7CCC8"),
	Plastic = Color3.fromHex("#3E2723"),
	Black = Color3.new(0, 0, 0)
}

-- 2. Setup Assets
local assetFolder = ReplicatedStorage:WaitForChild("asset", 10)
local gameAssets = assetFolder and assetFolder:WaitForChild(CONFIG.ASSET_PATH, 10)

if not gameAssets then
	warn("CRITICAL: Assets not found in ReplicatedStorage.asset." .. CONFIG.ASSET_PATH)
	return
end

-- 3. Utility Functions
local function findAsset(parent, name)
	local targetName = name:lower()
	
	-- Level 1: Direct child search (Case insensitive)
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name:lower() == targetName then
			return child
		end
	end
	
	-- Level 2: Recursive search
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Folder") or child:IsA("Model") then
			local found = findAsset(child, name)
			if found then return found end
		end
	end
	
	-- Level 3: Partial match fallback (e.g., if searching for "Lobby" matches "MiLobby_v2")
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name:lower():match(targetName) then
			return child
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

-- 4. Gameplay Logic
local function activatePlatform(index, model, template, parent)
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

				-- Physics/Visual change
				for _, p in ipairs(model:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Color = THEME_COLORS.Black
						p.Anchored = false
						p.CanCollide = false
					end
				end

				task.delay(2, function() if model then model:Destroy() end end)
				task.delay(5, function() 
					local cframe = model:GetPivot()
					local newModel = template:Clone()
					newModel.Name = model.Name
					newModel:PivotTo(cframe)
					newModel.Parent = parent
					applyTheme(newModel, index)
					activatePlatform(index, newModel, template, parent)
				end)
			end
		end)
	end
end

local function spawnPlatform(index, cframe, template, parent)
	local model = template:Clone()
	model.Name = "Salto_" .. index
	model:PivotTo(cframe)
	model.Parent = parent
	applyTheme(model, index)
	activatePlatform(index, model, template, parent)
end

-- 5. Final Generation
local function generateLevel()
	print("🚀 Ejecutando GameLoop...")
	
	-- 🧹 Cleanup Environment
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then 
		print("🗑️ Eliminando Baseplate...")
		baseplate:Destroy() 
	end

	local realPlatform = findAsset(gameAssets, "Plataforma_Level1")
	local realLobbyTemplate = findAsset(gameAssets, "Lobby")
	
	-- Robust Search in Workspace (Recursive to find nested objects)
	local lobby = workspace:FindFirstChild("Lobby", true)
	local levelContainer = workspace:FindFirstChild("Level_1", true) or workspace:FindFirstChild("Level1", true)

	-- 🎯 Analyze Geometry (Common for both modes)
	local struct1, struct2 = nil, nil
	if lobby then
		for _, p in ipairs(lobby:GetDescendants()) do
			local n = p.Name:lower()
			if n == "estructura1" then struct1 = p elseif n == "estructura2" then struct2 = p end
		end
	end

	local pathDirection = lobby and lobby:GetPivot().LookVector or Vector3.new(0,0,1)
	local lobbyBasePos = lobby and lobby:GetPivot().Position or Vector3.new(0, CONFIG.START_HEIGHT, 0)
	local startPoint = lobbyBasePos
	local rotationAnglePath = math.atan2(pathDirection.X, pathDirection.Z)

	if struct1 and struct2 then
		startPoint = Vector3.new((struct1.Position.X + struct2.Position.X)/2, lobbyBasePos.Y, (struct1.Position.Z + struct2.Position.Z)/2)
		local widthVector = (struct2.Position - struct1.Position).Unit
		pathDirection = widthVector:Cross(Vector3.new(0, 1, 0))
		
		-- Sanity Check
		local outward = (startPoint - Vector3.new(lobbyBasePos.X, startPoint.Y, lobbyBasePos.Z)).Unit
		if pathDirection:Dot(outward) < 0 then pathDirection = -pathDirection end
		rotationAnglePath = math.atan2(pathDirection.X, pathDirection.Z)
	end
	
	-- Platform Rotation Data
	if not realPlatform then 
		warn("❌ No se encontró Plataforma_Level1 en assets.") 
		return 
	end

	local _, platformSize = realPlatform:GetBoundingBox()
	local internalRotation = (platformSize.X > platformSize.Z) and 0 or math.rad(90)
	local basePlatformRotation = rotationAnglePath + internalRotation
	local finalDepth = math.min(platformSize.X, platformSize.Z)

	-- A) REGENERATE MODE
	if CONFIG.REGENERATE_LEVEL then
		print("🔄 Modo REGENERATE activo...")
		if levelContainer then levelContainer:Destroy() end
		if lobby then lobby:Destroy() end
		
		levelContainer = Instance.new("Folder")
		levelContainer.Name = "Level_1"
		levelContainer.Parent = workspace

		if realLobbyTemplate then
			lobby = realLobbyTemplate:Clone()
			lobby.Name = "Lobby"
			lobby:PivotTo(CFrame.new(0, CONFIG.START_HEIGHT, 0))
			lobby.Parent = workspace
			applyTheme(lobby, nil)
		end

		local currentDistance = 0
		for i = 1, CONFIG.MAX_PLATFORMS do
			local currentGap = CONFIG.BASE_GAP + (math.floor((i - 1) / CONFIG.INCREMENT_STEP) * CONFIG.GAP_INCREMENT)
			currentDistance += currentGap + (finalDepth / 2)
			local targetPos = startPoint + (pathDirection * currentDistance)
			local platformCFrame = CFrame.new(targetPos) * CFrame.Angles(0, basePlatformRotation, 0)
			spawnPlatform(i, platformCFrame, realPlatform, levelContainer)
			currentDistance += (finalDepth / 2)
		end
		
	-- B) MANUAL/FREEZE MODE
	else
		print("❄️ Modo MANUAL activo.")
		
		-- Safety spawn for Lobby if missing completely
		if not lobby and realLobbyTemplate then
			print("⚠️ Lobby no encontrado. Cargando desde Assets...")
			lobby = realLobbyTemplate:Clone()
			lobby.Name = "Lobby"
			lobby.Parent = workspace
			applyTheme(lobby, nil)
		end

		if not levelContainer then
			levelContainer = Instance.new("Folder")
			levelContainer.Name = "Level_1"
			levelContainer.Parent = workspace
		end

		local children = levelContainer:GetChildren()
		if #children == 0 then
			print("🆕 Level_1 vacío. Instanciando plataforma de salto inicial...")
			-- Spawn exactly at the arch midpoint or slightly forward
			local firstGap = CONFIG.BASE_GAP
			local targetPos = startPoint + (pathDirection * (firstGap + finalDepth/2))
			local platformCFrame = CFrame.new(targetPos) * CFrame.Angles(0, basePlatformRotation, 0)
			spawnPlatform(1, platformCFrame, realPlatform, levelContainer)
		else
			print("✅ Vinculando lógica a " .. #children .. " plataformas manuales.")
			for i, child in ipairs(children) do
				if child:IsA("Model") then
					applyTheme(child, i)
					activatePlatform(i, child, realPlatform, levelContainer)
				end
			end
		end
		
		if lobby then 
			applyTheme(lobby, nil) 
		end
	end
	
	print("✨ Generación finalizada.")
end

task.spawn(generateLevel)
