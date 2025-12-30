-- src/server/Builders/ShopBuilder_Standard.luau
local ShopBuilder_Standard = {}

function ShopBuilder_Standard.BuildStandardPanel(mainPart: BasePart)
    if not mainPart then return end
    
    -- Estetica estandar para tiendas normales (Cristal Simple)
    mainPart.Material = Enum.Material.Glass
    mainPart.Transparency = 0.8 
    mainPart.CastShadow = false
    
    -- Borde Neon Cian (Estilo original)
    local selection = mainPart:FindFirstChild("NeonBorder") or Instance.new("SelectionBox")
    selection.Name = "NeonBorder"
    selection.Adornee = mainPart
    selection.LineThickness = 0.04
    selection.Transparency = 0.2
    selection.Color3 = Color3.fromRGB(0, 255, 255)
    selection.Parent = mainPart
    
    print("✅ [ShopBuilder_Standard] Panel estilizado para: " .. mainPart.Name)
end

return ShopBuilder_Standard
