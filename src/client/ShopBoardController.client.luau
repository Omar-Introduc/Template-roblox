-- src/client/ShopBoardController.client.luau
--!strict
-- Dual-Style Shop Controller (Futuristic Robux vs Standard CR)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
local BuyItem = ReplicatedStorage:WaitForChild("Events"):WaitForChild("BuyItem")

local purchasedItems: { [string]: boolean } = {}

-- DESIGN TOKENS
local COLORS = {
    BG_MAIN = Color3.fromRGB(15, 15, 30),
    BG_GLASS = Color3.fromRGB(25, 25, 50),
    NEON_BLUE = Color3.fromRGB(0, 255, 255),
    NEON_PURPLE = Color3.fromRGB(180, 0, 255),
    GOLD = Color3.fromRGB(255, 215, 0),
    WHITE = Color3.new(1, 1, 1),
    TEXT_DIM = Color3.fromRGB(180, 180, 200)
}

-- UTILS
local function createCorner(parent: Instance, radius: number?)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
end

local function createStroke(parent: Instance, color: Color3, thickness: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 2
    stroke.Transparency = 0.3
    stroke.Parent = parent
    return stroke
end

local function applyHover(button: GuiButton)
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            BackgroundColor3 = COLORS.NEON_BLUE:Lerp(originalColor, 0.7)
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.4,
            BackgroundColor3 = originalColor
        }):Play()
    end)
end

