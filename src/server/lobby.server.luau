-- Lobby Island and Deadly Ocean Setup Script (MEJORADO)
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuración
local LOBBY_SIZE = 80
local WALL_HEIGHT = 3

-- Función para crear una pared
local function createWall(position, size, parent)
	local wall = Instance.new("Part")
	wall.Name = "LobbyWall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.BrickColor = BrickColor.new("Dark stone grey")
	wall.Material = Enum.Material.Concrete
	wall.Transparency = 0.2
	wall.Parent = parent
end

-- Función para crear un Árbol de Cerezo (Sakura)
local function createCherryTree(position, parent)
	local Templates = ReplicatedStorage:WaitForChild("Templates")
	while not Templates:GetAttribute("SakuraReady") do task.wait(0.1) end
	local tree = Templates:WaitForChild("MasterSakuraTree"):Clone()
	
	-- Posicionamos el modelo
	tree:SetPrimaryPartCFrame(CFrame.new(position))
	tree.Parent = parent
	
	print("🌸 Árbol de cerezo profesional añadido.")
end

-- Función para crear la Plataforma Hexagonal
local function createHexPlatform(position, parent)
	local Templates = ReplicatedStorage:WaitForChild("Templates")
	while not Templates:GetAttribute("PlatformReady") do task.wait(0.1) end
	local platform = Templates:WaitForChild("HexPlatform_V2"):Clone()
	
	-- Posicionamos usando PrimaryPart (Root)
	-- Nota: El Root ya tiene offset Y=2 en el Factory, pero aquí ajustamos la posición mundo
	platform:SetPrimaryPartCFrame(CFrame.new(position))
	platform.Parent = parent
	print("💠 Plataforma Hexagonal añadida.")
end

-- Función para instanciar el Carro (depuración mejorada)
local function createCarInstance(position, parent)
	print("🔍 Buscando carpeta de assets en ReplicatedStorage...")
	local AssetFolder = ReplicatedStorage:WaitForChild("asset", 5)
	
	if not AssetFolder then
		warn("❌ ERROR: No se encontró la carpeta 'asset' en ReplicatedStorage tras 5s.")
		return
	end
	
	print("📂 Carpeta 'asset' encontrada. Buscando 'carro'...")
	local car = AssetFolder:WaitForChild("carro", 3) or AssetFolder:WaitForChild("Carro", 3)
	
	if car then
		print("📦 Objeto encontrado: " .. car.Name .. " (" .. car.ClassName .. ")")
		local carClone = car:Clone()
		carClone.Name = "CarroLobby_Antigravity"
		
		-- Elevamos la posición a Y=3 para que esté claramente encima del suelo (Y=1)
		carClone:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
		
		carClone.Parent = Workspace
		print("✅ Carro (.rbxm) instanciado con éxito en el Workspace.")
	else
		warn("⚠️ No se encontró el objeto 'carro' dentro de la carpeta 'asset'.")
	end
end

-- === CONFIGURACIÓN DE GEMAS (Fiel a Blender Script) ===
local GEMS_SETTINGS = {
	["cilindro"]  = { Name = "Esmeralda", Color = "#22ff44", RotSpeed = 0.02 },
	["rubi"]      = { Name = "Rubi",      Color = "#ff0044", RotSpeed = 0.05 },
	["zafiro"]    = { Name = "Zafiro",    Color = "#0088ff", RotSpeed = 0.03 },
	["cuarzo"]    = { Name = "Cuarzo",    Color = "#ffffff", RotSpeed = 0.01 },
	["powerball"] = { Name = "Caos",      Color = "#aa00ff", RotSpeed = 0.02, HasShards = true }
}

-- Función auxiliar para aplicar visuales y física estable (Efecto Cristal con Brillo Visible)
local function applyGemVisuals(model, colorHex)
	local color = Color3.fromHex(colorHex)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part.Name:find("Glow") then
			-- Carcasa de Cristal
			part.Color = color
			part.Material = Enum.Material.Glass
			part.Transparency = 0.3
			part.CastShadow = false
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = true
			
			-- NÚCLEO DE BRILLO (Más visible ahora)
			local glow = part:Clone()
			glow.Name = "GlowCore_" .. part.Name
			glow.Size = part.Size * 0.9 -- Ligeramente más pequeño
			glow.Material = Enum.Material.Neon
			glow.Transparency = 0.4 -- Reducido de 0.8 a 0.4 para mayor visibilidad
			glow.Color = color
			glow.Anchored = false
			glow.Parent = part
			glow.CFrame = part.CFrame
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = part
			weld.Part1 = glow
			weld.Parent = glow
		end
	end
	
	-- Luz interna (Brillo Incrementado)
	local lightBase = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if lightBase then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 8 -- Rango aumentado de 6 a 8
		light.Brightness = 1.0 -- Aumentado de 0.3 a 1.0 para emisión real
		light.Parent = lightBase
	end
