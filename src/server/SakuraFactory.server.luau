-- SakuraFactory.server.luau (Con Escala Ajustada para Roblox)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- === CONFIGURACIÓN DE ESCALA ===
-- Factor de multiplicación para adaptar Three.js a Roblox.
-- Three.js (1 unidad) -> Roblox (1 stud) es muy pequeño para un jugador de 5 studs.
-- 2.5x hace que el tronco mida 10 studs de alto (el doble de un jugador), perfecto para caminar debajo.
local GLOBAL_SCALE = 2.5 

-- 1. COLORES
local COLORS = {
	Wood = Color3.fromHex("#8B4513"),
	DarkWood = Color3.fromHex("#5D4037"),
	Sakura1 = Color3.fromHex("#FFB7C5"),
	Sakura2 = Color3.fromHex("#FF69B4"),
	Sakura3 = Color3.fromHex("#FFC0CB"),
	Grass = Color3.fromHex("#4CAF50"),
	Stone = Color3.fromHex("#808080")
}

-- 2. HELPER CON ESCALA APLICADA
local function createBox(name, size, pos, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	-- APLICAMOS LA ESCALA AL TAMAÑO
	part.Size = size * GLOBAL_SCALE
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	
	-- CFrame con POSICIÓN ESCALADA
	-- Multiplicamos el offset (pos) por la escala para mantener la distancia proporcional entre piezas
	if parent:IsA("BasePart") then
		part.CFrame = parent.CFrame * CFrame.new(pos * GLOBAL_SCALE)
	else
		part.CFrame = CFrame.new(pos * GLOBAL_SCALE)
	end
	
	part.Parent = parent
	return part
end

local function createMasterSakuraTree(templates)
	print("🌸 SakuraFactory: Construyendo Sakura Voxel (Escala x" .. GLOBAL_SCALE .. ")...")
	
	local model = Instance.new("Model")
	model.Name = "MasterSakuraTree"

	-- Raíz
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1) * GLOBAL_SCALE
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	-- Elevamos el centro basándonos en la escala
	root.CFrame = CFrame.new(0, 5 * GLOBAL_SCALE, 0)
	root.Parent = model
	model.PrimaryPart = root

	-- === 1. SUELO JARDÍN ZEN ===
	-- React: groundGroup.position.y = -5
	local groundCenter = CFrame.new(0, -5 * GLOBAL_SCALE, 0)

	-- Base de pasto
	local grass = createBox("GrassBase", Vector3.new(16, 1, 16), Vector3.new(0,0,0), COLORS.Grass, model)
	grass.CFrame = root.CFrame * groundCenter -- Centrado en el suelo
	
	-- CAMBIO CLAVE: PrimaryPart ahora es la Base (Pasto) para facilitar posicionamiento en el Lobby
	-- Así, al ponerlo en Y, se coloca la base, no el tronco medio.
	model.PrimaryPart = grass

	-- Piedras
	local rng = Random.new(12345)
	for i = 1, 6 do
		local x = (rng:NextNumber() - 0.5) * 10
		local z = (rng:NextNumber() - 0.5) * 10
		local stone = createBox("Stone", Vector3.new(1.5, 1.1, 1.5), Vector3.new(0,0,0), COLORS.Stone, model)
		-- Aplicamos escala a las coordenadas X, Z
		stone.CFrame = root.CFrame * groundCenter * CFrame.new(x * GLOBAL_SCALE, 0, z * GLOBAL_SCALE)
	end

	-- === 2. TRONCO ===
	-- Nota: CFrame.new(x, y, z) DEBE ser escalado.
	-- Nota: CFrame.Angles(...) NO se escala (los ángulos son los mismos sin importar el tamaño).

	-- Segmento 1
	local t1 = createBox("Trunk1", Vector3.new(2, 4, 2), Vector3.new(0,0,0), COLORS.Wood, model)
	t1.CFrame = root.CFrame * CFrame.new(0, -2 * GLOBAL_SCALE, 0)

	-- Segmento 2
	local t2 = createBox("Trunk2", Vector3.new(1.8, 3, 1.8), Vector3.new(0,0,0), COLORS.Wood, model)
	t2.CFrame = root.CFrame * CFrame.new(0.2 * GLOBAL_SCALE, 1 * GLOBAL_SCALE, 0.2 * GLOBAL_SCALE) * CFrame.Angles(0, 0, -0.1)

	-- Segmento 3
	local t3 = createBox("Trunk3", Vector3.new(1.5, 3, 1.5), Vector3.new(0,0,0), COLORS.Wood, model)
	t3.CFrame = root.CFrame * CFrame.new(0.5 * GLOBAL_SCALE, 3.5 * GLOBAL_SCALE, 0.5 * GLOBAL_SCALE) * CFrame.Angles(0, 0, -0.2)

	-- === 3. RAMAS ===
	
	-- Rama Izquierda
	local bL = createBox("BranchL", Vector3.new(1, 4, 1), Vector3.new(0,0,0), COLORS.Wood, model)
	bL.CFrame = root.CFrame 
		* CFrame.new(0, 2 * GLOBAL_SCALE, 0) -- Posición Grupo
		* CFrame.new(-2 * GLOBAL_SCALE, 1 * GLOBAL_SCALE, 0) -- Posición Caja
		* CFrame.Angles(0, 0, 0.8)

	-- Rama Derecha - Sub 1
	local bR1 = createBox("BranchR1", Vector3.new(0.8, 3.5, 0.8), Vector3.new(0,0,0), COLORS.Wood, model)
	bR1.CFrame = root.CFrame 
		* CFrame.new(0, 3 * GLOBAL_SCALE, 0) 
		* CFrame.new(2 * GLOBAL_SCALE, 1 * GLOBAL_SCALE, 0.5 * GLOBAL_SCALE) 
		* CFrame.Angles(0, 0, -0.6)

	-- Rama Derecha - Sub 2
	local bR2 = createBox("BranchR2", Vector3.new(0.8, 3.5, 0.8), Vector3.new(0,0,0), COLORS.Wood, model)
	bR2.CFrame = root.CFrame 
		* CFrame.new(0, 3 * GLOBAL_SCALE, 0) 
		* CFrame.new(1 * GLOBAL_SCALE, 1 * GLOBAL_SCALE, -1.5 * GLOBAL_SCALE) 
		* CFrame.Angles(-0.6, 0, 0)

	-- === 4. FOLLAJE ===
	
	local function createCluster(x, y, z, s, color)
		-- Escalamos posiciones y tamaños
		local main = createBox("ClusterMain", Vector3.new(s, s*0.8, s), Vector3.new(0,0,0), color, model)
		main.CFrame = root.CFrame * CFrame.new(x * GLOBAL_SCALE, y * GLOBAL_SCALE, z * GLOBAL_SCALE)
		
		local d1 = createBox("ClusterD1", Vector3.new(s*0.6, s*0.4, s*0.6), Vector3.new(0,0,0), color, model)
		d1.CFrame = root.CFrame * CFrame.new((x + s*0.4) * GLOBAL_SCALE, (y + s*0.3) * GLOBAL_SCALE, (z + s*0.4) * GLOBAL_SCALE)
		
		local d2 = createBox("ClusterD2", Vector3.new(s*0.5, s*0.5, s*0.5), Vector3.new(0,0,0), color, model)
		d2.CFrame = root.CFrame * CFrame.new((x - s*0.3) * GLOBAL_SCALE, (y - s*0.2) * GLOBAL_SCALE, (z - s*0.3) * GLOBAL_SCALE)
	end

	-- Distribución (Valores originales de React, la función createCluster aplica el SCALE)
	-- Copa Central
	createCluster(0, 6, 0, 3.5, COLORS.Sakura1)
	createCluster(1, 7, 1, 2.5, COLORS.Sakura2)
	createCluster(-1, 6.5, -1, 3, COLORS.Sakura3)

	-- Lado Izquierdo
	createCluster(-3.5, 4.5, 0, 2.8, COLORS.Sakura2)
	createCluster(-4.5, 5.5, 1, 2, COLORS.Sakura1)
	createCluster(-2.5, 3.5, -1.5, 2.2, COLORS.Sakura3)

	-- Lado Derecho
	createCluster(3.5, 5, 0.5, 3, COLORS.Sakura1)
	createCluster(4.5, 4, -1, 2.2, COLORS.Sakura3)
	createCluster(2.5, 6, 2, 2.5, COLORS.Sakura2)

	-- Frente y Fondo
	createCluster(0, 5, 3, 2.5, COLORS.Sakura2)
	createCluster(0.5, 5.5, -3, 2.8, COLORS.Sakura1)

	-- === 5. PÉTALOS (Ajustados a la escala) ===
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "PetalEmitter"
	-- Área de emisión más grande por la escala
	emitterPart.Size = Vector3.new(15, 1, 15) * GLOBAL_SCALE 
	emitterPart.Transparency = 1
	emitterPart.CanCollide = false
	emitterPart.Anchored = true
	emitterPart.CFrame = root.CFrame * CFrame.new(0, 10 * GLOBAL_SCALE, 0)
	emitterPart.Parent = model

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "SakuraRain"
	particles.Texture = "rbxassetid://15444645258"
	particles.Color = ColorSequence.new(COLORS.Sakura3)
	-- Pétalos más grandes para que se vean bien con el árbol gigante
	particles.Size = NumberSequence.new(0.15 * GLOBAL_SCALE, 0) 
	particles.Lifetime = NumberRange.new(8, 12)
	particles.Rate = 10 * (GLOBAL_SCALE * 0.5) -- Más área = un poco más de tasa
	particles.Speed = NumberRange.new(2 * GLOBAL_SCALE, 4 * GLOBAL_SCALE) -- Caen más rápido relativo al tamaño
	particles.EmissionDirection = Enum.NormalId.Bottom
	particles.SpreadAngle = Vector2.new(0, 0)
	particles.Acceleration = Vector3.new(0.5, -0.5, 0.5) * GLOBAL_SCALE -- Viento escalado
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-50, 50)
	particles.Parent = emitterPart

	-- Limpieza
	if templates:FindFirstChild("MasterSakuraTree") then
		templates.MasterSakuraTree:Destroy()
	end
	
	model.Parent = templates
	templates:SetAttribute("SakuraReady", true)
	print("✅ SakuraFactory: Voxel Sakura Tree (Escalado) creado en Templates.")
end

local templates = ReplicatedStorage:WaitForChild("Templates", 10)
if templates then
	createMasterSakuraTree(templates)
end
