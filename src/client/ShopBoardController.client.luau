-- src/client/ShopBoardController.client.luau
-- Controlador de pantallas físicas (SurfaceGui) - VERSIÓN CANVAS FIJO (4 ITEMS)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
local BuyItem = ReplicatedStorage:WaitForChild("Events"):WaitForChild("BuyItem")

local ShopUI_Folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("ShopUI")

-- MICRO-INTERACCIONES
local function applyHoverEffect(button)
    local originalSize = button.Size
    local hoverSize = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, originalSize.Y.Scale * 1.05, originalSize.Y.Offset)
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = hoverSize}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = originalSize}):Play()
    end)
end

local function animateShine(button)
    local gradient = button:FindFirstChildWhichIsA("UIGradient")
    if not gradient then return end
    
    task.spawn(function()
        while button and button.Parent do
            gradient.Offset = Vector2.new(-1, 0)
            local tween = TweenService:Create(gradient, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            tween:Play()
            tween.Completed:Wait()
            task.wait(3)
        end
    end)
end

-- POBLAR UNA PANTALLA (SIN BARRA DE DESPLAZAMIENTO)
local function populateBoard(board)
    local sg = board:FindFirstChild("ShopSurfaceUI") or board:FindFirstChildOfClass("SurfaceGui") or Instance.new("SurfaceGui")
    sg.Name = "ShopSurfaceUI"
    sg.Face = Enum.NormalId.Front
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50
    sg.Parent = board
    
    sg:ClearAllChildren()
    
    -- Usamos un FRAME normal en lugar de ScrollingFrame para un canvas fijo
    local container = Instance.new("Frame")
    container.Name = "ItemsContainer"
    container.Size = UDim2.new(1, -20, 1, -20)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1 -- Fondo transparente para efecto Glassmorphism del board
    container.Parent = sg
    
    local gridLayout = Instance.new("UIGridLayout")
    -- Ajustado para 2x2 en un canvas fijo
    gridLayout.CellSize = UDim2.new(0.48, 0, 0.48, 0)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0.04, 0)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    gridLayout.Parent = container

    local categoryKey = board:GetAttribute("Category")
    local category = ShopConfig.Categories[categoryKey]
    
    local itemsToDisplay = {}
    if category then
        itemsToDisplay = category.Items
    else
        -- Fallback: Primeras 4 cosas que encuentre
        local count = 0
        for _, cat in pairs(ShopConfig.Categories) do
            for _, item in ipairs(cat.Items) do
                table.insert(itemsToDisplay, item)
                count += 1
                if count >= 4 then break end
            end
            if count >= 4 then break end
        end
    end

    local template = (ShopUI_Folder and ShopUI_Folder:FindFirstChild("ItemTemplate"))

    for i = 1, math.min(#itemsToDisplay, 4) do
        local item = itemsToDisplay[i]
        local itemCard = template and template:Clone() or Instance.new("TextButton")
        itemCard.Name = item.Id
        
        if not template then
            itemCard.Text = item.Name .. "\n" .. item.Price .. " CR"
            itemCard.BackgroundColor3 = item.Color or Color3.fromRGB(50, 50, 50)
            itemCard.BackgroundTransparency = 0.3
            itemCard.Font = Enum.Font.FredokaOne
            itemCard.TextColor3 = Color3.new(1,1,1)
            itemCard.TextScaled = true
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = item.Color or Color3.new(1,1,1)
            stroke.Thickness = 2
            stroke.Parent = itemCard
        else
            -- Data Binding
            local titleLabel = itemCard:FindFirstChild("ItemName", true)
            local priceLabel = itemCard:FindFirstChild("Price", true)
            local buyBtn = itemCard:FindFirstChild("BuyButton", true) or itemCard
            
            if titleLabel then titleLabel.Text = item.Name end
            if priceLabel then priceLabel.Text = item.Price .. " CR" end
            
            if item.Color then
                local bg = itemCard:FindFirstChild("Background", true) or itemCard
                bg.BackgroundColor3 = item.Color
                local st = itemCard:FindFirstChildOfClass("UIStroke", true)
                if st then st.Color = item.Color end
            end
            
            applyHoverEffect(buyBtn)
            animateShine(buyBtn)
            
            buyBtn.MouseButton1Click:Connect(function()
                BuyItem:InvokeServer(item.Id)
            end)
        end
        
        itemCard.Parent = container
    end
end

-- INICIAR
local function discoverAndPopulate()
    local tagged = CollectionService:GetTagged("TiendaTag")
    for _, board in ipairs(tagged) do
        task.spawn(populateBoard, board)
    end
    
    -- Fallback por nombre
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj.Name == "ShopBoard" or obj.Name == "TiendaVisual") and not CollectionService:HasTag(obj, "TiendaTag") then
            task.spawn(populateBoard, obj)
        end
    end
end

task.wait(2)
discoverAndPopulate()

CollectionService:GetInstanceAddedSignal("TiendaTag"):Connect(function(instance)
    task.wait(0.5)
    populateBoard(instance)
end)
