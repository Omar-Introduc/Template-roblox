-- CharizardFactory.server.luau (Traspaso EXACTO React/Three.js -> Roblox Voxel)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local COLORS = {
	Orange = Color3.fromHex("#FB8C00"),
	Cream = Color3.fromHex("#FFECB3"),
	Teal = Color3.fromHex("#00897B"),
	Fire = Color3.fromHex("#FF3D00"),
	White = Color3.fromHex("#FFFFFF"),
	Black = Color3.fromHex("#111111"),
	Smoke = Color3.fromHex("#555555")
}

-- Helper para crear Bloques (Equivalente a tu función 'box' de React)
local function createBox(name, size, pos, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size -- W, H, D directo del código React
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic -- Plástico liso para que se vea limpio (no Lego rugoso)
	part.CastShadow = true
	part.Anchored = false -- Falso para que los Motor6D funcionen
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	
	-- La posición inicial no importa tanto porque el Motor6D la controlará, 
	-- pero la seteamos para referencia visual si se rompe el joint.
	part.CFrame = parent.IsA(parent, "BasePart") and parent.CFrame * CFrame.new(pos) or CFrame.new(pos)
	part.Parent = parent
	return part
end

-- Helper para Articulaciones (Equivalente a añadir a un THREE.Group y rotar)
local function createJoint(name, part0, part1, c0, c1, rotationOffset)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0 or CFrame.new()
	motor.C1 = c1 or CFrame.new()
	
	-- Aplicar rotación inicial si el código React tenía .rotation.x = ...
	if rotationOffset then
		motor.C0 = motor.C0 * rotationOffset
	end
	
	motor.Parent = part0
	return motor
end

local function generateCharizard(templates)
	print("🔥 CharizardFactory: Construyendo Voxel Articulado (React Port)...")
	
	local model = Instance.new("Model")
	model.Name = "Charivoxel"

	-- === 1. CUERPO (BodyGroup) ===
	-- React: box(3.5, 4.5, 3, 0, 0, 0, ...)
	local torso = createBox("Torso", Vector3.new(3.5, 4.5, 3), Vector3.new(0,0,0), COLORS.Orange, model)
	torso.Anchored = true -- La raíz anclada
	model.PrimaryPart = torso

	-- Panza (Cream)
	-- React: box(2.8, 3.8, 0.5, 0, -0.2, 1.55, ...)
	local belly = createBox("Belly", Vector3.new(2.8, 3.8, 0.5), Vector3.new(0, -0.2, 1.55), COLORS.Cream, model)
	createJoint("BellyWeld", torso, belly, CFrame.new(0, -0.2, 1.55))

	-- === 2. CUELLO Y CABEZA (NeckGroup) ===
	-- React: neckGroup.position.set(0, 2.2, 0)
	-- React: box(1.8, 2.5, 1.8 ...).rotation.x = 0.2
	
	local neck = createBox("Neck", Vector3.new(1.8, 2.5, 1.8), Vector3.new(0, 2.2, 0), COLORS.Orange, model)
	-- El joint simula el neckGroup.position (0, 2.2, 0)
	-- Y aplicamos la rotación X = 0.2 en el C0
	createJoint("Neck", torso, neck, CFrame.new(0, 2.2, 0) * CFrame.Angles(0.2, 0, 0), CFrame.new(0, -1, 0)) 
	-- Nota: Ajustamos el pivot del cuello a la base (-1 en Y local) para que rote desde abajo

	-- Cabeza (HeadGroup)
	-- React: headGroup.position.set(0, 2.2, 0.5) (relativo al cuello)
	local head = createBox("Head", Vector3.new(2.2, 2.2, 3), Vector3.new(0,0,0), COLORS.Orange, model)
	createJoint("Head", neck, head, CFrame.new(0, 1.25, 0.5)) 
	-- Pivot en la base de la cabeza

	-- Cuernos
	-- React: box(0.4, 1.5, 0.4, -0.8, 1.5, -0.8 ...).rotation.x = -0.5
	local function addHorn(xMult)
		local horn = createBox("Horn", Vector3.new(0.4, 1.5, 0.4), Vector3.new(0,0,0), COLORS.Orange, model)
		createJoint("HornWeld", head, horn, 
			CFrame.new(0.8 * xMult, 1.5, -0.8) * CFrame.Angles(-0.5, 0, 0),
			CFrame.new(0, -0.75, 0) -- Pivot en base del cuerno
		)
	end
	addHorn(1) -- Derecha
	addHorn(-1) -- Izquierda

	-- Ojos
	-- React: box(0.4, 0.4, 0.1, -0.8, 0.8, 2.05, ...)
	local eyeL = createBox("EyeL", Vector3.new(0.4, 0.4, 0.1), Vector3.new(0,0,0), COLORS.Black, model)
	createJoint("EyeL_Weld", head, eyeL, CFrame.new(-0.8, 0.8, 1.52)) -- Z ajustado a la superficie frontal (3/2 + 0.02)
	
	local eyeR = createBox("EyeR", Vector3.new(0.4, 0.4, 0.1), Vector3.new(0,0,0), COLORS.Black, model)
	createJoint("EyeR_Weld", head, eyeR, CFrame.new(0.8, 0.8, 1.52))

	-- Mandíbula (JawGroup)
	-- React: jawGroup.position.set(0, -0.2, 1)
	-- React: box(1.8, 0.6, 2.5 ...)
	local jaw = createBox("Jaw", Vector3.new(1.8, 0.6, 2.5), Vector3.new(0,0,0), COLORS.Orange, model)
	-- Pivot trasero para abrir la boca
	createJoint("Jaw", head, jaw, CFrame.new(0, -0.2, 0.5), CFrame.new(0, 0, -1.25))

	-- Dientes
	local t1 = createBox("Tooth", Vector3.new(0.2, 0.4, 0.2), Vector3.new(0,0,0), COLORS.White, model)
	createJoint("Tw1", jaw, t1, CFrame.new(-0.7, 0.5, 1.0))
	local t2 = createBox("Tooth", Vector3.new(0.2, 0.4, 0.2), Vector3.new(0,0,0), COLORS.White, model)
	createJoint("Tw2", jaw, t2, CFrame.new(0.7, 0.5, 1.0))

	-- === 3. ALAS (Pivotes) ===
	local function createWing(isLeft)
		local m = isLeft and -1 or 1 -- React usa -1.5 para izquierda
		
		-- Pivot Group (Invisible en React, Parte transparente aquí)
		-- React: pivot.position.set(isLeft ? -1.5 : 1.5, 1.5, -1)
		local pivotPart = Instance.new("Part", model)
		pivotPart.Name = isLeft and "WingPivotL" or "WingPivotR"
		pivotPart.Size = Vector3.new(0.5, 0.5, 0.5)
		pivotPart.Transparency = 1
		pivotPart.CanCollide = false
		createJoint("WingMotor", torso, pivotPart, CFrame.new(1.5 * m, 1.5, -1))

		-- Hueso
		-- React: box(isLeft ? -4 : 4, 0.6, 0.6, isLeft ? -2 : 2, 0, 0 ...)
		local boneSizeX = 4
		local bonePosX = 2 * m
		local bone = createBox("WingBone", Vector3.new(boneSizeX, 0.6, 0.6), Vector3.new(0,0,0), COLORS.Orange, model)
		createJoint("BoneWeld", pivotPart, bone, CFrame.new(bonePosX, 0, 0))

		-- Membrana 1
		-- React: box(isLeft ? -3.5 : 3.5, 0.1, 2.5, isLeft ? -1.8 : 1.8, -0.2, 1.2 ...)
		local mem1 = createBox("Membrane1", Vector3.new(3.5, 0.1, 2.5), Vector3.new(0,0,0), COLORS.Teal, model)
		createJoint("Mem1Weld", pivotPart, mem1, CFrame.new(1.8 * m, -0.2, 1.2))

		-- Membrana 2
		-- React: box(isLeft ? -2.5 : 2.5, 0.1, 2, isLeft ? -3.5 : 3.5, -0.5, 0.8 ...)
		local mem2 = createBox("Membrane2", Vector3.new(2.5, 0.1, 2), Vector3.new(0,0,0), COLORS.Teal, model)
		createJoint("Mem2Weld", pivotPart, mem2, CFrame.new(3.5 * m, -0.5, 0.8))
	end
	createWing(true) -- Izquierda (Left)
	createWing(false) -- Derecha (Right)

	-- === 4. COLA (TailPivot) ===
	-- React: tailPivot.position.set(0, -1.5, -1.2)
	-- React: tail1 box(1.5, 1.5, 2.5 ...).rotation.x = -0.2
	
	local tail1 = createBox("Tail1", Vector3.new(1.5, 1.5, 2.5), Vector3.new(0,0,0), COLORS.Orange, model)
	createJoint("Tail1", torso, tail1, CFrame.new(0, -1.5, -1.2) * CFrame.Angles(-0.2, 0, 0), CFrame.new(0, 0, 1.25))

	-- Tail2
	-- React: tail2.position.set(0, -1, -3.5) RELATIVO al Pivot
	-- Pero en React, Tail2 es hija de Pivot, no de Tail1 directamente en posición, pero visualmente sigue la cadena.
	-- Vamos a encadenarlos para mejor física en Roblox: Tail1 -> Tail2
	
	local tail2 = createBox("Tail2", Vector3.new(1.2, 1.2, 3), Vector3.new(0,0,0), COLORS.Orange, model)
	-- Ajustamos offset relativo a Tail1
	createJoint("Tail2", tail1, tail2, CFrame.new(0, -0.2, -2.5) * CFrame.Angles(0.3, 0, 0), CFrame.new(0, 0, 1.5))

	-- TailTip
	-- React: tailTip.position.set(0, 0.5, -2.5) relative to tail2 .rotation.x = 0.4
	local tailTip = createBox("TailTip", Vector3.new(0.8, 0.8, 2), Vector3.new(0,0,0), COLORS.Orange, model)
	createJoint("TailTip", tail2, tailTip, CFrame.new(0, 0.5, -2.5) * CFrame.Angles(0.4, 0, 0), CFrame.new(0, 0, 1))

	-- Fire Point
	local firePart = Instance.new("Part", model)
	firePart.Name = "FirePoint"
	firePart.Size = Vector3.new(0.2,0.2,0.2)
	firePart.Transparency = 1
	firePart.CanCollide = false
	createJoint("FireWeld", tailTip, firePart, CFrame.new(0, 0, -1)) -- Punta de la cola

	-- Partículas de Fuego (Igual que en tu código)
	local fire = Instance.new("ParticleEmitter", firePart)
	fire.Texture = "rbxassetid://6201389270"
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.White),
		ColorSequenceKeypoint.new(0.2, COLORS.Orange),
		ColorSequenceKeypoint.new(1, COLORS.Fire)
	})
	fire.Size = NumberSequence.new(1.5, 0)
	fire.Rate = 50
	fire.Speed = NumberRange.new(5, 8)
	
	local light = Instance.new("PointLight", firePart)
	light.Color = COLORS.Fire
	light.Brightness = 2
	light.Range = 10

	-- === 5. EXTREMIDADES ===
	-- Brazos
	-- React: box(0.8, 1.8, 0.8, -1.8, 0.5, 1 ...).rotation.x = -0.8
	local function addArm(isLeft)
		local m = isLeft and -1 or 1
		local arm = createBox("Arm", Vector3.new(0.8, 1.8, 0.8), Vector3.new(0,0,0), COLORS.Orange, model)
		createJoint("ArmWeld", torso, arm, CFrame.new(1.8 * m, 0.5, 1) * CFrame.Angles(-0.8, 0, 0), CFrame.new(0, 0.9, 0))
	end
	addArm(true)
	addArm(false)

	-- Piernas
	-- React: box(1.5, 2.5, 2, -1.6, -2.5, 0.5 ...)
	local function addLeg(isLeft)
		local m = isLeft and -1 or 1
		local leg = createBox("Leg", Vector3.new(1.5, 2.5, 2), Vector3.new(0,0,0), COLORS.Orange, model)
		createJoint("LegWeld", torso, leg, CFrame.new(1.6 * m, -2.5, 0.5))
		
		-- Garras (Hijas de la pierna en Roblox para que se muevan con ella)
		local c1 = createBox("Claw1", Vector3.new(0.3, 0.3, 0.5), Vector3.new(0,0,0), COLORS.White, model)
		createJoint("CW1", leg, c1, CFrame.new(-0.4, -1.25, 1.0))
		local c2 = createBox("Claw2", Vector3.new(0.3, 0.3, 0.5), Vector3.new(0,0,0), COLORS.White, model)
		createJoint("CW2", leg, c2, CFrame.new(0.4, -1.25, 1.0))
	end
	addLeg(true)
	addLeg(false)

	-- Finalización
	CollectionService:AddTag(model, "Charivoxel")
	
	if templates:FindFirstChild("Charivoxel") then
		templates.Charivoxel:Destroy()
	end
	model.Parent = templates
	templates:SetAttribute("CharizardReady", true)
	print("✅ CharizardFactory: Voxel Model (React Exact) creado.")
end

local templates = ReplicatedStorage:WaitForChild("Templates", 10)
if templates then
	generateCharizard(templates)
end