-- ==========================================
-- LÓGICA DE TIENDA ESTÁNDAR (LAYOUT ORIGINAL)
-- ==========================================
local function populateStandardBoard(board: BasePart)
    local sgName = "StandardShop_" .. board.Name
    local foundSg = playerGui:FindFirstChild(sgName)
    local sg: SurfaceGui
    
    if foundSg and foundSg:IsA("SurfaceGui") then
        sg = foundSg
    else
        sg = Instance.new("SurfaceGui")
        sg.Name = sgName
        sg.Parent = playerGui
    end

    sg.Adornee = board
    sg.Face = Enum.NormalId.Front
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50
    sg.AlwaysOnTop = false -- FIX: Ya no se ve a través de paredes
    sg.ZOffset = 0.05 -- Evitar Z-fighting
    sg.ResetOnSpawn = false
    sg:ClearAllChildren()

    local catKeyVal = board:GetAttribute("Category")
    local categoryKey: string = if typeof(catKeyVal) == "string" then catKeyVal else "Movement"
    local category = ShopConfig.Categories[categoryKey]

    -- Contenedor Principal (Transparencia Total)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 1, -10)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1 -- ELIMINADO COLOR NEGRO
    container.Parent = sg

    -- Título centrado arriba
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = (category and category.Title or tostring(categoryKey)):upper()
    title.Font = Enum.Font.FredokaOne
    title.TextColor3 = COLORS.WHITE
    title.TextSize = 40
    title.TextXAlignment = Enum.TextXAlignment.Center -- CENTRADO
    title.Parent = container

    local gridFrame = Instance.new("Frame")
    gridFrame.Size = UDim2.new(1, -40, 1, -80)
    gridFrame.Position = UDim2.fromOffset(20, 70)
    gridFrame.BackgroundTransparency = 1
    gridFrame.Parent = container

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.48, -10, 0.48, -10) -- REJILLA 2x2
    grid.CellPadding = UDim2.new(0.04, 0, 0.04, 0)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = gridFrame

    if category then
        for i, item in ipairs(category.Items) do
            local card = Instance.new("Frame")
            card.BackgroundColor3 = item.Color or Color3.fromRGB(100, 100, 100)
            card.BackgroundTransparency = 1 -- TRANSPARENCIA 1 (VIDRIO)
            card.LayoutOrder = i
            createCorner(card, 12)
            
            -- Borde del color del Item para dar forma
            local stroke = createStroke(card, item.Color or COLORS.WHITE, 3)
            stroke.Transparency = 0.2

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -20, 0, 70)
            nameLabel.Position = UDim2.fromOffset(10, 10)
            nameLabel.Text = item.Name
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextColor3 = COLORS.WHITE
            nameLabel.TextSize = 24 -- TEXTO MÁS GRANDE
            nameLabel.TextWrapped = true
            nameLabel.BackgroundTransparency = 1
            nameLabel.Parent = card

            if item.Implemented == false then
                -- ESTILO PRÓXIMAMENTE
                local soon = Instance.new("TextLabel")
                soon.Size = UDim2.new(1, 0, 0.3, 0)
                soon.Position = UDim2.fromScale(0, 0.5)
                soon.Text = "PRÓXIMAMENTE"
                soon.Font = Enum.Font.FredokaOne
                soon.TextColor3 = Color3.fromRGB(200, 200, 200)
                soon.TextSize = 22 -- TEXTO MÁS GRANDE
                soon.BackgroundTransparency = 1
                soon.Parent = card
                
                stroke.Color = Color3.fromRGB(80, 80, 80)
                nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                local priceLabel = Instance.new("TextLabel")
                priceLabel.Size = UDim2.new(1, 0, 0, 40)
                priceLabel.Position = UDim2.fromScale(0, 0.45)
                priceLabel.Text = tostring(item.Price) .. " CR"
                priceLabel.Font = Enum.Font.FredokaOne
                priceLabel.TextColor3 = COLORS.WHITE
                priceLabel.TextSize = 35 -- PRECIO MÁS GRANDE
                priceLabel.BackgroundTransparency = 1
                priceLabel.Parent = card

                local buyBtn = Instance.new("TextButton")
                buyBtn.Size = UDim2.new(0.9, 0, 0, 65) -- BOTÓN MUCHO MÁS GRANDE
                buyBtn.Position = UDim2.fromScale(0.05, 0.68)
                buyBtn.BackgroundColor3 = item.Color or COLORS.NEON_BLUE
                buyBtn.BackgroundTransparency = 0.2
                buyBtn.Text = "COMPRAR"
                buyBtn.Font = Enum.Font.FredokaOne
                buyBtn.TextColor3 = COLORS.WHITE
                buyBtn.TextSize = 24 -- LETRAS MÁS GRANDES
                createCorner(buyBtn, 10)
                buyBtn.Parent = card

                if purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then
                    buyBtn.Text = "LISTO"
                    buyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                    buyBtn.BackgroundTransparency = 0
                end

                buyBtn.MouseButton1Click:Connect(function()
                    if purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then return end
                    local success, msg = BuyItem:InvokeServer(item.Id)
                    if success then
                        purchasedItems[item.Id] = true
                        buyBtn.Text = "LISTO"
                        buyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                    else
                        buyBtn.Text = tostring(msg or "ERROR")
                        task.wait(1)
                        buyBtn.Text = "COMPRAR"
                    end
                end)
            end

            card.Parent = gridFrame
        end
    end
end

