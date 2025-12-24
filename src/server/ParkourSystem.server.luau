--[[
    🏃 ParkourSystem - Core Gameplay Logic

    Responsabilidad: Gestionar la generación procedural de caminos, progreso del jugador y checkpoints.
    Optimizado para evitar conflictos de posicionamiento y garantizar la activación de eventos.

    Autor: Arquitecto de Sistemas Roblox (IA)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local Logger = require(ReplicatedStorage.Shared.Logger)

-- Validation System Connection
local VerifyTrajectory = ServerStorage:WaitForChild("VerifyTrajectory", 30)

--------------------------------------------------------------------------------
-- 1. CONFIGURACIÓN Y CONSTANTES
--------------------------------------------------------------------------------

-- Espera de Templates (Crítico)
local Templates = ReplicatedStorage:WaitForChild("Templates")
local FactorySignal = Templates:WaitForChild("FactoryReady", 30)
if not FactorySignal then
	Logger.Critical("🛑 ERROR CRÍTICO: PrefabFactory no respondió a tiempo.")
	error("🛑 ERROR CRÍTICO: PrefabFactory no respondió a tiempo.")
end

-- Configuración de Niveles (Separación > 150 Studs garantizada)
local LEVEL_DATA = {
	{ Index = 1, Name = "Neon Forest",      Pos = Vector3.new(300, 50, 0) },
	{ Index = 2, Name = "Electric Ocean",   Pos = Vector3.new(0, 100, 300) },
	{ Index = 3, Name = "Lava Underworld",  Pos = Vector3.new(-300, 150, 0) },
	{ Index = 4, Name = "Galactic Void",    Pos = Vector3.new(0, 200, -300) }
}

-- Configuración de Dificultad (Ascendente)
local DIFFICULTY = {
	[1] = { DistMin = 10, DistMax = 14, Variance = 2,  LifeTime = 5.0 },
	[2] = { DistMin = 12, DistMax = 16, Variance = 4,  LifeTime = 4.5 },
	[3] = { DistMin = 14, DistMax = 18, Variance = 6,  LifeTime = 4.0 },
	[4] = { DistMin = 16, DistMax = 20, Variance = 8,  LifeTime = 3.5 },
}

-- Estado de Juego
local playerSessions = {} -- { [Player] = { CurrentPath = {}, Active = bool, Level = int } }
local levelCheckpoints = {}

--------------------------------------------------------------------------------
-- 2. UTILIDADES DEL SISTEMA
--------------------------------------------------------------------------------

local function getPlayerSession(player)
	if not playerSessions[player] then
		playerSessions[player] = {
			CurrentPath = {},
			Active = false,
			Level = 0 -- 0 = Lobby
		}
	end
	return playerSessions[player]
end

local function cleanupPath(player)
	local session = playerSessions[player]
	if session and session.CurrentPath then
		for _, block in ipairs(session.CurrentPath) do
			if block and block.Parent then
				-- Efecto de desaparición elegante
				TweenService:Create(block, TweenInfo.new(0.5), {Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
				Debris:AddItem(block, 0.5)
			end
		end
		session.CurrentPath = {}
		session.Active = false
	end
end

--------------------------------------------------------------------------------
-- 3. LÓGICA DE GENERACIÓN PROCEDURAL
--------------------------------------------------------------------------------

local function spawnBlock(player, levelIndex, originPart)
	local session = getPlayerSession(player)
	local diff = DIFFICULTY[levelIndex]
	local targetPos = LEVEL_DATA[levelIndex].Pos

	-- Determinar origen (Bloque anterior o Pad inicial)
	local startPos = Vector3.zero
	if typeof(originPart) == "Instance" then
		startPos = (originPart:IsA("Model") and originPart:GetPivot().Position) or originPart.Position
	else
		-- Si no hay origen válido, abortar
		return
	end

	-- Cálculos vectoriales
	local vecToTarget = (targetPos - startPos) * Vector3.new(1,0,1) -- Proyección plana
	local distTotal = vecToTarget.Magnitude
	local dirToTarget = vecToTarget.Unit
	
	-- Parámetros del salto
	local jumpDist = math.random(diff.DistMin * 10, diff.DistMax * 10) / 10

	-- Caso final: Cerca de la meta
	if distTotal < (jumpDist + 5) then
		jumpDist = distTotal - 4 -- Aterrizaje suave
	end

	-- Variación angular (Espiral)
	local angle = math.rad(math.random(-diff.Variance * 5, diff.Variance * 5))
	local finalDir = CFrame.Angles(0, angle, 0) * dirToTarget
	
	-- Variación de altura (Escalera)
	local heightStep = math.clamp((targetPos.Y - startPos.Y) / (distTotal / jumpDist), 0, 4)
	
	local nextPos = startPos + (finalDir * jumpDist) + Vector3.new(0, heightStep, 0)

	-- VERIFICACIÓN DE TRAYECTORIA
	if VerifyTrajectory then
		local isSafe, reason = VerifyTrajectory:Invoke(startPos, nextPos)
		if not isSafe then
			Logger.Error(string.format("Spawn Block Blocked: %s (Lvl %d)", reason, levelIndex))
			-- Optional: Try to adjust position or abort?
			-- For now, we log and proceed or slightly adjust?
			-- "Antes de spawnear un bloque... debe verificar" implies we might want to stop or retry.
			-- Let's retry once with a different angle?
			-- Simple retry logic:
			angle = angle + math.rad(20)
			finalDir = CFrame.Angles(0, angle, 0) * dirToTarget
			nextPos = startPos + (finalDir * jumpDist) + Vector3.new(0, heightStep, 0)

			-- Re-check
			isSafe, reason = VerifyTrajectory:Invoke(startPos, nextPos)
			if not isSafe then
				Logger.Error("Spawn Block Retry Failed. Aborting block spawn.")
				return
			end
		end
	end

	-- Instanciación
	local folder = Templates:FindFirstChild("Level" .. levelIndex)
	local prefab = folder and folder:FindFirstChild("ParkourBlock")
	if not prefab then prefab = Templates.Level1.ParkourBlock end -- Fallback

	local block = prefab:Clone()
	block.Name = "Path_" .. player.Name
	block:PivotTo(CFrame.new(nextPos, nextPos + dirToTarget)) -- Orientar hacia adelante
	block.Parent = Workspace

	-- Registro
	table.insert(session.CurrentPath, block)

	-- Animación de Entrada
	local targetSize = (block:IsA("Model") and block.PrimaryPart.Size) or block.Size
	if block:IsA("BasePart") then
		block.Size = Vector3.new(0,0,0)
		TweenService:Create(block, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = targetSize}):Play()
	end

	-- Lógica de Interacción (Touch)
	local touchPart = (block:IsA("Model") and block.PrimaryPart) or block
	local db = false
	
	touchPart.Touched:Connect(function(hit)
		if db then return end
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if p == player then
			db = true

			-- Sonido
			local sfx = block:FindFirstChild("JumpSound", true)
			if sfx then sfx:Play() end

			-- Generar siguiente paso
			spawnBlock(player, levelIndex, block)

			-- Destruir anterior (Presión de tiempo/Gameplay)
			task.delay(0.5, function()
				if block.Parent then
					TweenService:Create(touchPart, TweenInfo.new(1), {Transparency = 1, Position = touchPart.Position - Vector3.new(0, 5, 0)}):Play()
					Debris:AddItem(block, 1)
				end
			end)
		end
	end)

	-- Auto-destrucción por inactividad
	task.delay(diff.LifeTime, function()
		if block.Parent then
			block:Destroy()
			-- Si el jugador estaba sobre este bloque, caerá
		end
	end)
end

--------------------------------------------------------------------------------
-- 4. SISTEMA DE ACTIVADORES (PADS)
--------------------------------------------------------------------------------

local function createStarterPad(sourcePart, levelIndexToUnlock)
	local nextLevelIdx = levelIndexToUnlock + 1
	if nextLevelIdx > #LEVEL_DATA then return end -- No hay más niveles
	
	local targetConfig = LEVEL_DATA[nextLevelIdx]
	
	-- Obtener Prefab Correcto
	local folder = Templates:FindFirstChild("Level" .. nextLevelIdx)
	local template = folder and folder:FindFirstChild("StarterPad")
	if not template then
		warn("⚠️ StarterPad no encontrado para Nivel " .. nextLevelIdx)
		return
	end

	local pad = template:Clone()
	pad.Name = "StarterPad_Level" .. nextLevelIdx

	-- POSICIONAMIENTO MATEMÁTICO PRECISO (Anti-Bug)
	local sPos = (sourcePart:IsA("Model") and sourcePart:GetPivot().Position) or sourcePart.Position
	local sSize = (sourcePart:IsA("Model") and sourcePart:GetExtentsSize()) or sourcePart.Size

	-- Fórmula: Superficie superior + 0.5 studs
	local finalY = sPos.Y + (sSize.Y / 2) + 0.5

	-- Dirección hacia el objetivo para ubicarlo en el borde
	local dirToTarget = (targetConfig.Pos - sPos) * Vector3.new(1,0,1)
	dirToTarget = dirToTarget.Unit
	local offsetDist = (sSize.X / 2) - 4 -- 4 studs hacia adentro del borde

	local finalPos = Vector3.new(sPos.X, finalY, sPos.Z) + (dirToTarget * offsetDist)

	pad.Position = finalPos
	pad.CFrame = CFrame.lookAt(finalPos, Vector3.new(targetConfig.Pos.X, finalPos.Y, targetConfig.Pos.Z))
	pad.Parent = Workspace

	-- Lógica de Activación
	local db = false
	pad.Touched:Connect(function(hit)
		if db then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local session = getPlayerSession(player)

			-- Verificar requisitos (Progreso)
			if session.Level >= levelIndexToUnlock then
				db = true
				print("✨ Activando camino para " .. player.Name .. " -> " .. targetConfig.Name)

				cleanupPath(player) -- Limpiar intentos previos
				session.Active = true

				-- Feedback Visual
				pad.Color = Color3.new(1,1,1) -- Flash blanco
				local hl = Instance.new("Highlight")
				hl.FillColor = Color3.new(1,1,1); hl.OutlineTransparency=1; hl.Parent=pad
				Debris:AddItem(hl, 0.3)

				spawnBlock(player, nextLevelIdx, pad)

				task.wait(1)
				pad.Color = Color3.fromRGB(255, 255, 0) -- Restaurar amarillo
				db = false
			else
				-- Feedback Negativo
				pad.Color = Color3.new(1,0,0)
				task.wait(0.5)
				pad.Color = Color3.fromRGB(255, 255, 0)
			end
		end
	end)
end

local function setupWorld()
	print("🌍 Construyendo mundo de Parkour...")
	
	-- 1. Vincular Lobby
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if lobby then
		createStarterPad(lobby, 0) -- Desbloquea Nivel 1
	else
		warn("⚠️ Lobby no encontrado. El juego podría no iniciar correctamente.")
	end

	-- 2. Crear Plataformas de Niveles
	for _, config in ipairs(LEVEL_DATA) do
		local folder = Templates:FindFirstChild("Level" .. config.Index)
		local platPrefab = folder and folder:FindFirstChild("LevelPlatform")
		
		if platPrefab then
			local plat = platPrefab:Clone()
			plat.CFrame = CFrame.new(config.Pos)
			plat.Parent = Workspace
			levelCheckpoints[config.Index] = plat

			-- Crear pad para el SIGUIENTE nivel
			createStarterPad(plat, config.Index)

			-- Trigger de Meta (Checkpoint)
			plat.Touched:Connect(function(hit)
				local p = Players:GetPlayerFromCharacter(hit.Parent)
				if p then
					local session = getPlayerSession(p)
					if config.Index > session.Level then
						session.Level = config.Index
						print("🏆 " .. p.Name .. " desbloqueó: " .. config.Name)
						
						-- Actualizar Leaderstats
						local ls = p:FindFirstChild("leaderstats")
						if ls and ls:FindFirstChild("Stage") then
							ls.Stage.Value = config.Index
						end

						cleanupPath(p) -- Camino completado
					end
				end
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- 5. GESTIÓN DE JUGADORES
--------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	-- Inicializar Leaderstats
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 0
	stage.Parent = ls
	
	-- Inicializar Sesión
	local session = getPlayerSession(player)

	player.CharacterAdded:Connect(function(char)
		-- Teleport inteligente al último checkpoint
		task.wait(0.2)
		local root = char:WaitForChild("HumanoidRootPart", 5)
		if root then
			if session.Level > 0 and levelCheckpoints[session.Level] then
				local plat = levelCheckpoints[session.Level]
				root.CFrame = plat.CFrame * CFrame.new(0, 5, 0)
			else
				local lobby = Workspace:FindFirstChild("Lobby")
				if lobby then
					root.CFrame = CFrame.new(lobby.Position + Vector3.new(0, 5, 0))
				end
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	cleanupPath(player)
	playerSessions[player] = nil
end)

-- Arranque
task.spawn(setupWorld)
