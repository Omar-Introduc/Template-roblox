local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- 1. Constants and Settings
local ASSET_PATH = "juego1"
local MAX_PLATFORMS = 50
local START_HEIGHT = 10
local BASE_GAP = 4
local GAP_INCREMENT = 0.5
local INCREMENT_STEP = 5

local THEME_COLORS = {
	Concrete = Color3.fromHex("#444444"), -- Gris Oscuro
	Basalt = Color3.fromHex("#2a2a2a"), -- Casi Negro
	Wood = Color3.fromHex("#5D4037"), -- Marrón
	Fabric = Color3.fromHex("#D7CCC8"), -- Fondo Cartel
	Plastic = Color3.fromHex("#3E2723"), -- Borde Cartel
	Black = Color3.new(0, 0, 0)
}

-- 2. Wait for Assets
local assetFolder = ReplicatedStorage:WaitForChild("asset", 10)
if not assetFolder then
	warn("CRITICAL: 'asset' folder not found in ReplicatedStorage.")
	return
end

local gameAssets = assetFolder:WaitForChild(ASSET_PATH, 10)
if not gameAssets then
	warn("CRITICAL: 'juego1' folder not found in ReplicatedStorage.asset.")
	return
end

local lobbyTemplate = gameAssets:WaitForChild("Lobby", 10)
local platformTemplate = gameAssets:WaitForChild("Plataforma_Level1", 10)

-- 3. Helper Functions

-- Helper to apply theme based on part names
local function applyTheme(model, difficultyIndex)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Physics Setup
			part.Anchored = true
			pcall(function()
				part.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			end)

			local name = part.Name

			-- Material and Color Logic
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
					-- Green (0.33) -> Red (0.0)
					local progress = math.clamp((difficultyIndex - 1) / (MAX_PLATFORMS - 1), 0, 1)
					local hue = 0.33 * (1 - progress)
					part.Color = Color3.fromHSV(hue, 1, 1)
				end
			end
		end
	end
end

-- Helper to get model size (Z axis)
local function getModelSizeZ(model)
	if model:IsA("Model") then
		local _, size = model:GetBoundingBox()
		return size.Z
	elseif model:IsA("BasePart") then
		return model.Size.Z
	end
	return 0
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

local function spawnPlatform(index, cframe, sizeZ)
	local model = platformTemplate:Clone()
	model.Name = "Plataforma_" .. index
	model:PivotTo(cframe)
	model.Parent = workspace

	applyTheme(model, index)

	-- Gameplay Logic
	local triggered = false

	-- Identify the main interaction part
	local mainPart = nil
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name:match("PlataformaPrincipal") then
			mainPart = p
			break
		end
	end
	-- Fallback
	if not mainPart then
		mainPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	end

	local function onTouched(hit)
		if triggered then return end
		if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
			triggered = true

			-- Countdown
			local bb, textLabel = createCountdown(mainPart)
			for i = 3, 1, -1 do
				textLabel.Text = tostring(i)
				task.wait(1)
			end
			bb:Destroy()

			-- Fall
			for _, p in ipairs(model:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Color = THEME_COLORS.Black
					p.Anchored = false
					p.CanCollide = false
				end
			end

			-- Destroy after 2s
			task.delay(2, function()
				if model then model:Destroy() end
			end)

			-- Respawn after 5s (from fall start)
			task.delay(5, function()
				spawnPlatform(index, cframe, sizeZ)
			end)
		end
	end

	if mainPart then
		mainPart.Touched:Connect(onTouched)
	end
end

-- 4. Main Level Generation
local function generateLevel()
	-- Clean workspace
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "Lobby" or child.Name:match("Plataforma_") then
			child:Destroy()
		end
	end

	-- Spawn Lobby
	local lobby = lobbyTemplate:Clone()
	lobby.Name = "Lobby"
	lobby:PivotTo(CFrame.new(0, START_HEIGHT, 0))
	lobby.Parent = workspace
	applyTheme(lobby, nil)

	local lobbySizeZ = getModelSizeZ(lobby)

	-- Calculate Start Position (Center of Lobby + Half Size = Edge)
	-- Platforms go along +Z
	local currentZ = (lobbySizeZ / 2)

	local platformSizeZ = getModelSizeZ(platformTemplate)

	for i = 1, MAX_PLATFORMS do
		-- Gap Calculation
		local gapMultiplier = math.floor((i - 1) / INCREMENT_STEP)
		local currentGap = BASE_GAP + (gapMultiplier * GAP_INCREMENT)

		-- Position: Previous Edge + Gap + Half Size
		local centerZ = currentZ + currentGap + (platformSizeZ / 2)

		local platformCFrame = CFrame.new(0, START_HEIGHT, centerZ) -- Fixed Rotation (0,0,0)
		spawnPlatform(i, platformCFrame, platformSizeZ)

		-- Update cursor to new edge
		currentZ = centerZ + (platformSizeZ / 2)
	end
end

generateLevel()