-- ==========================================
-- LÓGICA DE TIENDA FUTURISTA (ROBUX ONLY)
-- ==========================================
local function populateFuturisticBoard(board: BasePart)
    local sgName = "FuturisticShop_" .. board.Name
    local foundSg = playerGui:FindFirstChild(sgName)
    local sg: SurfaceGui
    
    if foundSg and foundSg:IsA("SurfaceGui") then
        sg = foundSg
    else
        sg = Instance.new("SurfaceGui")
        sg.Name = sgName
        sg.Parent = playerGui
    end

    sg.Adornee = board
    sg.Face = Enum.NormalId.Front
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50
    sg.AlwaysOnTop = false -- FIX: Ya no se ve a través de paredes
    sg.ZOffset = 0.05 -- Evitar Z-fighting con la parte
    sg.ResetOnSpawn = false
    sg:ClearAllChildren()

    -- 1. MAIN CANVAS (Glassmorphism)
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(1, -20, 1, -20)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = COLORS.BG_MAIN
    main.BackgroundTransparency = 0.2
    createCorner(main, 20)
    createStroke(main, COLORS.NEON_PURPLE, 3)
    main.Parent = sg

    -- 2. TOP BAR (Title & Info)
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, -40, 0, 80)
    topBar.Position = UDim2.fromOffset(20, 20)
    topBar.BackgroundTransparency = 1
    topBar.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0) -- Ocupa todo el ancho para centrar
    title.Text = "STELLAR PREMIUM"
    title.Font = Enum.Font.FredokaOne
    title.TextColor3 = COLORS.WHITE
    title.TextSize = 45
    title.TextXAlignment = Enum.TextXAlignment.Center -- CENTRADO
    title.BackgroundTransparency = 1
    title.Parent = topBar

    local balanceLabel = Instance.new("TextLabel")
    balanceLabel.Size = UDim2.new(0, 200, 0, 40)
    balanceLabel.Position = UDim2.new(1, -210, 0.5, 0)
    balanceLabel.AnchorPoint = Vector2.new(0, 0.5)
    local balVal = player:GetAttribute("Coins")
    balanceLabel.Text = string.format("CR: %d", if typeof(balVal) == "number" then balVal else 0)
    balanceLabel.Font = Enum.Font.GothamBold
    balanceLabel.TextColor3 = COLORS.NEON_BLUE
    balanceLabel.TextSize = 25
    balanceLabel.TextXAlignment = Enum.TextXAlignment.Right
    balanceLabel.BackgroundTransparency = 1
    balanceLabel.Parent = topBar
    
    player:GetAttributeChangedSignal("Coins"):Connect(function()
        local newVal = player:GetAttribute("Coins")
        balanceLabel.Text = string.format("CR: %d", if typeof(newVal) == "number" then newVal else 0)
    end)

    -- 3. CONTENT AREA (Items - Expanded to fill full width)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -40, 1, -120) -- Expandido (antes -230)
    contentArea.Position = UDim2.fromOffset(20, 100) -- Movido a la izquierda (antes 210)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = main

    local scrollingContent = Instance.new("ScrollingFrame")
    scrollingContent.Size = UDim2.new(1, 0, 1, 0)
    scrollingContent.BackgroundTransparency = 1
    scrollingContent.ScrollBarThickness = 4
    scrollingContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingContent.Parent = contentArea

    local catAttrVal = board:GetAttribute("Category")
    local currentCategory: string = if typeof(catAttrVal) == "string" then catAttrVal else "Robux"

    local function renderItems(catKey: string)
        scrollingContent:ClearAllChildren()
        
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 15)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.VerticalAlignment = Enum.VerticalAlignment.Center -- CENTRAR ITEMS VERTICALMENTE
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = scrollingContent
        
        local category = ShopConfig.Categories[catKey]
        if not category then return end
        
        for i, item in ipairs(category.Items) do
            -- CARTA ESPECIAL (Horizontal - ANCHO OPTIMIZADO)
            local card = Instance.new("Frame")
            card.Name = "SpecialCard_" .. item.Id
            card.Size = UDim2.new(0.98, 0, 0, 130) -- Más ancha para aprovechar espacio
            card.BackgroundColor3 = COLORS.BG_GLASS
            card.BackgroundTransparency = 0.5
            card.LayoutOrder = i
            createCorner(card, 15)
            
            local stroke = createStroke(card, item.CurrencyType == "Robux" and COLORS.GOLD or COLORS.NEON_BLUE, 3)
            stroke.Transparency = 0.1

            -- Icon Area
            local iconFrame = Instance.new("Frame")
            iconFrame.Size = UDim2.new(0, 90, 0, 90)
            iconFrame.Position = UDim2.fromOffset(20, 20)
            iconFrame.BackgroundColor3 = item.Color or COLORS.NEON_PURPLE
            iconFrame.BackgroundTransparency = 0.3
            createCorner(iconFrame, 45)
            createStroke(iconFrame, COLORS.WHITE, 2)
            iconFrame.Parent = card

            local iconText = Instance.new("TextLabel")
            iconText.Size = UDim2.new(1, 0, 1, 0)
            iconText.Text = "★"
            iconText.TextColor3 = COLORS.WHITE
            iconText.TextSize = 45
            iconText.BackgroundTransparency = 1
            iconText.Parent = iconFrame

            -- Info Area
            local info = Instance.new("Frame")
            info.Size = UDim2.new(0.5, 0, 1, 0)
            info.Position = UDim2.fromOffset(130, 0)
            info.BackgroundTransparency = 1
            info.Parent = card

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, 0, 0.4, 0)
            name.Position = UDim2.fromOffset(0, 20)
            name.Text = item.Name:upper()
            name.Font = Enum.Font.FredokaOne
            name.TextColor3 = COLORS.WHITE
            name.TextSize = 32
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.BackgroundTransparency = 1
            name.Parent = info

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, 0, 0.3, 0)
            desc.Position = UDim2.fromOffset(0, 60)
            desc.Text = "ITEM ESPECIAL PREMIUM"
            desc.Font = Enum.Font.GothamBold
            desc.TextColor3 = COLORS.TEXT_DIM
            desc.TextSize = 16
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.BackgroundTransparency = 1
            desc.Parent = info

            -- Buy Area
            local buyArea = Instance.new("Frame")
            buyArea.Size = UDim2.new(0, 200, 1, 0)
            buyArea.Position = UDim2.new(1, -220, 0, 0)
            buyArea.BackgroundTransparency = 1
            buyArea.Parent = card

            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(1, 0, 0, 65)
            buyBtn.Position = UDim2.fromScale(0, 0.5)
            buyBtn.AnchorPoint = Vector2.new(0, 0.5)
            buyBtn.BackgroundColor3 = item.CurrencyType == "Robux" and COLORS.GOLD or COLORS.NEON_BLUE
            buyBtn.BackgroundTransparency = 0.1
            buyBtn.Text = item.Price .. (item.CurrencyType == "Robux" and " R$" or " CR")
            buyBtn.Font = Enum.Font.FredokaOne
            buyBtn.TextColor3 = COLORS.BG_MAIN
            buyBtn.TextSize = 24
            createCorner(buyBtn, 12)
            applyHover(buyBtn)
            buyBtn.Parent = buyArea

            if purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then
                buyBtn.Text = "LISTO"
                buyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                buyBtn.TextColor3 = COLORS.WHITE
            end

            buyBtn.MouseButton1Click:Connect(function()
                if purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then return end
                if item.CurrencyType == "Robux" then
                    game:GetService("MarketplaceService"):PromptGamePassPurchase(player, item.GamePassId)
                else
                    local res, err = BuyItem:InvokeServer(item.Id)
                    if res then
                         purchasedItems[item.Id] = true
                         buyBtn.Text = "LISTO"
                         buyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                         buyBtn.TextColor3 = COLORS.WHITE
                    else
                         buyBtn.Text = tostring(err or "ERROR")
                         task.wait(1)
                         buyBtn.Text = item.Price .. (item.CurrencyType == "Robux" and " R$" or " CR")
                    end
                end
            end)

            card.Parent = scrollingContent
        end
        scrollingContent.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
    end

    renderItems(currentCategory)
