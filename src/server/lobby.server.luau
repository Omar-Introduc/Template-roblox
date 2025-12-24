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

-- Función auxiliar para aplicar visuales y física estable
local function applyGemVisuals(model, colorHex)
	local color = Color3.fromHex(colorHex)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = color
			part.Material = Enum.Material.Neon
			part.CastShadow = false
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	
	-- Luz interna
	local lightBase = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if lightBase then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10
		light.Brightness = 1.2
		light.Parent = lightBase
	end
end

-- Función para crear fragmentos orbitantes (Caos Shards)
local function createChaosShards(centerPart, colorHex)
	local color = Color3.fromHex(colorHex)
	local shards = {}
	for i = 1, 8 do
		local shard = Instance.new("Part")
		shard.Name = "Shard_" .. i
		shard.Size = Vector3.new(0.5, 0.5, 0.5)
		shard.Color = color
		shard.Material = Enum.Material.Neon
		shard.Anchored = true
		shard.CanCollide = false
		shard.Parent = centerPart.Parent
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere 
		mesh.Scale = Vector3.new(0.5, 1, 0.5)
		mesh.Parent = shard
		
		table.insert(shards, {Part = shard, AngleOffset = (i / 8) * math.pi * 2})
	end
	return shards
end

-- Función para instanciar y animar Efectos (Implementación Principal Restaurada)
local function createEffectInstances(centerPosition, lobbyIsland)
	print("✨ Restaurando Lógica Principal de Blender...")
	local AssetFolder = ReplicatedStorage:WaitForChild("asset", 5)
	if not AssetFolder then return end

	local EffectsFolder = AssetFolder:FindFirstChild("Effects")
	if not EffectsFolder then return end

	local effectsAssets = EffectsFolder:GetChildren()
	local radius = 30
	local scaleFactor = 3.5
	
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
			
			-- Animación según script de Blender
			task.spawn(function()
				local startTick = tick()
				-- Blender's frame-based speed to rad/sec conversion
				-- rot_speed in blender is per frame. Frames/sec = 60.
				local rotSpeedSec = config.RotSpeed * 60 
				
				local shards = nil
				if config.HasShards then
					local core = gemClone.PrimaryPart or gemClone:FindFirstChildWhichIsA("BasePart")
					if core then shards = createChaosShards(core, config.Color) end
				end
				
				while gemClone and gemClone.Parent do
					local deltaT = tick() - startTick
					-- t = frame / 20. At 60fps, 1 sec = 60 frames. So frame = deltaT * 60.
					-- t = (deltaT * 60) / 20 = deltaT * 3.
					local t = deltaT * 3.0
					
					-- 1. Flotación (Blender: += sin(t*1.5)*0.005)
					-- To avoid cumulative error and match Roblox feel, we use absolute sine:
					local floatY = math.sin(t * 1.5) * 1.5
					
					-- 2. Rotación Y (Blender: rotation_euler.z += rot_speed)
					local currentRotY = deltaT * rotSpeedSec
					local spin = CFrame.Angles(0, currentRotY, 0)
					
					gemClone:PivotTo(CFrame.new(basePos + Vector3.new(0, floatY, 0)) * spin * initialRotation)
					
					-- 3. Fragmentos del Caos
					if shards then
						for _, sData in ipairs(shards) do
							-- Blender Shard Orbit Logic:
							local shardAngle = t * 1.5 + sData.AngleOffset
							local orbitRad = 8 -- Blender 1.8 * scaleFactor (~3.5) = 6.3. Using 8 for visual spacing.
							
							local offX = math.cos(shardAngle) * orbitRad
							local offZ = math.sin(shardAngle) * orbitRad
							local offY = math.sin(t * 2 + sData.AngleOffset) * 2 -- Blender 0.4 * scaleFactor = 1.4
							
							local gemCenter = gemClone:GetPivot().Position
							
							-- Tumbling (Blender: rotation_euler += 0.05 per frame)
							local tumble = deltaT * 0.05 * 60
							sData.Part.CFrame = CFrame.new(gemCenter + Vector3.new(offX, offY, offZ)) 
								* CFrame.Angles(tumble, tumble, 0)
						end
					end
					
					task.wait()
				end
				
				if shards then for _, s in ipairs(shards) do s.Part:Destroy() end end
			end)
			
			print("💎 Gema " .. config.Name .. " restaurada (Look Blender).")
		end
	end
end

-- Función para crear el Lobby con seguridad
local function createLobbyIsland()
	-- 1. Crear el suelo de la isla
	local lobbyIsland = Instance.new("Part")
	lobbyIsland.Name = "Lobby"
	lobbyIsland.Size = Vector3.new(LOBBY_SIZE, 2, LOBBY_SIZE)
	lobbyIsland.Position = Vector3.new(0, 0, 0) -- Top surface at Y=1 (thickness 2)
	lobbyIsland.Anchored = true
	lobbyIsland.BrickColor = BrickColor.new("Dark stone grey")
	lobbyIsland.Material = Enum.Material.SmoothPlastic
	lobbyIsland.Parent = Workspace

	-- 2. Crear paredes alrededor (para que sea seguro)
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
	
	print("🎯 Spawn del Lobby arreglado definitivamente.")

	-- 4. Decoración y Assets
	createCherryTree(Vector3.new(20, 1.2, 20), lobbyIsland)
	createCherryTree(Vector3.new(-20, 1.2, -20), lobbyIsland)
	createHexPlatform(Vector3.new(-15, 0.2, 15), lobbyIsland) 
	
	-- 5. Añadir Carro (Punto principal)
	createCarInstance(Vector3.new(10, 0.2, -10), lobbyIsland)

	-- 6. Añadir Efectos 3D Animados (Cilindro, Rubi, Zafiro, etc.)
	createEffectInstances(Vector3.new(0, 0, 0), lobbyIsland)

	print("✅ Lobby Island completo con Efectos Animados.")
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