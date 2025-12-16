-- Navidad.server.lua
-- Script mejorado para generar un árbol de navidad espectacular
-- Con luces dinámicas, partículas, animación y escala ajustable.

local ESCALA = 3 -- Factor de tamaño (2 = doble, 3 = triple, etc.)

-- Configuración de Colores
local COLORES = {
	Verde = Color3.fromRGB(35, 80, 25),
	Tronco = Color3.fromRGB(50, 35, 20),
	Nieve = Color3.fromRGB(245, 250, 255),
	Estrella = Color3.fromRGB(255, 215, 0),
	Luces = {
		Color3.fromRGB(255, 50, 50),   -- Rojo
		Color3.fromRGB(50, 255, 50),   -- Verde
		Color3.fromRGB(50, 100, 255),  -- Azul
		Color3.fromRGB(255, 200, 50),  -- Dorado
		Color3.fromRGB(200, 50, 255),  -- Morado
	}
}

-- Tablas para almacenar referencias para animación
local lucesParaAnimar = {}

-- Función auxiliar para crear partes básicas
local function crearParte(nombre, tamano, posicion, color, material, padre)
	local parte = Instance.new("Part")
	parte.Name = nombre
	parte.Size = tamano * ESCALA
	parte.Position = posicion
	parte.Color = color
	parte.Material = material
	parte.Anchored = true
	parte.CastShadow = true
	parte.Parent = padre
	return parte
end

-- 1. TRONCO
local function crearTronco(modelo, centroBase)
	local tamano = Vector3.new(4, 10, 4)
	local pos = centroBase + Vector3.new(0, (tamano.Y * ESCALA)/2, 0)
	crearParte("Tronco", tamano, pos, COLORES.Tronco, Enum.Material.Wood, modelo)
	return (tamano.Y * ESCALA) -- Retorna la altura tope del tronco
end

