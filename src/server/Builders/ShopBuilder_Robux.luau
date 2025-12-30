-- src/server/builder/ShopBuilder.server.luau
local ShopBuilder = {}

function ShopBuilder.BuildFuturisticKiosk(basePart: BasePart)
    local root = Instance.new("Model")
    root.Name = "FuturisticKiosk_" .. basePart.Name
    root.Parent = basePart.Parent
    
    -- Ajustar la basePart original para que sea el Display
    basePart.Transparency = 1
    basePart.CanCollide = false
    basePart.Name = "Display"
    basePart.Parent = root
    
    local size = basePart.Size
    local cf = basePart.CFrame
    
    -- 1. Marco Principal (Marco Neon)
    local frame = Instance.new("Part")
    frame.Name = "NeonFrame"
    frame.Size = size + Vector3.new(0.5, 0.5, -size.Z + 0.2)
    frame.CFrame = cf * CFrame.new(0, 0, size.Z/2)
    frame.Material = Enum.Material.Neon
    frame.Color = Color3.fromRGB(85, 0, 255) -- Púrpura Neón
    frame.CanCollide = false
    frame.Parent = root

    -- 2. Panel Trasero (Glassmorphism Base)
    local back = Instance.new("Part")
    back.Name = "BackPanel"
    back.Size = size + Vector3.new(0.2, 0.2, 0)
    back.CFrame = cf * CFrame.new(0, 0, -0.1)
    back.Material = Enum.Material.Glass
    back.Color = Color3.fromRGB(20, 20, 40)
    back.Transparency = 0.5
    back.Parent = root
    
    -- 3. Detalles de Esquina (Cian Neón)
    local cornerOffset = (size/2) + Vector3.new(0.25, 0.25, 0)
    local corners = {
        Vector3.new(1, 1, 0), Vector3.new(-1, 1, 0),
        Vector3.new(1, -1, 0), Vector3.new(-1, -1, 0)
    }
    
    for _, offsetMult in ipairs(corners) do
        local detail = Instance.new("Part")
        detail.Size = Vector3.new(0.4, 0.4, 0.4)
        detail.CFrame = cf * CFrame.new(cornerOffset.X * offsetMult.X, cornerOffset.Y * offsetMult.Y, size.Z/2)
        detail.Material = Enum.Material.Neon
        detail.Color = Color3.fromRGB(0, 255, 255) -- Cian Neón
        detail.Shape = Enum.PartType.Ball
        detail.Parent = root
    end

    -- 4. Luces de Apoyo
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 170, 255)
    light.Brightness = 3
    light.Range = 15
    light.Parent = frame

    return root
end

return ShopBuilder
