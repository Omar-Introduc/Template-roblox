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
    sg.AlwaysOnTop = true
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

    -- Título simple arriba
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = (category and category.Title or tostring(categoryKey)):upper()
    title.Font = Enum.Font.FredokaOne
    title.TextColor3 = COLORS.WHITE
    title.TextSize = 40
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
    sg.AlwaysOnTop = true
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
    title.Size = UDim2.new(0.4, 0, 1, 0)
    title.Text = "STELLAR PREMIUM"
    title.Font = Enum.Font.FredokaOne
    title.TextColor3 = COLORS.WHITE
    title.TextSize = 40
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = topBar

    local balanceLabel = Instance.new("TextLabel")
    balanceLabel.Size = UDim2.new(0.4, 0, 1, 0)
    balanceLabel.Position = UDim2.fromScale(0.6, 0)
    local balVal = player:GetAttribute("Coins")
    balanceLabel.Text = string.format("CR: %d", if typeof(balVal) == "number" then balVal else 0)
    balanceLabel.Font = Enum.Font.GothamBold
    balanceLabel.TextColor3 = COLORS.NEON_BLUE
    balanceLabel.TextSize = 30
    balanceLabel.TextXAlignment = Enum.TextXAlignment.Right
    balanceLabel.BackgroundTransparency = 1
    balanceLabel.Parent = topBar
    
    player:GetAttributeChangedSignal("Coins"):Connect(function()
        local newVal = player:GetAttribute("Coins")
        balanceLabel.Text = string.format("CR: %d", if typeof(newVal) == "number" then newVal else 0)
    end)

    -- 3. SIDEBAR (Categories)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 180, 1, -120)
    sidebar.Position = UDim2.fromOffset(20, 100)
    sidebar.BackgroundColor3 = COLORS.BG_GLASS
    sidebar.BackgroundTransparency = 0.5
    createCorner(sidebar, 15)
    sidebar.Parent = main

    local scrollingSidebar = Instance.new("ScrollingFrame")
    scrollingSidebar.Size = UDim2.new(1, -10, 1, -20)
    scrollingSidebar.Position = UDim2.fromOffset(5, 10)
    scrollingSidebar.BackgroundTransparency = 1
    scrollingSidebar.ScrollBarThickness = 2
    scrollingSidebar.CanvasSize = UDim2.new(0,0,2,0)
    scrollingSidebar.Parent = sidebar

    local sideList = Instance.new("UIListLayout")
    sideList.Padding = UDim.new(0, 10)
    sideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideList.Parent = scrollingSidebar

    -- 4. CONTENT AREA (Items)
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(1, -230, 1, -120)
    content.Position = UDim2.fromOffset(210, 100)
    content.BackgroundTransparency = 1
    content.Parent = main

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.3, 0, 0.45, 0)
    grid.CellPadding = UDim2.new(0.03, 0, 0.03, 0)
    grid.Parent = content

    local catAttrVal = board:GetAttribute("Category")
    local currentCategory: string = if typeof(catAttrVal) == "string" then catAttrVal else "Robux"

    local function renderItems(catKey: string)
        content:ClearAllChildren()
        grid.Parent = content
        
        local category = ShopConfig.Categories[catKey]
        if not category then return end
        
        for _, item in ipairs(category.Items) do
            local card = Instance.new("Frame")
            card.BackgroundColor3 = COLORS.BG_GLASS
            card.BackgroundTransparency = 0.4
            createCorner(card, 15)
            createStroke(card, item.CurrencyType == "Robux" and COLORS.GOLD or COLORS.NEON_BLUE, 2)
            
            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -10, 0.4, 0)
            name.Position = UDim2.fromOffset(5, 5)
            name.Text = item.Name
            name.Font = Enum.Font.GothamBold
            name.TextColor3 = COLORS.WHITE
            name.TextSize = 18
            name.TextWrapped = true
            name.Parent = card

            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
            buyBtn.Position = UDim2.fromScale(0.1, 0.7)
            buyBtn.BackgroundColor3 = COLORS.NEON_BLUE
            buyBtn.Text = item.Price .. (item.CurrencyType == "Robux" and " R$" or " CR")
            buyBtn.Font = Enum.Font.FredokaOne
            buyBtn.TextColor3 = COLORS.WHITE
            buyBtn.TextSize = 14
            createCorner(buyBtn, 8)
            applyHover(buyBtn)
            buyBtn.Parent = card

            if purchasedItems[item.Id] or player:GetAttribute("Owns_" .. item.Id) == true then
                buyBtn.Text = "LISTO"
                buyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
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
                    else
                         buyBtn.Text = tostring(err or "ERROR")
                         task.wait(1)
                         buyBtn.Text = item.Price .. (item.CurrencyType == "Robux" and " R$" or " CR")
                    end
                end
            end)

            card.Parent = content
        end
    end

    -- Sidebar Buttons
    for key, catData in pairs(ShopConfig.Categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.BackgroundColor3 = (key == currentCategory) and COLORS.NEON_BLUE or COLORS.BG_GLASS
        btn.Text = tostring(catData.Title or key)
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = COLORS.WHITE
        createCorner(btn, 10)
        btn.Parent = scrollingSidebar
        btn.MouseButton1Click:Connect(function()
            currentCategory = key
            renderItems(key)
        end)
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