end

-- Función para crear fragmentos orbitantes (Cristal con Brillo Visible)
local function createChaosShards(centerPart, colorHex)
	local color = Color3.fromHex(colorHex)
	local shards = {}
	for i = 1, 8 do
		local shard = Instance.new("Part")
		shard.Name = "ShardShell_" .. i
		shard.Size = Vector3.new(0.5, 0.5, 0.5)
		shard.Color = color
		shard.Material = Enum.Material.Glass
		shard.Transparency = 0.3
		shard.Anchored = true
		shard.CanCollide = false
		shard.Parent = centerPart.Parent
		
		-- Núcleo de brillo para el shard (Más visible)
		local glow = shard:Clone()
		glow.Name = "ShardGlow_" .. i
		glow.Size = shard.Size * 0.8
		glow.Material = Enum.Material.Neon
		glow.Transparency = 0.4 -- Reducido de 0.8 a 0.4
		glow.Anchored = false
		glow.Parent = shard
		glow.CFrame = shard.CFrame
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = shard
		weld.Part1 = glow
		weld.Parent = glow

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere 
		mesh.Scale = Vector3.new(0.5, 1, 0.5)
		mesh.Parent = shard
		
		table.insert(shards, {Part = shard, AngleOffset = (i / 8) * math.pi * 2})
	end
	return shards
end