end

-- ==========================================
-- INICIALIZACIÓN Y DISPATCHER
-- ==========================================
local function populateDispatcher(board: BasePart)
    local categoryAttr = board:GetAttribute("Category")
    if categoryAttr == "Robux" then
        populateFuturisticBoard(board)
    else
        populateStandardBoard(board)
    end
end

local function setup()
    for _, board in ipairs(CollectionService:GetTagged("TiendaTag")) do
        local adornee: BasePart? = nil
        if board:IsA("BasePart") then
            adornee = board
        elseif board:IsA("Model") then
            adornee = board.PrimaryPart or board:FindFirstChild("Display") :: BasePart? or board:FindFirstChildWhichIsA("BasePart", true)
        end
        
        if adornee then populateDispatcher(adornee) end
    end
end

CollectionService:GetInstanceAddedSignal("TiendaTag"):Connect(function(inst: Instance)
    task.wait(0.5)
    local adornee: BasePart? = nil
    if inst:IsA("BasePart") then
        adornee = inst
    elseif inst:IsA("Model") then
        adornee = inst.PrimaryPart or inst:FindFirstChild("Display") :: BasePart? or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    if adornee then populateDispatcher(adornee) end
end)

player.CharacterAdded:Connect(function()
    table.clear(purchasedItems)
    task.wait(1)
    setup()
end)

task.wait(2)
setup()
