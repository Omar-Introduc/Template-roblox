-- Un generador de árbol simple "Low Poly" usando solo código
local function crearArbol(posicion)
	local modelo = Instance.new("Model")
	modelo.Name = "Arbol_Generado"
	
	-- 1. El Tronco
	local tronco = Instance.new("Part")
	tronco.Name = "Tronco"
	tronco.Size = Vector3.new(2, 8, 2)
	tronco.Position = posicion + Vector3.new(0, 4, 0)
	tronco.Color = Color3.fromRGB(86, 62, 44) -- Marrón
	tronco.Material = Enum.Material.Wood
	tronco.Anchored = true
	tronco.Parent = modelo

	-- 2. Las Hojas (3 capas de pirámides/bloques)
	local tamanos = {10, 7, 4} -- Tamaños de los bloques de hojas
	local alturas = {7, 9, 11} -- Alturas donde van
	
	for i, tamano in ipairs(tamanos) do
		local hojas = Instance.new("Part")
		hojas.Name = "Hojas_" .. i
		hojas.Size = Vector3.new(tamano, 2, tamano)
		hojas.Position = posicion + Vector3.new(0, alturas[i], 0)
		hojas.Color = Color3.fromRGB(75, 151, 75) -- Verde
		hojas.Material = Enum.Material.Plastic
		hojas.Anchored = true
		-- Hacemos que rote un poco al azar para que se vea natural
		hojas.CFrame = CFrame.new(hojas.Position) * CFrame.Angles(0, math.rad(math.random(0, 45)), 0)
		hojas.Parent = modelo
	end

	modelo.Parent = workspace
end

-- Generar un árbol en el centro del mapa
crearArbol(Vector3.new(0, 0, 0))