-- Función para instanciar y animar Efectos (Escala Reducida)
local function createEffectInstances(centerPosition, lobbyIsland)
	print("✨ Refinando Brillo y Órbita del Caos...")
	local AssetFolder = ReplicatedStorage:WaitForChild("asset", 5)
	if not AssetFolder then return end

	local EffectsFolder = AssetFolder:FindFirstChild("Effects")
	if not EffectsFolder then return end

	local effectsAssets = EffectsFolder:GetChildren()
	local radius = 30
	local scaleFactor = 1.8 
	
	for i, template in ipairs(effectsAssets) do
		local key = template.Name:lower()
		local config = GEMS_SETTINGS[key]
		
		if config and (template:IsA("Model") or template:IsA("BasePart")) then
			local angle = (i-1) * (math.pi * 2 / #effectsAssets)
			local basePos = centerPosition + Vector3.new(math.cos(angle) * radius, 8, math.sin(angle) * radius)
			
			local gemClone = template:Clone()
			gemClone.Name = config.Name .. "_Gem"
			
			if gemClone:IsA("Model") then gemClone:ScaleTo(scaleFactor)
			else gemClone.Size = gemClone.Size * scaleFactor end
			
			gemClone:PivotTo(CFrame.new(basePos))
			gemClone.Parent = Workspace
			
			applyGemVisuals(gemClone, config.Color)
			
			local initialCFrame = gemClone:GetPivot()
			local initialRotation = initialCFrame.Rotation
			
			-- Animación según script de Blender (Ajustada a mitad de velocidad)
			task.spawn(function()
				local startTick = tick()
				local animSpeed = 0.5 
				local rotSpeedSec = config.RotSpeed * 60 * animSpeed
				
				-- Preparar componentes para Powerball
				local isChaos = config.HasShards
				local chaosComponents = {}
				local mainPart = gemClone.PrimaryPart or gemClone:FindFirstChildWhichIsA("BasePart")
				
				if isChaos and gemClone:IsA("Model") then
					for _, p in ipairs(gemClone:GetDescendants()) do
						if p:IsA("BasePart") and not p.Name:find("Glow") then
							local name = p.Name:lower()
							if name:find("core") or name:find("ball") or name:find("sphere") then
								mainPart = p
								break
							end
							if not mainPart or p.Size.Magnitude > mainPart.Size.Magnitude then
								mainPart = p
							end
						end
					end
					
					for _, p in ipairs(gemClone:GetDescendants()) do
						if p:IsA("BasePart") and p ~= mainPart and not p.Name:find("Glow") then
							table.insert(chaosComponents, {
								Part = p,
								InitialRot = p.CFrame.Rotation,
								AngleOffset = math.atan2(p.Position.Z - mainPart.Position.Z, p.Position.X - mainPart.Position.X)
							})
							p.Anchored = true 
						end
					end
				end

				-- Fragmentos extra procedimentales
				local proceduralShards = nil
				if isChaos and #chaosComponents == 0 then
					if mainPart then proceduralShards = createChaosShards(mainPart, config.Color) end
				end
				
				while gemClone and gemClone.Parent do
					local deltaT = (tick() - startTick)
					local t = deltaT * 1.5 -- Velocidad base a la mitad
					
					-- 1. Movimiento del Núcleo / Bola Principal
					local floatY = math.sin(t * 1.5) * 1.5
					local spin = CFrame.Angles(0, deltaT * rotSpeedSec, 0)
					local currentPos = basePos + Vector3.new(0, floatY, 0)
					
					if mainPart then
						mainPart.CFrame = CFrame.new(currentPos) * spin * initialRotation
					end
					
					-- 2. Movimiento de Componentes Internos (Órbita Lenta)
					local gemCenter = currentPos
					
					-- Usamos una velocidad orbital MENOR (t * 0.5 en lugar de t * 1.5)
					local orbitT = t * 0.5 

					for i, comp in ipairs(chaosComponents) do
						local sAngle = orbitT + comp.AngleOffset
						local orbitRad = 8 
						local offX = math.cos(sAngle) * orbitRad
						local offZ = math.sin(sAngle) * orbitRad
						local offY = math.sin(t * 2 + comp.AngleOffset) * 2
						
						local tumble = deltaT * 0.05 * 60 * animSpeed
						comp.Part.CFrame = CFrame.new(gemCenter + Vector3.new(offX, offY, offZ)) 
							* CFrame.Angles(tumble, tumble, 0) * comp.InitialRot
					end
					
					if proceduralShards then
						for _, sData in ipairs(proceduralShards) do
							local sAngle = orbitT + sData.AngleOffset
							local orbitRad = 8
							local offX = math.cos(sAngle) * orbitRad
							local offZ = math.sin(sAngle) * orbitRad
							local offY = math.sin(t * 2 + sData.AngleOffset) * 2
							
							local tumble = deltaT * 0.05 * 60 * animSpeed
							sData.Part.CFrame = CFrame.new(gemCenter + Vector3.new(offX, offY, offZ)) 
								* CFrame.Angles(tumble, tumble, 0)
						end
					end
					
					task.wait()
				end
				
				if proceduralShards then for _, s in ipairs(proceduralShards) do s.Part:Destroy() end end
			end)
			
			print("💎 Gema " .. config.Name .. " restaurada (Look Blender).")
		end
	end
end

-- Función para auditar y limpiar materiales/luces (Solo Gemas y Plataforma emiten luz)
local function auditLobbyAsset(instance)
	for _, desc in ipairs(instance:GetDescendants()) do
		-- 1. Eliminar luces perdidas
		if desc:IsA("Light") then
			desc:Destroy()
		end
		
		-- 2. Forzar materiales no emisores
		if desc:IsA("BasePart") then
			if desc.Material == Enum.Material.Neon then
				desc.Material = Enum.Material.SmoothPlastic
			end
			-- Opcional: Asegurar que no haya Reflectance excesivo que simule emisión
			if desc.Reflectance > 0.5 then
				desc.Reflectance = 0.1
			end
		end
	end
end

-- Función para crear el Lobby con seguridad (Auditoría de Iluminación Aplicada)
local function createLobbyIsland()
	print("🛡️ Iniciando Auditoría de Iluminación del Lobby...")
	-- 1. Crear el suelo de la isla
	local lobbyIsland = Instance.new("Part")
	lobbyIsland.Name = "Lobby"
	lobbyIsland.Size = Vector3.new(LOBBY_SIZE, 2, LOBBY_SIZE)
	lobbyIsland.Position = Vector3.new(0, 0, 0)
	lobbyIsland.Anchored = true
	lobbyIsland.BrickColor = BrickColor.new("Dark stone grey")
	lobbyIsland.Material = Enum.Material.SmoothPlastic
	lobbyIsland.Parent = Workspace

	-- 2. Crear paredes
	local halfSize = LOBBY_SIZE / 2
	local wallThick = 1
	createWall(Vector3.new(0, WALL_HEIGHT/2, -halfSize), Vector3.new(LOBBY_SIZE, WALL_HEIGHT, wallThick), lobbyIsland)
	createWall(Vector3.new(0, WALL_HEIGHT/2, halfSize), Vector3.new(LOBBY_SIZE, WALL_HEIGHT, wallThick), lobbyIsland)
	createWall(Vector3.new(halfSize, WALL_HEIGHT/2, 0), Vector3.new(wallThick, WALL_HEIGHT, LOBBY_SIZE), lobbyIsland)
	createWall(Vector3.new(-halfSize, WALL_HEIGHT/2, 0), Vector3.new(wallThick, WALL_HEIGHT, LOBBY_SIZE), lobbyIsland)

	-- 3. SpawnLocation
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(1, 1, 1)
	spawnLocation.Position = Vector3.new(0, 1.5, 0)
	spawnLocation.Anchored = true
	spawnLocation.Transparency = 1 
	spawnLocation.Parent = Workspace
	
	-- 4. Decoración y Assets (Con Auditoría Individual)
	local tree1Pos = Vector3.new(20, 1.2, 20)
	createCherryTree(tree1Pos, lobbyIsland)
	
	local tree2Pos = Vector3.new(-20, 1.2, -20)
	createCherryTree(tree2Pos, lobbyIsland)
	
	-- Auditamos árboles tras crearlos
	for _, item in ipairs(lobbyIsland:GetChildren()) do
		if item.Name == "MasterSakuraTree" then auditLobbyAsset(item) end
	end

	-- Plataforma Hexagonal (EXCEPCIÓN: Sí emite luz)
	createHexPlatform(Vector3.new(-15, 0.2, 15), lobbyIsland) 
	
	-- Carro (Auditoría aplicada tras instanciar)
	createCarInstance(Vector3.new(10, 0.2, -10), lobbyIsland)
	task.defer(function()
		local car = Workspace:FindFirstChild("CarroLobby_Antigravity")
		if car then auditLobbyAsset(car) end
	end)

	-- 5. Efectos 3D Animados (EXCEPCIÓN: Son la fuente principal de luz)
	createEffectInstances(Vector3.new(0, 0, 0), lobbyIsland)

	print("✅ Lobby Island consolidado. Solo Gemas y Plataforma emiten luz.")
end

-- Función para crear el Océano Mortal
local function createDeadlyOcean()
	local deadlyOcean = Instance.new("Part")
	deadlyOcean.Name = "DeadlyOcean"
	deadlyOcean.Size = Vector3.new(2048, 8, 2048) -- Un poco más grueso
	deadlyOcean.Position = Vector3.new(0, -25, 0) -- Más abajo para dar espacio de caída
	deadlyOcean.Anchored = true
	deadlyOcean.CanCollide = false
	deadlyOcean.BrickColor = BrickColor.new("Deep blue")
	deadlyOcean.Material = Enum.Material.Water
	deadlyOcean.Transparency = 0.4
	deadlyOcean.Reflectance = 0.3 -- Un poco de brillo
	deadlyOcean.Parent = Workspace

	-- Lógica de muerte DIRECTA (sin crear otro script)
	deadlyOcean.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		
		if humanoid and humanoid.Health > 0 then
			print("🌊 Jugador cayó al agua: " .. character.Name)
			
			-- Splash Sound
			local splash = Instance.new("Sound", hit)
			splash.SoundId = "rbxassetid://5930519356" -- High Quality Water Splash
			splash.Volume = 0.8
			splash.PlayOnRemove = true
			splash:Play()
			splash:Destroy()

			humanoid.Health = 0 -- Muerte instantánea
		end
	end)

	print("✅ Océano Mortal activado.")
