local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 1. Inicialización y Espera de Fábrica
print("🏃 ParkourSystem: Inicializando...")
local Templates = ReplicatedStorage:WaitForChild("Templates")

-- Esperar señal de listo
local readySignal = Templates:WaitForChild("FactoryReady", 20)
if not readySignal then
	error("🛑 CRÍTICO: FactoryReady no recibido. Revise PrefabFactory.")
end
print("✅ ParkourSystem: Templates cargados.")

-- 2. Configuración de Niveles (Separación > 150 Studs)
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(300, 45, 0),    Name = "Nivel 1: Christmas" },
	{ Position = Vector3.new(0, 90, 300),    Name = "Nivel 2: Neon City" },
	{ Position = Vector3.new(-300, 135, 0),  Name = "Nivel 3: Toxic Waste" },
	{ Position = Vector3.new(0, 180, -300),  Name = "Nivel 4: Void" },
}

local BIOME_CONFIG = {
	[1] = { Color = Color3.fromRGB(200, 240, 255), Material = Enum.Material.Ice },
	[2] = { Color = Color3.fromRGB(255, 0, 100),   Material = Enum.Material.Neon },
	[3] = { Color = Color3.fromRGB(50, 255, 50),   Material = Enum.Material.CorrodedMetal },
	[4] = { Color = Color3.fromRGB(100, 0, 255),   Material = Enum.Material.ForceField }
}

local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 12, MaxDist = 14, Variance = 2, Time = 5 },
	[2] = { MinDist = 14, MaxDist = 16, Variance = 4, Time = 4.5 },
	[3] = { MinDist = 16, MaxDist = 18, Variance = 6, Time = 4 },
	[4] = { MinDist = 18, MaxDist = 22, Variance = 8, Time = 3.5 },
}

-- Estado del Juego
local playerPaths = {}    -- { LastBlock, AllBlocks }
local playerProgress = {} -- Nivel desbloqueado
local levelParts = {}     -- Referencias a plataformas de nivel

-- Declaraciones Forward
local spawnNextBlock, startPath, cleanupPlayerPath

--------------------------------------------------------------------------------
-- UTILIDADES VISUALES
--------------------------------------------------------------------------------

local function applyBiome(part, levelIndex)
	local config = BIOME_CONFIG[levelIndex]
	if not config then return end
	
	if part:IsA("BasePart") then
		part.Color = config.Color
		part.Material = config.Material
	end
	
	-- Recursivo para modelos
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("BasePart") and not child.Name:find("Touch") then
			child.Color = config.Color
			child.Material = config.Material
		end
	end
end

--------------------------------------------------------------------------------
-- LÓGICA CORE
--------------------------------------------------------------------------------