-- 2. CAPAS DEL ÁRBOL
local function crearFollaje(modelo, centroBase, alturaInicio)
	local capas = 8
	local tamanoBase = 16
	local alturaActual = alturaInicio
	local espesor = 3.5
	
	for i = 1, capas do
		local proporcion = 1 - ((i-1)/capas)
		local tamanoActual = tamanoBase * proporcion
		if tamanoActual < 2 then tamanoActual = 2 end
		
		-- Bloque verde principal
		local tamanoBloque = Vector3.new(tamanoActual, espesor, tamanoActual)
		local pos = centroBase + Vector3.new(0, alturaActual + (espesor*ESCALA/2), 0)
		
		crearParte("Capa_"..i, tamanoBloque, pos, COLORES.Verde, Enum.Material.Grass, modelo)
		
		-- Nieve encima (ligeramente más ancha y delgada)
		local tamanoNieve = Vector3.new(tamanoActual + 0.5, 0.4, tamanoActual + 0.5)
		local posNieve = pos + Vector3.new(0, (espesor*ESCALA/2), 0)
		crearParte("Nieve_"..i, tamanoNieve, posNieve, COLORES.Nieve, Enum.Material.Sand, modelo)
		
		-- Decoraciones en las esquinas (Esferas)
		if i < capas then
			local offset = (tamanoActual * ESCALA) / 2
			local esquinas = {
				Vector3.new(offset, 0, offset),
				Vector3.new(-offset, 0, offset),
				Vector3.new(offset, 0, -offset),
				Vector3.new(-offset, 0, -offset)
			}
			
			for _, vecOffset in ipairs(esquinas) do
				if math.random() > 0.2 then
					local colorRandom = COLORES.Luces[math.random(1, #COLORES.Luces)]
					local esfera = crearParte("Esfera", Vector3.new(1.5, 1.5, 1.5), pos + vecOffset + Vector3.new(0, -1 * ESCALA, 0), colorRandom, Enum.Material.Neon, modelo)
					esfera.Shape = Enum.PartType.Ball
					
					-- Luz real
					local luz = Instance.new("PointLight")
					luz.Color = colorRandom
					luz.Range = 8 * ESCALA
					luz.Brightness = 2
					luz.Parent = esfera
					
					table.insert(lucesParaAnimar, {parte = esfera, luz = luz})
				end
			end
		end
		
		alturaActual = alturaActual + (espesor * 0.8 * ESCALA)
	end
	
	return alturaActual
end

-- 3. ESTRELLA Y PARTÍCULAS
local function crearEstrella(modelo, centroBase, alturaTope)
	local tamano = Vector3.new(5, 5, 1)
	local pos = centroBase + Vector3.new(0, alturaTope + (2 * ESCALA), 0)
	
	local estrella = crearParte("Estrella", tamano, pos, COLORES.Estrella, Enum.Material.Neon, modelo)
	
	-- Rotar 45 grados y hacerla girar lentamente (con script aparte o tween, aqui solo estático por ahora)
	estrella.CFrame = estrella.CFrame * CFrame.Angles(0, math.rad(45), 0)
	
	-- Luz potente
	local luz = Instance.new("PointLight")
	luz.Color = COLORES.Estrella
	luz.Range = 20 * ESCALA
	luz.Brightness = 5
	luz.Parent = estrella
	
	-- Partículas de destello
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = COLORES.Estrella
	sparkles.Parent = estrella
	
	-- Nieve cayendo (ParticleEmitter hacia abajo)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://241555776" -- Textura de copo de nieve genérica o chispa
	emitter.Color = ColorSequence.new(Color3.new(1,1,1))
	emitter.Size = NumberSequence.new(0.5 * ESCALA)
	emitter.Lifetime = NumberRange.new(5, 10)
	emitter.Rate = 20 
	emitter.Speed = NumberRange.new(2 * ESCALA, 5 * ESCALA)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -5, 0) -- Gravedad
	emitter.Parent = estrella
end

-- 4. LUCES EN ESPIRAL (GUIRNALDA)
local function crearGuirnalda(modelo, centroBase, alturaInicio, alturaFinal)
	local radioBase = 8 * ESCALA
	local vueltas = 5
	local cantidadLuces = 80
	
	for i = 0, cantidadLuces do
		local p = i / cantidadLuces
		local angulo = p * (360 * vueltas)
		local radio = radioBase * (1 - p)
		local y = alturaInicio + (p * (alturaFinal - alturaInicio))
		
		local x = math.cos(math.rad(angulo)) * radio
		local z = math.sin(math.rad(angulo)) * radio
		
		local pos = centroBase + Vector3.new(x, y, z)
		
		local color = COLORES.Luces[(i % #COLORES.Luces) + 1]
		local foco = crearParte("Foco_Guirnalda", Vector3.new(0.6, 0.6, 0.6), pos, color, Enum.Material.Neon, modelo)
		foco.CanCollide = false
		
		local luz = Instance.new("PointLight")
		luz.Color = color
		luz.Range = 5 * ESCALA
		luz.Brightness = 1
		luz.Parent = foco
		
		table.insert(lucesParaAnimar, {parte = foco, luz = luz, baseColor = color})
	end
end

-- 5. REGALOS
local function crearRegalos(modelo, centroBase)
	for i = 1, 8 do
		local angulo = math.rad(math.random(0, 360))
		local distancia = math.random(5 * ESCALA, 9 * ESCALA)
		local x = math.cos(angulo) * distancia
		local z = math.sin(angulo) * distancia
		
		local tamano = Vector3.new(math.random(2,4), math.random(2,4), math.random(2,4))
		local pos = centroBase + Vector3.new(x, (tamano.Y*ESCALA)/2, z)
		
		local color = COLORES.Luces[math.random(1, #COLORES.Luces)]
		local regalo = crearParte("Regalo", tamano, pos, color, Enum.Material.Plastic, modelo)
		regalo.Orientation = Vector3.new(0, math.random(0,90), 0)
		
		-- Cinta (Cruz)
		local cinta1 = crearParte("Cinta", Vector3.new(tamano.X + 0.2, tamano.Y, 0.5), pos, Color3.new(1,1,1), Enum.Material.SmoothPlastic, modelo)
		cinta1.CFrame = regalo.CFrame
		local cinta2 = crearParte("Cinta", Vector3.new(0.5, tamano.Y, tamano.Z + 0.2), pos, Color3.new(1,1,1), Enum.Material.SmoothPlastic, modelo)
		cinta2.CFrame = regalo.CFrame
	end
end

-- ANIMACIÓN
local function iniciarAnimacion()
	task.spawn(function()
		while true do
			for _, item in ipairs(lucesParaAnimar) do
				-- Cambiar color aleatoriamente o parpadear
				if math.random() > 0.95 then
					local nuevoColor = COLORES.Luces[math.random(1, #COLORES.Luces)]
					item.parte.Color = nuevoColor
					item.luz.Color = nuevoColor
				end
			end
			task.wait(0.5)
		end
	end)
end

-- FUNCIÓN PRINCIPAL
local function generarArbolNavidadPro(posicion)
	local modelo = Instance.new("Model")
	modelo.Name = "Arbol_Navidad_Ultra_Pro"
	
	crearTronco(modelo, posicion)
	local alturaTopeFollaje = crearFollaje(modelo, posicion, 4 * ESCALA) -- Empezar un poco arriba del suelo
	
	crearGuirnalda(modelo, posicion, 5 * ESCALA, alturaTopeFollaje)
	crearEstrella(modelo, posicion, alturaTopeFollaje)
	crearRegalos(modelo, posicion)
	
	modelo.Parent = workspace
	
	-- Iniciar bucle de luces
	iniciarAnimacion()
end

-- EJECUCIÓN
generarArbolNavidadPro(Vector3.new(0, 0, 0))