end

local function cleanupBaseplate()
	-- 1. Eliminar Baseplate original
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("🗑️ Baseplate eliminado.")
	end

	-- 2. Eliminar Spawns por defecto para evitar duplicados
	for _, item in ipairs(Workspace:GetChildren()) do
		if item:IsA("SpawnLocation") and item.Name ~= "LobbySpawn" then
			item:Destroy()
			print("🗑️ Spawn por defecto '" .. item.Name .. "' eliminado.")
		end
	end
end

-- Ejecución principal
local function setupGameEnvironment()
	print("🛠️ Iniciando configuración del entorno...")
	
	cleanupBaseplate()
	createLobbyIsland()
	createDeadlyOcean()
	
	-- Ajuste de Iluminación (Tokyo Style - Anti-Glare Standardized)
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.OutdoorAmbient = Color3.fromHex("#FFE4E1") -- Tinte rosa amanecer
	Lighting.GlobalShadows = true
	Lighting.Brightness = 1.5 -- Reduced from 2.5
	
	-- Bloom para "brillo" suave
	local bloom = Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.1 -- Reduced from 0.2
	bloom.Threshold = 0.8 -- Adjusted from 0.95
	bloom.Size = 24 -- Soft halo
	
	print("✨ Entorno listo (Estilo Tokyo). ¡A saltar!")
end

setupGameEnvironment()