spawnNextBlock = function(player, levelIndex, originOverride)
	local path = playerPaths[player]
	if not path then return nil end

	local lastBlock = originOverride or path.LastBlock
	if not lastBlock then return nil end

	-- Obtener posición pivot (compatible con Modelos y Partes)
	local lastPos = (lastBlock:IsA("Model") and lastBlock:GetPivot().Position) or lastBlock.Position
	local targetPos = LEVEL_CONFIGS[levelIndex].Position
	local diff = DIFFICULTY_SETTINGS[levelIndex]

	-- Cálculos de Vector
	local vecToTarget = (targetPos - lastPos) * Vector3.new(1,0,1) -- Plano Horizontal
	local distToTarget = vecToTarget.Magnitude
	local dirToTarget = vecToTarget.Unit

	-- Determinar siguiente posición
	local jumpDist = math.random(diff.MinDist * 10, diff.MaxDist * 10) / 10
	
	-- Ajuste final si está cerca
	if distToTarget < jumpDist + 5 then
		jumpDist = distToTarget - 5 -- Aterrizaje suave antes de la plataforma
	end

	-- Varianza (Curva espiral)
	local angle = math.rad(math.random(-diff.Variance * 5, diff.Variance * 5))
	local nextDir = CFrame.Angles(0, angle, 0) * dirToTarget
	
	-- Altura (Escalera progresiva)
	local heightStep = (LEVEL_CONFIGS[levelIndex].Position.Y - lastPos.Y) / (distToTarget / jumpDist)
	heightStep = math.clamp(heightStep, 0, 4) -- Límite físico de salto Roblox

	local nextPos = lastPos + (nextDir * jumpDist) + Vector3.new(0, heightStep, 0)

	-- SPAWN
	-- Búsqueda inteligente de Prefabs por nivel
	local levelFolder = Templates:FindFirstChild("Level" .. levelIndex)
	local template = levelFolder and levelFolder:FindFirstChild("ParkourBlock")
	
	if not template then
		warn("⚠️ No se encontró ParkourBlock para Nivel " .. levelIndex .. ". Usando Fallback.")
		-- Fallback a nivel 1 o genérico si existe
		template = Templates.Level1.ParkourBlock
	end

	local block = template:Clone()
	block.Name = "Path_" .. player.Name
	block:PivotTo(CFrame.new(nextPos, nextPos + dirToTarget)) -- Mirar al objetivo
	block.Parent = Workspace
	
	applyBiome(block, levelIndex)

	-- Animación de Aparición (Pop-up)
	local targetSize = (block:IsA("Model") and block.PrimaryPart.Size) or block.Size
	if block:IsA("Model") then
		block:ScaleTo(0.1)
		local tween = TweenService:Create(block.PrimaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {Size = targetSize}) -- Nota: ScaleTo no se anima directamete, esto es simplificación.
		-- Mejor aproximación para Modelos: ScaleTo manual en loop o Tween de PrimaryPart si es simple
		block:ScaleTo(1) -- Reset para evitar complejidad ahora
	else
		block.Size = Vector3.new(0,0,0)
		TweenService:Create(block, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = targetSize}):Play()
	end

	-- Lógica de Pisado
	local touchPart = (block:IsA("Model") and block.PrimaryPart) or block
	local db = false
	
	touchPart.Touched:Connect(function(hit)
		if db then return end
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if p == player then
			db = true

			-- Efecto visual
			local sound = block:FindFirstChild("JumpSound", true)
			if sound then sound:Play() end

			-- Generar siguiente
			path.LastBlock = block
			spawnNextBlock(player, levelIndex)

			-- Destruir bloque anterior (Efecto puente cayendo)
			task.delay(0.5, function()
				if block and block.Parent then
					TweenService:Create(touchPart, TweenInfo.new(0.3), {Transparency = 1, Position = touchPart.Position - Vector3.new(0,5,0)}):Play()
					Debris:AddItem(block, 0.3)
				end
			end)
		end
	end)

	table.insert(path.AllBlocks, block)
	path.LastBlock = block

	-- Auto-destrucción por tiempo (Pressure)
	task.delay(diff.Time, function()
		if block and block.Parent then
			block:Destroy()
			-- Si era el último bloque y el jugador no saltó, se cae
		end
	end)

	return block
end

startPath = function(player, startPad, targetLevelIndex)
	cleanupPlayerPath(player)

	playerPaths[player] = {
		LastBlock = nil,
		AllBlocks = {},
		TargetLevel = targetLevelIndex
	}

	print("🚀 Iniciando camino para " .. player.Name .. " hacia Nivel " .. targetLevelIndex)
	spawnNextBlock(player, targetLevelIndex, startPad)
end

cleanupPlayerPath = function(player)
	if playerPaths[player] then
		for _, b in ipairs(playerPaths[player].AllBlocks) do
			if b then b:Destroy() end
		end
	end
	playerPaths[player] = nil
end

--------------------------------------------------------------------------------
-- GENERACIÓN DE MUNDO
--------------------------------------------------------------------------------

