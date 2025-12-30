--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementService = require(Shared:WaitForChild("MovementService"))
local PlatformSpawner = require(Shared:WaitForChild("PlatformSpawner"))
local FeedbackService = require(Shared:WaitForChild("FeedbackService"))
local AssetScanner = require(script.Parent:WaitForChild("AssetScanner"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local GameManager = {}

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

-- Rate Limiting System
local COOLDOWN_TIME = 0.5
local lastPointRequest = {} -- [Player] = { [PlatformInstance] = timestamp }

Players.PlayerRemoving:Connect(function(player)
	lastPointRequest[player] = nil
end)

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

function GameManager:Start()
	print("✅ GameManager Started (Loop delegated to events)")
end

function GameManager.otorgarPuntos(player: Player, platformName: string, position: Vector3)
	local nPlataforma = tonumber(string.match(platformName, "_(%d+)")) or 1
	local basePuntos = nPlataforma

	local multiplicador = 1
	if player.Character then
		multiplicador = (player.Character:GetAttribute("PointMultiplier") :: number?) or 1
	end

	local puntosAGanar = (basePuntos or 1) * multiplicador

	-- print(string.format("DEBUG: otorgarPuntos -> Player: %s, Platform: %s, Puntos: %d", player.Name, platformName, puntosAGanar))
	print(string.format("DEBUG: Awarding %d points to %s for %s", puntosAGanar, player.Name, platformName))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cr = leaderstats:FindFirstChild("CR")
		if cr and (cr:IsA("NumberValue") or cr:IsA("IntValue")) then
			local valInstance = cr :: NumberValue -- Cast to interface that has .Value
			local oldValue = valInstance.Value
			valInstance.Value += puntosAGanar
			print(string.format("DEBUG: Updated CR from %d to %d", oldValue, valInstance.Value))
			
			if PointAwarded then
				PointAwarded:FireClient(player, puntosAGanar, position)
			else
				warn("⚠️ [GameManager] PointAwarded RemoteEvent is nil")
			end
		else
			warn("❌ [GameManager] CR Value not found or not a NumberValue/IntValue in leaderstats")
		end
	else
		warn("❌ [GameManager] leaderstats folder not found on player " .. player.Name)
	end
end

function GameManager.ValidatePointRequest(player: Player, platform: Instance)
	if not platform then return false, "Invalid Platform" end
	
	local mainPart: BasePart?
	if platform:IsA("Model") then
		mainPart = platform.PrimaryPart
	elseif platform:IsA("BasePart") then
		mainPart = platform
	end
	
	if not mainPart then
		return false, "Invalid Platform Type"
	end

	-- 1. Rate Limiting Check
	if not lastPointRequest[player] then
		lastPointRequest[player] = {}
	end

	local lastTime = lastPointRequest[player][platform]
	local now = os.clock()

	if lastTime and (now - lastTime < COOLDOWN_TIME) then
		return false, "Rate Limit"
	end

	lastPointRequest[player][platform] = now

	local character = player.Character
	if not character then return false, "No Character" end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then return false, "No RootPart" end

	-- Validate Distance
	local dist = (rootPart.Position - mainPart.Position).Magnitude
	-- Safe margin: Platform size + some latency tolerance
	-- Assuming platforms are not massive, 25 studs should be enough
	if dist > 30 then
		return false, "Too Far"
	end

	return true, "Valid"
end

-- Validate Request Points from Client
RequestPointsEvent.OnServerEvent:Connect(function(player: Player, platform: Instance)
	print(string.format("DEBUG: Server received point request from %s for %s", player.Name, platform.Name))
	local valid, reason = GameManager.ValidatePointRequest(player, platform)
	if valid then
		local mainPart: BasePart?
		if platform:IsA("Model") then
			mainPart = platform.PrimaryPart
		elseif platform:IsA("BasePart") then
			mainPart = platform
		end
		
		if mainPart then
			GameManager.otorgarPuntos(player, platform.Name, mainPart.Position)
		end
	else
		-- DEBUG: Warn user why point was rejected (helps with "missing prefab" issues)
		if reason ~= "Rate Limit" then -- Ignore rate limit spam
			warn(string.format("❌ [GameManager] Point Rejected for %s on %s: %s", player.Name, platform.Name, tostring(reason)))
		end
	end
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
		GameManager.otorgarPuntos(player, platform.Name, mainPart.Position)

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

	local mainPart: BasePart? = nil
	if platform:IsA("Model") then
		mainPart = platform.PrimaryPart
	elseif platform:IsA("BasePart") then
		mainPart = platform
	end
	
	if not mainPart then return end

	if not platform:GetAttribute("OriginalPivot") then
		if platform:IsA("Model") or platform:IsA("BasePart") then
			platform:SetAttribute("OriginalPivot", (platform :: PVInstance):GetPivot())
            if mainPart then
                platform:SetAttribute("OriginalColor", mainPart.Color)
            end
		end
	end

	MovementService.StopMovement(platform)

	-- Reset Properties
	mainPart.Anchored = true
	mainPart.CanCollide = true
	mainPart.Transparency = 0
	mainPart.AssemblyLinearVelocity = Vector3.zero
	mainPart.AssemblyAngularVelocity = Vector3.zero

	local pivotBase = platform:GetAttribute("OriginalPivot") :: CFrame
	if platform:IsA("Model") or platform:IsA("BasePart") then
		(platform :: PVInstance):PivotTo(pivotBase)
	end

	platform:SetAttribute("Triggered", false)
	
    local savedColor = platform:GetAttribute("OriginalColor")
    if savedColor and typeof(savedColor) == "Color3" then
        mainPart.Color = savedColor
    else
	    mainPart.Color = Color3.fromRGB(163, 162, 165) -- Fallback only if no original color found
    end

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

return GameManager
