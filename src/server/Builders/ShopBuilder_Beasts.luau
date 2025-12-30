--!strict
local ShopBuilder_Beasts = {}

local COLORS = {
	WOOD_DARK = Color3.fromRGB(101, 67, 33),
	TYPE_GREEN = Color3.fromRGB(50, 205, 50),
	NEON_GREEN = Color3.fromRGB(0, 255, 127),
}

function ShopBuilder_Beasts.BuildNaturePanel(mainPart: BasePart)
	if not mainPart then return end
	
	-- 1. Estética Rústica (Madera y Naturaleza)
	mainPart.Material = Enum.Material.Wood
	mainPart.Color = COLORS.WOOD_DARK
	mainPart.Transparency = 0
	
	-- 2. Borde de Selección "Naturaleza"
	local existingSelection = mainPart:FindFirstChild("BeastBorder")
	if existingSelection then existingSelection:Destroy() end
	
	local selection = Instance.new("SelectionBox")
	selection.Name = "BeastBorder"
	selection.Adornee = mainPart
	selection.LineThickness = 0.1
	selection.Color3 = COLORS.NEON_GREEN
	selection.SurfaceTransparency = 0.8
	selection.SurfaceColor3 = COLORS.TYPE_GREEN
	selection.Parent = mainPart
	
	-- 3. Partículas de "Hojas" o Naturaleza (ELIMINADO POR PETICIÓN DE CLIENTE)
	local particleAttr = mainPart:FindFirstChild("NatureParticles")
	if particleAttr then particleAttr:Destroy() end
	
	print("✅ [ShopBuilder_Beasts] Panel natural aplicado a: " .. mainPart.Name)
end

return ShopBuilder_Beasts