local function makePad(sourcePart, levelIndexForUnlock)
	local targetLevelIndex = levelIndexForUnlock + 1
	if targetLevelIndex > #LEVEL_CONFIGS then return end
	
	local levelFolder = Templates:FindFirstChild("Level" .. targetLevelIndex)
	local padTemplate = levelFolder and levelFolder:FindFirstChild("StarterPad")
	
	if not padTemplate then
		warn("❌ Falta StarterPad en Level" .. targetLevelIndex)
		return
	end

	local pad = padTemplate:Clone()
	pad.Name = "StarterPad_L" .. targetLevelIndex

	-- POSICIONAMIENTO CORREGIDO (Suprema Prompt)
	local sourcePos = (sourcePart:IsA("Model") and sourcePart:GetPivot().Position) or sourcePart.Position
	local sourceSize = (sourcePart:IsA("Model") and sourcePart:GetExtentsSize()) or sourcePart.Size

	-- En el borde mirando al objetivo
	local targetPos = LEVEL_CONFIGS[targetLevelIndex].Position
	local dir = (targetPos - sourcePos).Unit
	local offset = (sourceSize.X / 2) - 2 -- Un poco dentro del borde

	-- FÓRMULA CLAVE: Y + Size/2 + 0.5
	local finalY = sourcePos.Y + (sourceSize.Y / 2) + 0.5

	local finalPos = sourcePos + (dir * offset)
	finalPos = Vector3.new(finalPos.X, finalY, finalPos.Z)

	pad.Position = finalPos
	pad.CFrame = CFrame.lookAt(finalPos, Vector3.new(targetPos.X, finalPos.Y, targetPos.Z))
	pad.Parent = Workspace

	-- Conexión de Activación
	local db = false
	pad.Touched:Connect(function(hit)
		if db then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local pProgress = playerProgress[player] or 0
			if pProgress >= levelIndexForUnlock then
				db = true
				print("✨ Jugador " .. player.Name .. " activó StarterPad Nivel " .. targetLevelIndex)

				-- Efecto visual de activación
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.new(1,1,1)
				highlight.Parent = pad
				Debris:AddItem(highlight, 0.2)

				startPath(player, pad, targetLevelIndex)
				task.wait(1)
				db = false
			else
				-- Feedback visual de "Bloqueado" (Rojo)
				pad.Color = Color3.new(1, 0, 0)
				task.wait(0.5)
				pad.Color = Color3.fromRGB(255, 255, 0) -- Vuelta al amarillo
			end
		end
	end)
end

local function setupWorld()
	-- 1. Buscar Lobby
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if not lobby then
		warn("⚠️ Lobby no encontrado, buscando fallback...")
		lobby = Workspace:FindFirstChild("LobbyIsland") or Workspace:FindFirstChild("Baseplate")
	end
	
	if lobby then
		makePad(lobby, 0) -- Pad para Nivel 1
	end

	-- 2. Crear Plataformas de Nivel
	for i, config in ipairs(LEVEL_CONFIGS) do
		local folder = Templates:FindFirstChild("Level" .. i)
		local platTemplate = folder and folder:FindFirstChild("LevelPlatform")
		
		if platTemplate then
			local plat = platTemplate:Clone()
			plat.Position = config.Position
			plat.Parent = Workspace
			levelParts[i] = plat

			-- Pad para el SIGUIENTE nivel (si existe)
			if i < #LEVEL_CONFIGS then
				makePad(plat, i)
			end

			-- Lógica de Checkpoint/Meta
			plat.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player then
					local current = playerProgress[player] or 0
					if i > current then
						playerProgress[player] = i
						print("🏆 " .. player.Name .. " llegó al Nivel " .. i)
						
						-- Limpiar camino anterior
						cleanupPlayerPath(player)

						-- Actualizar Leaderstats
						local ls = player:FindFirstChild("leaderstats")
						if ls and ls:FindFirstChild("Stage") then
							ls.Stage.Value = i
						end
					end
				end
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- EVENTOS DE JUGADOR
--------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	playerProgress[player] = 0
	
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 0
	stage.Parent = ls
	
	player.CharacterAdded:Connect(function(char)
		-- Teleportar al último checkpoint
		task.wait(0.5) -- Esperar carga física
		local level = playerProgress[player]
		if level and level > 0 then
			local plat = levelParts[level]
			if plat then
				char:PivotTo(CFrame.new(plat.Position + Vector3.new(0, 5, 0)))
			end
		else
			-- TP al Lobby
			local lobby = Workspace:FindFirstChild("Lobby")
			if lobby then
				char:PivotTo(CFrame.new(lobby.Position + Vector3.new(0, 5, 0)))
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(cleanupPlayerPath)

-- Iniciar Sistema
task.wait(1) -- Pequeña espera para asegurar carga total
setupWorld()
