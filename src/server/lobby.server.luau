-- Lobby: Galería Lineal y Iluminación Realista (Versión Final Estable)
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Configuración de Galería
local LOBBY_WIDTH = 250
local LOBBY_DEPTH = 80
local WALL_HEIGHT = 4

-- Configuración de Gemas (Fiel a Blender)
local GEMS_SETTINGS = {
	["cilindro"]  = { Name = "Esmeralda", Color = "#22ff44", RotSpeed = 0.02 },
	["rubi"]      = { Name = "Rubi",      Color = "#ff0044", RotSpeed = 0.05 },
	["zafiro"]    = { Name = "Zafiro",    Color = "#0088ff", RotSpeed = 0.03 },
	["cuarzo"]    = { Name = "Cuarzo",    Color = "#ffffff", RotSpeed = 0.01 },
	["powerball"] = { Name = "Caos",      Color = "#aa00ff", RotSpeed = 0.02, HasShards = true }
}

-- 2. Configuración de Ambiente Nocturno VISIBLE (Estilo Videojuego)
local function setupGlobalLighting()
	print("🌕 Configurando Visibilidad Nocturna Total...")
	Lighting.ClockTime = 0 
	Lighting.Brightness = 2.0 -- Intensidad de luz de luna fuerte
	Lighting.GlobalShadows = true
	
	-- Iluminación Ambiental Alta: Esto hace que los bloques se vean con su color original
	-- sin necesidad de que emitan luz propia (Neon).
	Lighting.Ambient = Color3.fromRGB(120, 120, 140) 
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 100)
	
	local bloom = Lighting:FindFirstChildWhichIsA("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 12
	bloom.Threshold = 0.8
	bloom.Parent = Lighting

	-- Limpieza de atmósfera para máxima claridad
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end
end

-- 3. Auditoría Profunda (Whitelist)
local function auditRecursive(instance)
	-- Whitelist: No tocar gemas ni plataforma
	if instance.Name:match("HexPlatform") or instance.Name:match("_Gem") or instance.Name:match("Glow") then
		return 
	end

	-- Eliminar luces y efectos no deseados
	if instance:IsA("Light") or instance:IsA("ParticleEmitter") or instance:IsA("Beam") then
		instance:Destroy()
	end
	
	-- Neutralizar materiales
	if instance:IsA("BasePart") then
		if instance.Material == Enum.Material.Neon then
			instance.Material = Enum.Material.SmoothPlastic
		end
		instance.Reflectance = 0
		instance.CastShadow = true
	end
	
	for _, child in ipairs(instance:GetChildren()) do
		auditRecursive(child)
	end
end

-- 4. Funciones de Construcción
local function createWall(position, size, parent)
	local wall = Instance.new("Part")
	wall.Name = "LobbyWall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.BrickColor = BrickColor.new("Dark stone grey")
	wall.Material = Enum.Material.Concrete
	wall.Parent = parent
	return wall
end

local function applyGemVisuals(model, colorHex)
	local color = Color3.fromHex(colorHex)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part.Name:find("Glow") then
			part.Color = color
			part.Material = Enum.Material.Glass
			part.Transparency = 0.3
			part.Anchored = true
			part.CanCollide = false
			part.Massless = true
			
			local glow = part:Clone()
			glow.Name = "GlowCore_" .. part.Name
			glow.Size = part.Size * 0.85
			glow.Material = Enum.Material.Neon
			glow.Transparency = 0.4
			glow.Color = color
			glow.Anchored = false
			glow.Parent = part
			glow.CFrame = part.CFrame
			
			local weld = Instance.new("WeldConstraint", glow)
			weld.Part0 = part; weld.Part1 = glow
		end
	end
	
	local lightBase = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if lightBase then
		local light = Instance.new("PointLight", lightBase)
		light.Color = color
		light.Range = 25 -- Iluminación ambiental realista
		light.Brightness = 1.8
	end
end

local function createEffectInstancesLineal(startY, startZ)
	print("✨ Alineando Gemas en Galería...")
	local AssetFolder = ReplicatedStorage:WaitForChild("asset", 5)
	if not AssetFolder then return end
	local EffectsFolder = AssetFolder:WaitForChild("Effects", 5)
	if not EffectsFolder then return end
	
	local assets = EffectsFolder:GetChildren()
	local spacing = 45
	local startX = -((#assets - 1) * spacing) / 2
	
	for i, template in ipairs(assets) do
		local key = template.Name:lower()
		local config = GEMS_SETTINGS[key]
		if config then
			local pos = Vector3.new(startX + (i-1) * spacing, startY, startZ)
			local gem = template:Clone()
			gem.Name = config.Name .. "_Gem"
			if gem:IsA("Model") then gem:ScaleTo(1.8) else gem.Size *= 1.8 end
			gem:PivotTo(CFrame.new(pos))
			gem.Parent = Workspace
			applyGemVisuals(gem, config.Color)
			
			task.spawn(function()
				local startTick = tick()
				while gem and gem.Parent do
					local delta = tick() - startTick
					local float = math.sin(delta * 1.5) * 1.5
					local rot = CFrame.Angles(0, delta * config.RotSpeed * 60, 0)
					gem:PivotTo(CFrame.new(pos + Vector3.new(0, float, 0)) * rot)
					task.wait()
				end
			end)
		end
	end
end

-- 5. Creación del Lobby Lineal
local function createLinearLobby()
	setupGlobalLighting()
	
	-- Suelo
	local floor = Instance.new("Part")
	floor.Name = "LobbyFloor"
	floor.Size = Vector3.new(LOBBY_WIDTH, 2, LOBBY_DEPTH)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.SmoothPlastic
	floor.BrickColor = BrickColor.new("Dark stone grey")
	floor.Parent = Workspace

	-- Paredes
	local w2 = LOBBY_WIDTH/2; local d2 = LOBBY_DEPTH/2
	createWall(Vector3.new(0, WALL_HEIGHT/2, -d2), Vector3.new(LOBBY_WIDTH, WALL_HEIGHT, 1), floor)
	createWall(Vector3.new(0, WALL_HEIGHT/2, d2), Vector3.new(LOBBY_WIDTH, WALL_HEIGHT, 1), floor)
	createWall(Vector3.new(w2, WALL_HEIGHT/2, 0), Vector3.new(1, WALL_HEIGHT, LOBBY_DEPTH), floor)
	createWall(Vector3.new(-w2, WALL_HEIGHT/2, 0), Vector3.new(1, WALL_HEIGHT, LOBBY_DEPTH), floor)

	-- Spawn
	local spawn = Instance.new("SpawnLocation", Workspace)
	spawn.Name = "LobbySpawn"; spawn.Size = Vector3.new(1,1,1)
	spawn.Position = Vector3.new(0, 1.5, 0); spawn.Transparency = 1; spawn.Anchored = true

	-- Filas
	createEffectInstancesLineal(8, 20) -- Gemas atrás

	-- Decoraciones (Fila adelante)
	local Templates = ReplicatedStorage:WaitForChild("Templates", 5)
	if Templates then
		-- Árboles
		local tree1 = Templates:WaitForChild("MasterSakuraTree", 3)
		if tree1 then
			local t1 = tree1:Clone(); t1:PivotTo(CFrame.new(-100, 1.2, -20)); t1.Parent = floor
			local t2 = tree1:Clone(); t2:PivotTo(CFrame.new(100, 1.2, -20)); t2.Parent = floor
		end
		
		-- Plataforma
		local platform = Templates:WaitForChild("HexPlatform_V2", 3)
		if platform then
			local p = platform:Clone(); p:PivotTo(CFrame.new(50, 0.2, -20)); p.Parent = floor
		end
	end

	-- Carro
	local car = ReplicatedStorage:WaitForChild("asset"):WaitForChild("carro", 5)
	if car then
		local c = car:Clone()
		c.Name = "CarroLobby_Antigravity"
		c:PivotTo(CFrame.new(-50, 3, -20)); c.Parent = Workspace
		task.defer(function() auditRecursive(c) end)
	end

	-- Auditoría final
	task.defer(function()
		task.wait(1)
		auditRecursive(floor)
		print("✅ Galería Lineal Lista.")
	end)
end

-- 6. Océano
local function createDeadlyOcean()
	local ocean = Instance.new("Part")
	ocean.Name = "DeadlyOcean"
	ocean.Size = Vector3.new(2048, 8, 2048)
	ocean.Position = Vector3.new(0, -25, 0)
	ocean.Anchored = true; ocean.CanCollide = false
	ocean.BrickColor = BrickColor.new("Deep blue")
	ocean.Material = Enum.Material.Water; ocean.Transparency = 0.4
	ocean.Parent = Workspace
	ocean.Touched:Connect(function(hit)
		local h = hit.Parent:FindFirstChild("Humanoid")
		if h then h.Health = 0 end
	end)
end

-- Ejecución
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

createLinearLobby()
createDeadlyOcean()