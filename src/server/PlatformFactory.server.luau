-- PlatformFactory.server.luau (Hex Tile V.2 Solid Port)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === CONFIGURACIÓN DE ESCALA ===
-- Mantenemos la escala del Sakura (2.5) para que el jugador quepa bien en la plataforma.
local GLOBAL_SCALE = 2.5 

-- 1. COLORES (Extraídos de tu código React)
local COLORS = {
	Base = Color3.fromHex("#556066"),   -- Gris Oscuro (Cuerpo)
	Bevel = Color3.fromHex("#BDC3C7"),  -- Gris Claro (Borde/Bisel)
	Top = Color3.fromHex("#7F8C8D"),    -- Gris Medio (Superficie)
	Detail = Color3.fromHex("#444444")  -- Piedritas
}

-- 2. HELPER PARA CILINDROS (Equivalente a CylinderGeometry)
local function createCylinder(name, radius, height, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	-- En Roblox, el cilindro se define por su eje X (largo) y diámetro en Y/Z.
	-- CylinderGeometry(radius...) -> Roblox Size(height, radius*2, radius*2)
	-- Nota: El cilindro de Roblox "se acuesta" en X, así que lo rotaremos.
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height * GLOBAL_SCALE, radius * 2 * GLOBAL_SCALE, radius * 2 * GLOBAL_SCALE)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic -- Look "Solid/Matte"
	part.Anchored = true
	part.CanCollide = true
	part.CastShadow = true
	
	-- Superficies lisas
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	
	part.Parent = parent
	return part
end

local function createHexPlatform(templates)
	print("💠 PlatformFactory: Construyendo Hex Tile V.2 (Escala x" .. GLOBAL_SCALE .. ")...")
	
	local model = Instance.new("Model")
	model.Name = "HexPlatform_V2"

	-- Parte Raíz (Invisible) para posicionamiento
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(0, 5, 0)
	root.Parent = model
	model.PrimaryPart = root

	-- Dimensiones Originales (React)
	local radius = 3.5
	local height = 1.2
	local bevelSize = 0.3
	local bevelTopRadius = radius - 0.4 -- 3.1

	-- === A. CUERPO BASE (BaseMesh) ===
	-- React: position.y = height / 2
	local basePart = createCylinder("BaseBody", radius, height, COLORS.Base, model)
	-- Rotamos 90 grados en Z para que el cilindro quede vertical
	basePart.CFrame = root.CFrame * CFrame.new(0, (height / 2) * GLOBAL_SCALE, 0) * CFrame.Angles(0, 0, math.rad(90))

	-- === B. BISEL SUPERIOR (BevelMesh) ===
	-- React: CylinderGeometry(bevelTopRadius, radius, bevelSize...)
	-- En Roblox no tenemos cilindros cónicos (truncados). 
	-- Simulamos el bisel usando un cilindro con el radio PROMEDIO o el SUPERIOR.
	-- Usaremos el radio superior para que se vea el "escalón" con la base.
	local avgRadius = (radius + bevelTopRadius) / 2
	local bevelPart = createCylinder("BevelRim", avgRadius, bevelSize, COLORS.Bevel, model)
	
	-- React: position.y = height + (bevelSize / 2)
	local bevelY = height + (bevelSize / 2)
	bevelPart.CFrame = root.CFrame * CFrame.new(0, bevelY * GLOBAL_SCALE, 0) * CFrame.Angles(0, 0, math.rad(90))

	-- === C. TAPA SUPERIOR (TopMesh) ===
	-- React: height = 0.1, radius = bevelTopRadius
	local topHeight = 0.1
	local topPart = createCylinder("TopSurface", bevelTopRadius, topHeight, COLORS.Top, model)
	
	-- React: position.y = height + bevelSize (apilado encima)
	-- Ajustamos un poco para evitar Z-fighting (parpadeo)
	local topY = height + bevelSize + (topHeight / 2)
	topPart.CFrame = root.CFrame * CFrame.new(0, topY * GLOBAL_SCALE, 0) * CFrame.Angles(0, 0, math.rad(90))

	-- === D. DETALLES (Piedritas) ===
	-- React: DodecahedronGeometry(0.15) -> Roblox Block aleatorio
	local rng = Random.new(999)
	for i = 1, 5 do
		local detail = Instance.new("Part")
		detail.Name = "Pebble"
		detail.Material = Enum.Material.SmoothPlastic
		detail.Color = COLORS.Detail
		-- Tamaño pequeño escalado
		local s = 0.25 * GLOBAL_SCALE -- Un poco más grande que 0.15 para que se note en Roblox
		detail.Size = Vector3.new(s, s, s) 
		detail.Anchored = true
		detail.CanCollide = false
		detail.CastShadow = true
		
		-- Posición Circular Aleatoria
		local angle = rng:NextNumber() * math.pi * 2
		local r = rng:NextNumber() * (bevelTopRadius - 0.5) * GLOBAL_SCALE
		
		local x = math.cos(angle) * r
		local z = math.sin(angle) * r
		local y = (height + bevelSize + 0.1) * GLOBAL_SCALE -- Apenas sobresaliendo
		
		detail.CFrame = root.CFrame * CFrame.new(x, y, z) * CFrame.Angles(rng:NextNumber(), rng:NextNumber(), rng:NextNumber())
		detail.Parent = model
	end
	
	-- === ILUMINACIÓN DE BORDE (Rim Light Simulado) ===
	-- Tu código React tenía una 'SpotLight' azulada (-5, 0, -5).
	-- En Roblox, podemos poner una PointLight suave dentro del Bisel para que emita ese brillo tenue.
	local rimLight = Instance.new("PointLight")
	rimLight.Color = Color3.fromHex("#aab7b8") -- Color del RimLight de React
	rimLight.Range = 8 * GLOBAL_SCALE
	rimLight.Brightness = 0.5
	rimLight.Parent = bevelPart -- Hija del borde claro

	-- Finalización
	if templates:FindFirstChild("HexPlatform_V2") then
		templates.HexPlatform_V2:Destroy()
	end
	
	model.Parent = templates
	templates:SetAttribute("PlatformReady", true)
	print("✅ PlatformFactory: Modelo Sólido creado en Templates.")
end

local templates = ReplicatedStorage:WaitForChild("Templates", 10)
if templates then
	createHexPlatform(templates)
end
