--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementService = require(Shared:WaitForChild("MovementService"))
local PlatformSpawner = require(Shared:WaitForChild("PlatformSpawner"))
local FeedbackService = require(Shared:WaitForChild("FeedbackService"))
local AssetScanner = require(Shared:WaitForChild("AssetScanner"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- Event System Setup (Decoupling)
local EventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not EventsFolder then
	EventsFolder = Instance.new("Folder")
	EventsFolder.Name = "Events"
	EventsFolder.Parent = ReplicatedStorage
end

local PlatformTriggered = EventsFolder:FindFirstChild("PlatformTriggered") --[[@as BindableEvent]]
if not PlatformTriggered then
	PlatformTriggered = Instance.new("BindableEvent")
	PlatformTriggered.Name = "PlatformTriggered"
	PlatformTriggered.Parent = EventsFolder
end

local RequestPointsEvent = EventsFolder:FindFirstChild("RequestPlatformPoints") --[[@as RemoteEvent]]
if not RequestPointsEvent then
	RequestPointsEvent = Instance.new("RemoteEvent")
	RequestPointsEvent.Name = "RequestPlatformPoints"
	RequestPointsEvent.Parent = EventsFolder
end

-- Inicializar UI Service (FeedbackService) para escuchar eventos
FeedbackService.Init(PlatformTriggered.Event)

-- Inicializar Mapa
AssetScanner.Init()

local estructuras = workspace:WaitForChild("Estructuras")

-- Calcular CentroGlobalZ
local CentroGlobalZ = 0
local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
if spawnLocation then
	CentroGlobalZ = spawnLocation.Position.Z
else
	local p1_inicial = estructuras:WaitForChild("Plataforma_1", 10)
	if p1_inicial then
		CentroGlobalZ = p1_inicial:GetPivot().Position.Z
	end
end

-- Eventos
local PointAwarded = EventsFolder:FindFirstChild("PointAwarded") --[[@as RemoteEvent]]
if not PointAwarded then
	warn("⚠️ [GameManager] 'PointAwarded' RemoteEvent no encontrado en ReplicatedStorage/Events!")
end

local function otorgarPuntos(player: Player, platformName: string, position: Vector3)
	local nPlataforma = tonumber(string.match(platformName, "_(%d+)")) or 1
	local basePuntos = nPlataforma

	local multiplicador = 1
	if player.Character then
		multiplicador = player.Character:GetAttribute("PointMultiplier") or 1
	end

	local puntosAGanar = basePuntos * multiplicador

	-- print(string.format("DEBUG: otorgarPuntos -> Player: %s, Platform: %s, Puntos: %d", player.Name, platformName, puntosAGanar))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cr = leaderstats:FindFirstChild("CR") --[[@as NumberValue]]
		if cr then
			cr.Value += puntosAGanar
			if PointAwarded then
				PointAwarded:FireClient(player, puntosAGanar, position)
			end
		end
	end
end

-- Validate Request Points from Client
RequestPointsEvent.OnServerEvent:Connect(function(player: Player, platform: Instance)
	if not platform or not platform:IsA("Model") and not platform:IsA("BasePart") then return end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then return end

	local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
	if not mainPart or not mainPart:IsA("BasePart") then return end

	-- Validate Distance
	local dist = (rootPart.Position - mainPart.Position).Magnitude
	-- Safe margin: Platform size + some latency tolerance
	-- Assuming platforms are not massive, 25 studs should be enough
	if dist > 30 then
		-- Too far, likely cheating or heavy lag
		return
	end

	-- Award Points
	otorgarPuntos(player, platform.Name, mainPart.Position)
end)

-- Forward declaration
local activatePlatform

local function handlePlatformTouch(platform: Instance, mainPart: BasePart)
	local connection
	connection = mainPart.Touched:Connect(function(hit)
		if platform:GetAttribute("Triggered") then return end
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- 1. Marcar como pisada
		platform:SetAttribute("Triggered", true)

		-- 2. Spawnea la siguiente
		PlatformSpawner.SpawnNext(platform, estructuras, CentroGlobalZ)

		-- 3. Otorgar puntos (Inicial)
		otorgarPuntos(player, platform.Name, mainPart.Position)

		-- 4. Iniciar loop de puntos continuos -> DELEGATED TO CLIENT (RequestPointsEvent)
		-- The server no longer runs a loop here.

		if platform.Name == "Plataforma_1" then
			return -- Plataforma inicial no cae
		end

		-- 5. Feedback Visual (Countdown) - USANDO EVENTO
		PlatformTriggered:Fire(platform, GameConfig.COUNTDOWN_TIME)

		-- Esperar cuenta regresiva
		task.wait(GameConfig.COUNTDOWN_TIME)

		-- 6. Caída
		MovementService.StopMovement(platform)

		mainPart.Color = Color3.new(0, 0, 0)
		mainPart.Anchored = false
		mainPart.CanCollide = false

		if connection then connection:Disconnect() end

		-- 7. Reset / Reactivar después de caer
		task.delay(GameConfig.FALL_DELAY + GameConfig.RESET_DELAY, function()
			activatePlatform(platform)
		end)
	end)
end

activatePlatform = function(platform: Instance)
	if not platform or platform.Name == "PlataformaTemplate" then return end
	if platform:GetAttribute("IsActive") then return end
	platform:SetAttribute("IsActive", true)

	local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
	if not mainPart or not mainPart:IsA("BasePart") then return end

	if not platform:GetAttribute("OriginalPivot") then
		platform:SetAttribute("OriginalPivot", platform:GetPivot())
	end

	MovementService.StopMovement(platform)

	-- Reset Properties
	mainPart.Anchored = true
	mainPart.CanCollide = true
	mainPart.Transparency = 0
	mainPart.AssemblyLinearVelocity = Vector3.zero
	mainPart.AssemblyAngularVelocity = Vector3.zero

	local pivotBase = platform:GetAttribute("OriginalPivot") --[[@as CFrame]]
	platform:PivotTo(pivotBase)

	platform:SetAttribute("Triggered", false)
	mainPart.Color = Color3.fromRGB(163, 162, 165) -- Default grey-ish

	if platform.Name ~= "Plataforma_1" then
		MovementService.StartMovement(platform, {CentroZ = CentroGlobalZ})
	end

	handlePlatformTouch(platform, mainPart)
end

-- Limpieza de mapa al entrar jugador
local function resetMapProgress()
	if not estructuras then return end
	for _, objeto in ipairs(estructuras:GetChildren()) do
		if string.match(objeto.Name, "Plataforma_") and objeto.Name ~= "Plataforma_1" then
			objeto:Destroy()
		elseif objeto.Name == "Plataforma_1" then
			objeto:SetAttribute("Triggered", false)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		resetMapProgress()
	end)
end)

-- Inicializar plataformas existentes
for _, platform in ipairs(CollectionService:GetTagged(GameConfig.TAG_PLATFORMA)) do
	activatePlatform(platform)
end

CollectionService:GetInstanceAddedSignal(GameConfig.TAG_PLATFORMA):Connect(function(instance)
	task.wait(0.1)
	activatePlatform(instance)
end)
