-- src/client/ShopController.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("🛒 ShopController: Glassmorphism y Contenido Expandido.")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")

local processedBoards = {}
local categoryOrder = {"Movement", "Aero", "Survival", "Economy"}
local shopIndex = 0

local function setupShopUI(shopBoard)
    if processedBoards[shopBoard] then return end
    processedBoards[shopBoard] = true
    shopIndex += 1
    
    -- Seleccionar categoría según el índice de la tienda encontrada
    local catKey = categoryOrder[(shopIndex - 1) % #categoryOrder + 1]
    local config = ShopConfig.Categories[catKey]
    
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "ShopUI_" .. shopBoard.Name
    surfaceGui.Adornee = shopBoard:IsA("BasePart") and shopBoard or (shopBoard:FindFirstChild("Display", true) or shopBoard.PrimaryPart or shopBoard:FindFirstChildWhichIsA("BasePart", true))
    surfaceGui.CanvasSize = Vector2.new(800, 1000)
    surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    surfaceGui.LightInfluence = 0.2
    surfaceGui.Parent = PlayerGui

    -- VIDRIO FROSTED (GLASSMORPHISM EXTREMO)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.BackgroundTransparency = 0.85 -- Súper transparente tipo cristal
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = surfaceGui
    
    -- Gradiente para efecto de luz en el cristal
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 230, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 200))
    })
    gradient.Rotation = 45
    gradient.Transparency = NumberSequence.new(0.4, 0.8)
    gradient.Parent = mainFrame

    -- BORDE NEÓN CELESTE (GUI)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 5
    stroke.Transparency = 0.4
    stroke.Parent = mainFrame

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.Position = UDim2.new(0, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 0 -- Ocultar barra
    content.ScrollingEnabled = false -- No permitir scroll
    content.Parent = mainFrame

    local layout = Instance.new("UIGridLayout")
    layout.CellPadding = UDim2.new(0, 30, 0, 0) -- Espacio entre tarjetas
    layout.CellSize = UDim2.new(0, 350, 0, 700) -- Tamaño para llenar casi todo el alto (Canvas 1000)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    -- Títulos ELIMINADOS por petición del usuario

    -- Render de Botones (Limitado a 2 targets grandes)
    for i = 1, math.min(2, #config.Items) do
        local item = config.Items[i]
        local card = Instance.new("Frame")
        card.Name = item.Id
        card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.Parent = content

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 40)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = item.Color
        cardStroke.Thickness = 6
        cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        cardStroke.Parent = card

        -- Nombre del Item (MÁXIMA PROMINENCIA)
        local itemName = Instance.new("TextLabel")
        itemName.Size = UDim2.new(1, -60, 0, 150)
        itemName.Position = UDim2.new(0, 30, 0, 40)
        itemName.BackgroundTransparency = 1
        itemName.Font = Enum.Font.FredokaOne
        itemName.TextSize = 45 
        itemName.TextColor3 = Color3.new(1, 1, 1)
        itemName.Text = item.Name:upper()
        itemName.TextWrapped = true
        itemName.Parent = card

        -- Visual / Icon Area
        local iconArea = Instance.new("Frame")
        iconArea.Size = UDim2.new(0, 160, 0, 160)
        iconArea.Position = UDim2.new(0.5, -80, 0.45, 0)
        iconArea.BackgroundColor3 = item.Color
        iconArea.BackgroundTransparency = 0.4
        iconArea.Parent = card
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(1, 0)
        iconCorner.Parent = iconArea
        
        local iconGradient = Instance.new("UIGradient")
        iconGradient.Color = ColorSequence.new(item.Color, Color3.new(1,1,1))
        iconGradient.Rotation = 90
        iconGradient.Parent = iconArea

        -- Botón de Compra (Target Real y Enorme)
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyButton"
        buyBtn.Size = UDim2.new(0.85, 0, 0, 100)
        buyBtn.Position = UDim2.new(0.075, 0, 0.8, 0)
        buyBtn.BackgroundColor3 = item.Color
        buyBtn.Font = Enum.Font.FredokaOne
        buyBtn.TextSize = 40
        buyBtn.Text = item.Price .. " CR"
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 25)
        btnCorner.Parent = buyBtn

        buyBtn.MouseButton1Click:Connect(function()
            local success, _ = BuyItemFunction:InvokeServer(item.Id)
            buyBtn.Text = success and "COMPRADO!" or "ERROR"
            task.wait(1.2)
            buyBtn.Text = item.Price .. " CR"
        end)

        -- Hover Effect
        buyBtn.MouseEnter:Connect(function()
            buyBtn.BackgroundColor3 = item.Color:Lerp(Color3.new(1,1,1), 0.3)
        end)
        buyBtn.MouseLeave:Connect(function()
            buyBtn.BackgroundColor3 = item.Color
        end)
    end
    
    print("✅ [Client] Tienda cargada con 2 Targets Optimizados (Sin Título).")
end

for _, obj in ipairs(CollectionService:GetTagged("TiendaTag")) do
    setupShopUI(obj)
end
CollectionService:GetInstanceAddedSignal("TiendaTag"):Connect(setupShopUI)
