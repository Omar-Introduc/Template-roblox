local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- 1. Preparation: Wait for assets
local asset = ReplicatedStorage:WaitForChild("asset", 10)
if not asset then
	warn("CRITICAL: 'asset' folder not found in ReplicatedStorage.")
	return
end

local juego1 = asset:WaitForChild("juego1", 10)
if not juego1 then
	warn("CRITICAL: 'juego1' folder not found in ReplicatedStorage.asset.")
	return
end

local lobbyTemplate = juego1:WaitForChild("Lobby", 10)
local platformTemplate = juego1:WaitForChild("Plataforma_Level1", 10)

if not lobbyTemplate then
	warn("CRITICAL: 'Lobby' model not found in juego1.")
	return
end

if not platformTemplate then
	warn("CRITICAL: 'Plataforma_Level1' model not found in juego1.")
	return
end

-- Helper to get size of a model/part
local function getSize(model)
	if model:IsA("Model") then
		local cf, size = model:GetBoundingBox()
		return size
	elseif model:IsA("BasePart") then
		return model.Size
	end
	return Vector3.new(0, 0, 0)
end

-- Helper to set properties safely
local function setupModelProperties(model)
	if model:IsA("BasePart") then
		model.Anchored = true
		pcall(function()
			model.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		end)
	elseif model:IsA("Model") then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				pcall(function()
					descendant.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
				end)
			end
		end
	end
end

-- Helper to set color and material
local function setVisuals(model, color, material)
	if model:IsA("BasePart") then
		model.Color = color
		model.Material = material
	elseif model:IsA("Model") then
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = color
				descendant.Material = material
			end
		end
	end
end

-- Helper to create countdown GUI
local function createCountdownGui()
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextScaled = true
	textLabel.Text = ""
	textLabel.Parent = billboard

	return billboard
end

local function spawnPlatform(index, position, sizeZ)
	local platform = platformTemplate:Clone()
	platform.Name = "Plataforma_" .. index

	-- Setup Initial Properties
	setupModelProperties(platform)

	-- Aesthetics
	local hue = 0.33 - (0.33 * (index - 1) / 49) -- Green (0.33) to Red (0)
	local color = Color3.fromHSV(hue, 1, 1)
	setVisuals(platform, color, Enum.Material.Neon)

	-- Positioning
	if platform:IsA("Model") then
		platform:PivotTo(CFrame.new(position))
	else
		platform.CFrame = CFrame.new(position)
	end

	platform.Parent = workspace

	-- Logic
	local isTouched = false
	local function onTouched(otherPart)
		if isTouched then return end
		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
		if humanoid then
			isTouched = true

			-- Visual Countdown
			local gui = createCountdownGui()
			gui.Parent = platform -- Attach to platform
			-- If platform is model, attach to PrimaryPart or a part
			if platform:IsA("Model") then
				if platform.PrimaryPart then
					gui.Adornee = platform.PrimaryPart
				else
					-- Find first part
					local firstPart = platform:FindFirstChildWhichIsA("BasePart", true)
					if firstPart then gui.Adornee = firstPart end
				end
			else
				gui.Adornee = platform
			end

			-- Countdown 3, 2, 1
			for i = 3, 1, -1 do
				gui.TextLabel.Text = tostring(i)
				task.wait(1)
			end

			-- Fall Logic (T=0)
			gui:Destroy()

			setVisuals(platform, Color3.new(0, 0, 0), Enum.Material.Neon) -- Black

			if platform:IsA("BasePart") then
				platform.CanCollide = false
				platform.Anchored = false
			elseif platform:IsA("Model") then
				for _, d in ipairs(platform:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CanCollide = false
						d.Anchored = false
					end
				end
			end

			-- Destroy at T=2 (2 seconds after fall starts)
			task.delay(2, function()
				if platform and platform.Parent then
					platform:Destroy()
				end
			end)

			-- Respawn at T=5 (5 seconds after fall starts)
			task.delay(5, function()
				spawnPlatform(index, position, sizeZ)
			end)
		end
	end

	-- Connect Touched
	if platform:IsA("BasePart") then
		platform.Touched:Connect(onTouched)
	elseif platform:IsA("Model") then
		-- Connect to all parts or just the main one?
		-- Better to connect to all parts but debounce handles single trigger.
		for _, d in ipairs(platform:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Touched:Connect(onTouched)
			end
		end
	end
end

local function setupLevel()
	-- Spawn Lobby
	local lobby = lobbyTemplate:Clone()
	lobby.Name = "Lobby"
	setupModelProperties(lobby)
	setVisuals(lobby, Color3.fromRGB(60, 60, 60), Enum.Material.Concrete) -- Gris oscuro

	if lobby:IsA("Model") then
		lobby:PivotTo(CFrame.new(0, 10, 0))
	else
		lobby.CFrame = CFrame.new(0, 10, 0)
	end
	lobby.Parent = workspace

	local lobbySize = getSize(lobby)

	-- Generate Platforms
	local currentZ = (0) + (lobbySize.Z / 2) -- Start at edge of lobby?
	-- User says "Lobby en 0,10,0". "Genera 50 plataformas hacia adelante (Eje Z)".
	-- Usually "Forward" is -Z in Roblox, but often users mean +Z.
	-- If "Gap" is positive, let's assume +Z or -Z.
	-- Let's stick to +Z as "Forward" is ambiguous. Actually Default Forward is -Z.
	-- But let's look at existing code or conventions.
	-- I'll use +Z for now as it's common for "progress".
	-- Wait, "50 platforms forward". If I use -Z, I subtract. If +Z, I add.
	-- I'll use +Z because coordinates usually increase.

	-- Wait, let's look at `LevelGenerator.server.luau` in memory if I can recall.
	-- It generated "50 falling platforms with increasing gaps".
	-- Let's stick to +Z.

	-- Calculate Z start.
	-- Lobby at 0. Edge is at +Size.Z/2.

	local zCursor = 10 + (lobbySize.Z / 2) -- Center Z (0) + half size. + 10 offset? No, Lobby is at 0,10,0. Center is 0.
	zCursor = (lobbySize.Z / 2)

	local platformSize = getSize(platformTemplate)

	for i = 1, 50 do
		-- Difficulty: Gap
		-- Initial 4. Increase 0.5 every 5 platforms.
		-- (i-1)//5 gives 0 for 1-5, 1 for 6-10.
		local gapIncrease = math.floor((i - 1) / 5) * 0.5
		local gap = 4 + gapIncrease

		-- Position Calculation
		-- Center to Center = (PrevSize/2) + Gap + (CurrentSize/2)
		-- Since we don't track prev size accurately if they vary, let's assume all platforms are same size as template.
		-- But for the FIRST one, it is LobbyEdge + Gap + PlatformHalf.

		if i == 1 then
			zCursor = zCursor + gap + (platformSize.Z / 2)
		else
			zCursor = zCursor + (platformSize.Z / 2) + gap + (platformSize.Z / 2)
		end

		local pos = Vector3.new(0, 10, zCursor) -- Same Y height (10) as Lobby? Or Lobby floor is at 10?
		-- "Instancia el Lobby en la posición 0, 10, 0".
		-- "Genera 50 plataformas...". Usually meant to be runnable.

		spawnPlatform(i, pos, platformSize.Z)
	end
end

setupLevel()
