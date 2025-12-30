-- src/client/ShopBoardController.client.luau
-- Controlador de pantallas físicas (SurfaceGui) - VERSIÓN CANVAS FIJO (4 ITEMS)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
local BuyItem = ReplicatedStorage:WaitForChild("Events"):WaitForChild("BuyItem")

local ShopUI_Folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("ShopUI")

-- Tracking of purchased items for current life
local purchasedItems: { [string]: boolean } = {}

-- MICRO-INTERACCIONES
local function applyHoverEffect(button)
    local originalSize = button.Size
    local hoverSize = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, originalSize.Y.Scale * 1.05, originalSize.Y.Offset)
    
    button.MouseEnter:Connect(function()
        if purchasedItems[button.Parent.Name] then return end
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
            if purchasedItems[button.Parent.Name] then break end
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
    -- Determine the actual Adornee Part (SurfaceGui needs a BasePart, not a Model)
    local adorneePart = board
    if board:IsA("Model") then
        adorneePart = board:FindFirstChild("Display") or board.PrimaryPart or board:FindFirstChildWhichIsA("BasePart", true)
    end
    
    if not adorneePart or not adorneePart:IsA("BasePart") then
        warn("⚠️ [ShopBoardController] No valid Adornee Part found for board:", board.Name)
        return
    end

    -- Use PlayerGui for reliable local input handling
    local playerGui = player:WaitForChild("PlayerGui")
    local sgName = "ShopSurfaceUI_" .. board.Name
    local sg = playerGui:FindFirstChild(sgName) or Instance.new("SurfaceGui")
    
    sg.Name = sgName
    sg.Adornee = adorneePart -- Link to the determined Part
    -- print(string.format("DEBUG: Creating UI for %s using Adornee: %s", board.Name, adorneePart.Name))

    sg.Face = Enum.NormalId.Front
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50
    sg.AlwaysOnTop = true -- FORCE ON TOP to prevent occlusion blocking clicks
    sg.Parent = playerGui 
    sg.ResetOnSpawn = false
    
    sg:ClearAllChildren()
    
    -- Usamos un FRAME normal en lugar de ScrollingFrame para un canvas fijo
    local container = Instance.new("Frame")
    container.Name = "ItemsContainer"
    container.Size = UDim2.new(1, -20, 0.8, -20) -- Leave space for header
    container.Position = UDim2.new(0.5, 0, 0.58, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1 
    container.Parent = sg

    local categoryKey = board:GetAttribute("Category")
    local category = ShopConfig.Categories[categoryKey]

    -- HEADER TITULO
    local header = Instance.new("TextLabel")
    header.Name = "CategoryHeader"
    header.Size = UDim2.new(1, -40, 0.15, 0)
    header.Position = UDim2.new(0.5, 0, 0.05, 0)
    header.AnchorPoint = Vector2.new(0.5, 0)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.FredokaOne
    header.TextSize = 35
    header.TextColor3 = Color3.new(1, 1, 1)
    header.TextStrokeTransparency = 0.5
    header.Text = category and category.Title or "TIENDA"
    header.Parent = sg
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.48, 0, 0.48, 0)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0.04, 0)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    gridLayout.Parent = container

    local itemsToDisplay = {}
    if category then
        itemsToDisplay = category.Items
    else
        -- Fallback: Primeras 4 cosas que encuentre
        local count = 0
        for _, cat in pairs(ShopConfig.Categories) do
            for _, it in ipairs(cat.Items) do
                table.insert(itemsToDisplay, it)
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
        itemCard.Active = true -- Ensure it catches input
        
        -- OVERLAY DE PRÓXIMAMENTE
        local isImplemented = (item.Implemented ~= false)
        if not isImplemented then
            local overlay = Instance.new("Frame")
            overlay.Name = "ComingSoonOverlay"
            overlay.Size = UDim2.new(1, 4, 1, 4)
            overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
            overlay.AnchorPoint = Vector2.new(0.5, 0.5)
            overlay.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            overlay.BackgroundTransparency = 0.4
            overlay.ZIndex = 10
            overlay.Parent = itemCard
            
            local overlayCorner = Instance.new("UICorner")
            overlayCorner.CornerRadius = UDim.new(0, 8)
            overlayCorner.Parent = overlay

            local msgLabel = Instance.new("TextLabel")
            msgLabel.Size = UDim2.new(1, 0, 1, 0)
            msgLabel.BackgroundTransparency = 1
            msgLabel.Font = Enum.Font.FredokaOne
            msgLabel.Text = "PRÓXIMAMENTE"
            msgLabel.TextColor3 = Color3.new(1, 1, 1)
            msgLabel.TextScaled = true
            msgLabel.Rotation = -15
            msgLabel.ZIndex = 11
            msgLabel.Parent = overlay
            
            itemCard.AutoButtonColor = false
        end

        if not template then
            itemCard.Text = item.Name .. "\n" .. item.Price .. " CR"
            itemCard.BackgroundColor3 = isImplemented and (item.Color or Color3.fromRGB(50, 50, 50)) or Color3.fromRGB(30, 30, 30)
            itemCard.BackgroundTransparency = 0.3
            itemCard.Font = Enum.Font.FredokaOne
            itemCard.TextColor3 = isImplemented and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150)
            itemCard.TextScaled = true
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = isImplemented and (item.Color or Color3.new(1,1,1)) or Color3.fromRGB(80, 80, 80)
            stroke.Thickness = 2
            stroke.Parent = itemCard

            -- Check for permanent ownership or session purchase
            local isAlreadyOwned = purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true

            if isAlreadyOwned then
                itemCard.Text = "COMPRADO"
                itemCard.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                itemCard.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            
            -- Direct Click Connection for Fallback Button
             itemCard.MouseButton1Click:Connect(function()
                 if not isImplemented or purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then return end
                 local success, msg = BuyItem:InvokeServer(item.Id)
                 if success then
                    purchasedItems[item.Id] = true
                    itemCard.Text = "COMPRADO"
                    itemCard.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    itemCard.TextColor3 = Color3.fromRGB(100, 255, 100)
                 else
                    local oldText = itemCard.Text
                    itemCard.Text = msg or "ERROR"
                    task.wait(1)
                    itemCard.Text = oldText
                 end
             end)
        else
            -- Data Binding
            local titleLabel = itemCard:FindFirstChild("ItemName", true)
            local priceLabel = itemCard:FindFirstChild("Price", true)
            local buyBtn = itemCard:FindFirstChild("BuyButton", true) or itemCard
            
            if titleLabel then titleLabel.Text = item.Name end
            if priceLabel then priceLabel.Text = item.Price .. " CR" end
            
            if item.Color then
                local bg = itemCard:FindFirstChild("Background", true) or itemCard
                local st = itemCard:FindFirstChildOfClass("UIStroke", true)
                
                if bg:IsA("GuiObject") then 
                    bg.BackgroundColor3 = isImplemented and item.Color or Color3.fromRGB(40, 40, 40)
                end
                if st then 
                    st.Color = isImplemented and item.Color or Color3.fromRGB(60, 60, 60)
                end
            end

            -- Check for permanent ownership or session purchase
            local isAlreadyOwned = purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true

            -- Update state if already purchased
            if isAlreadyOwned then
                if buyBtn:IsA("TextLabel") or buyBtn:IsA("TextButton") then
                    buyBtn.Text = "COMPRADO"
                    buyBtn.TextColor3 = Color3.new(0, 1, 0)
                end
            end
            
            if isImplemented then
                applyHoverEffect(buyBtn)
                animateShine(buyBtn)
                
                buyBtn.MouseButton1Click:Connect(function()
                    if purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then return end
                    
                    local success, msg = BuyItem:InvokeServer(item.Id)
                    
                    if success then
                        purchasedItems[item.Id] = true
                        buyBtn.Text = "COMPRADO"
                        buyBtn.TextColor3 = Color3.new(0, 1, 0)
                    else
                        local originalText = buyBtn.Text
                        buyBtn.Text = msg or "ERROR"
                        buyBtn.TextColor3 = Color3.new(1, 0, 0)
                        task.delay(1, function()
                            if buyBtn then
                                buyBtn.Text = originalText
                                buyBtn.TextColor3 = Color3.new(1, 1, 1) 
                            end
                        end)
                    end
                end)
            else
                if buyBtn:IsA("TextButton") then
                    buyBtn.Text = "BLOQUEADO"
                    buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                end
            end
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
        if (obj.Name == "ShopBoard" or obj.Name == "TiendaVisual" or string.find(obj.Name, "ShopBoard")) and not CollectionService:HasTag(obj, "TiendaTag") then
            -- Check if it's a Part or MeshPart to be a valid board
            if obj:IsA("BasePart") then
                -- print("DEBUG: Found ShopBoard by fallback name:", obj.Name)
                task.spawn(populateBoard, obj)
            end
        end
    end
end

-- Refresh all boards
local function refreshAllBoards()
    local tagged = CollectionService:GetTagged("TiendaTag")
    for _, board in ipairs(tagged) do
        populateBoard(board)
    end
    -- Fallback boards
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj.Name == "ShopBoard" or obj.Name == "TiendaVisual" or string.find(obj.Name, "ShopBoard")) and obj:IsA("BasePart") then
            populateBoard(obj)
        end
    end
end

-- Reset on Death/Spawn
player.CharacterAdded:Connect(function()
    purchasedItems = {} -- Clear purchased items
    task.wait(1)
    refreshAllBoards() -- Redraw to remove "COMPRADO" labels
end)

task.wait(1.5)
discoverAndPopulate()

CollectionService:GetInstanceAddedSignal("TiendaTag"):Connect(function(instance)
    task.wait(0.5)
    populateBoard(instance)
end)
