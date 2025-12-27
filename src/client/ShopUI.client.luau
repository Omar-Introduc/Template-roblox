local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- State
local state = {
	selectedCategory = 'Mejoras',
	balance = { coins = 12400, gems = 85 },
	currentFloor = 42,
	streak = 15,
	status = 'PESADILLA'
}

-- Constants for Styles
local COLORS = {
	Orange = Color3.fromHex("#f97316"),
	Blue = Color3.fromHex("#3b82f6"),
	WoodDark = Color3.fromHex("#3e2723"),
	WoodLight = Color3.fromHex("#5d4037"),
	PanelBg = Color3.new(0.1, 0.1, 0.1), -- Approximate bg-white/10 on dark
	DarkOverlay = Color3.new(0,0,0),
}

-- Helper to create instances
local function create(className, properties, children)
	local instance = Instance.new(className)
	for k, v in pairs(properties or {}) do
		instance[k] = v
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	return instance
end

-- Wait for Shop Board
-- REFACTOR: Look for ShopBoard inside workspace.estructuras or workspace directly if scanned
-- The instructions say: "Actualmente busca un ShopBoard que se generaba proceduralmente. Ahora debe buscar el ShopBoard estático que yo colocaré manualmente en estructuras."
-- It is likely in workspace.estructuras.ShopBoard.

local shopBoard = nil
local maxRetries = 10
local retryCount = 0

while not shopBoard and retryCount < maxRetries do
    -- Try direct workspace (legacy fallback)
    shopBoard = workspace:FindFirstChild("ShopBoard")

    -- Try inside estructuras
    if not shopBoard then
        local estructuras = workspace:FindFirstChild("estructuras")
        if estructuras then
            shopBoard = estructuras:FindFirstChild("ShopBoard")
        end
    end

    if not shopBoard then
        retryCount += 1
        task.wait(1)
    end
end

if not shopBoard then
	warn("ShopBoard not found in Workspace or estructuras! Shop UI will not load.")
	return
end

print("ShopUI attached to: " .. shopBoard:GetFullName())

local surfaceGui = create("SurfaceGui", {
	Name = "MiningShopGui",
	Adornee = shopBoard,
	Face = Enum.NormalId.Front,
	SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	PixelsPerStud = 50, -- High resolution
	CanvasSize = Vector2.new(1200, 800), -- Match approximate layout size
	ClipsDescendants = true,
	LightInfluence = 0,
	Parent = player:WaitForChild("PlayerGui")
})

-- Main Container
local container = create("Frame", {
	Name = "Container",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.5, -- backdrop-blur simulation
	BorderSizePixel = 0,
	Parent = surfaceGui
})

-- Gradient Border Effect (Rainbow)
local stroke = create("UIStroke", {
	Thickness = 4,
	Transparency = 0,
	Parent = container
})

-- Animated Gradient for Border
local gradient = create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,0,0)),
		ColorSequenceKeypoint.new(0.14, Color3.new(1,0.5,0)),
		ColorSequenceKeypoint.new(0.28, Color3.new(1,1,0)),
		ColorSequenceKeypoint.new(0.42, Color3.new(0,1,0)),
		ColorSequenceKeypoint.new(0.57, Color3.new(0,0,1)),
		ColorSequenceKeypoint.new(0.71, Color3.new(0.29,0,0.51)),
		ColorSequenceKeypoint.new(0.85, Color3.new(0.93,0.51,0.93)),
		ColorSequenceKeypoint.new(1, Color3.new(1,0,0)),
	}),
	Rotation = 0,
	Parent = stroke
})

task.spawn(function()
	while true do
		local tween = TweenService:Create(gradient, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Rotation = 360})
		tween:Play()
		tween.Completed:Wait()
		gradient.Rotation = 0
	end
end)

-- Header
local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 100),
	BackgroundColor3 = COLORS.WoodLight,
	BorderSizePixel = 0,
	Parent = container
})

-- Wood texture overlay
create("ImageLabel", {
	BackgroundTransparency = 1,
	Image = "rbxassetid://6031091531", -- Generic wood pattern placeholder
	ImageTransparency = 0.8,
	Size = UDim2.fromScale(1, 1),
	ScaleType = Enum.ScaleType.Tile,
	TileSize = UDim2.new(0, 64, 0, 64),
	Parent = header
})

-- Bottom border of header
create("Frame", {
	Size = UDim2.new(1, 0, 0, 8),
	Position = UDim2.new(0, 0, 1, -8),
	BackgroundColor3 = COLORS.WoodDark,
	BorderSizePixel = 0,
	Parent = header
})

-- Title Area
local titleContainer = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 24, 0, 20),
	Size = UDim2.new(0.5, 0, 1, -20),
	Parent = header
})

-- Pickaxe Icon Box
local pickaxeBox = create("Frame", {
	BackgroundColor3 = Color3.fromHex("#2d1d19"),
	Size = UDim2.new(0, 60, 0, 60),
	Parent = titleContainer
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = pickaxeBox })
create("UIStroke", { Color = Color3.fromHex("#8d6e63"), Thickness = 2, Parent = pickaxeBox })
create("TextLabel", {
	Text = "⛏️", -- Fallback for lucide icon
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1,1),
	TextSize = 40,
	Parent = pickaxeBox
})

-- Title Text
local titleLabel = create("TextLabel", {
	Text = "SUMINISTROS DE ÉLITE",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 80, 0, 0),
	Size = UDim2.new(1, -80, 0, 40),
	Font = Enum.Font.GothamBlack,
	TextSize = 32,
	TextColor3 = Color3.new(1,1,1),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleContainer
})
-- Rainbow Text Effect for Title
local titleGradient = gradient:Clone()
titleGradient.Parent = titleLabel
task.spawn(function()
	while true do
		local tween = TweenService:Create(titleGradient, TweenInfo.new(2, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
		-- Simple gradient animation approximation
		-- Roblox UIGradient Offset doesn't loop perfectly for rainbow without texture tricks, but rotation works.
		-- Let's stick to Rotation for simplicity or just static color if it looks bad.
		-- Actually let's just make it colorful.
		task.wait(2)
	end
end)


-- Catalog Tag
create("TextLabel", {
	Text = " CATÁLOGO AMPLIADO ",
	BackgroundColor3 = Color3.fromHex("#ea580c"),
	TextColor3 = Color3.new(1,1,1),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Position = UDim2.new(0, 80, 0, 40),
	Size = UDim2.new(0, 150, 0, 20),
	Parent = titleContainer
}, {create("UICorner", {CornerRadius=UDim.new(0,4)})})

-- Balance Area (Top Right)
local balanceContainer = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -24, 0.5, 0),
	Size = UDim2.new(0, 200, 0, 80),
	Parent = header
})

local function createBalanceDisplay(iconText, amount, color, yPos)
	local frame = create("Frame", {
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, yPos),
		Parent = balanceContainer
	})
	create("UIStroke", {Color=Color3.new(1,1,1), Transparency=0.8, Parent=frame})

	create("TextLabel", {
		Text = iconText,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 30, 1, 0),
		TextSize = 20,
		Parent = frame
	})

	create("TextLabel", {
		Text = tostring(amount),
		TextColor3 = color,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		Parent = frame
	})
end

createBalanceDisplay("🪙", state.balance.coins, Color3.new(1, 0.8, 0), 0)
createBalanceDisplay("💎", state.balance.gems, Color3.new(0, 1, 1), 35)

-- Main Body
local body = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 100),
	Size = UDim2.new(1, 0, 1, -100),
	Parent = container
})

-- Sidebar (Categories)
local sidebar = create("Frame", {
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 0.75,
	Size = UDim2.new(0, 120, 1, 0),
	BorderSizePixel = 0,
	Parent = body
})
create("UIStroke", {Thickness=4, Color=Color3.new(1,1,1), Transparency=0.9, Parent=sidebar}) -- Border Right

-- Sidebar Buttons Container
local sidebarLayout = create("UIListLayout", {
	Padding = UDim.new(0, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Parent = sidebar
})
create("UIPadding", {PaddingTop=UDim.new(0,20), Parent=sidebar})

local itemsGrid -- Forward declaration

local function updateItems(category)
	state.selectedCategory = category
	-- Clear grid
	for _, child in ipairs(itemsGrid:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local items = ShopConfig.Items[category]
	if items then
		for _, item in ipairs(items) do
			local card = create("Frame", {
				BackgroundColor3 = Color3.fromHex("#1c1c1c"),
				Size = UDim2.new(0, 200, 0, 280), -- Fixed size for grid
				Parent = itemsGrid
			})
			-- Card Styling
			create("UIStroke", {Color=Color3.fromHex("#0a0a0a"), Thickness=2, Parent=card})
			create("Frame", { -- Bottom border thickness simulation
				BackgroundColor3 = Color3.fromHex("#0a0a0a"),
				Size = UDim2.new(1,0,0,8),
				Position = UDim2.new(0,0,1,-8),
				BorderSizePixel = 0,
				Parent = card
			})

			-- Image Area
			local imgFrame = create("Frame", {
				BackgroundColor3 = Color3.fromHex("#0a0a0a"),
				Size = UDim2.new(1, -40, 0, 140),
				Position = UDim2.new(0, 20, 0, 20),
				Parent = card
			})
			create("UIStroke", {Color=Color3.new(1,1,1), Transparency=0.9, Parent=imgFrame})

			-- Color strip
			create("Frame", {
				BackgroundColor3 = item.color,
				Size = UDim2.new(0, 8, 1, 0),
				BorderSizePixel = 0,
				Parent = imgFrame
			})

			-- Emoji/Icon
			create("TextLabel", {
				Text = item.img,
				TextSize = 60,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1,1),
				Parent = imgFrame
			})

			-- Info
			local infoFrame = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 170),
				Size = UDim2.new(1, 0, 0, 100),
				Parent = card
			})

			create("TextLabel", {
				Text = item.rarity,
				TextColor3 = item.color,
				TextSize = 12,
				Font = Enum.Font.GothamBlack,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 15),
				Parent = infoFrame
			})

			create("TextLabel", {
				Text = item.name,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0,0,0,15),
				Parent = infoFrame
			})

            create("TextLabel", {
				Text = item.effect,
				TextColor3 = Color3.new(0.6,0.6,0.6),
				TextSize = 12,
				Font = Enum.Font.Gotham,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 15),
				Position = UDim2.new(0,0,0,35),
				Parent = infoFrame
			})

			-- Buy Button
			local btnColor = (item.type == 'coins') and Color3.fromHex("#fbc02d") or Color3.fromHex("#00acc1")
			local btnText = tostring(item.price) .. (item.type == 'coins' and " ORO" or " GEMAS")

			local buyBtn = create("TextButton", {
				Text = btnText,
				BackgroundColor3 = btnColor,
				TextColor3 = (item.type == 'coins') and Color3.fromHex("#5f4b00") or Color3.new(1,1,1),
				Font = Enum.Font.GothamBlack,
				TextSize = 14,
				Size = UDim2.new(1, -40, 0, 40),
				Position = UDim2.new(0, 20, 1, -50),
				Parent = card
			})
			create("UICorner", {CornerRadius=UDim.new(0,4), Parent=buyBtn})

            buyBtn.MouseButton1Click:Connect(function()
                print("Buying " .. item.name)
                -- TODO: Add server logic for buying
            end)
		end
	end
end

-- Render Sidebar Buttons
local categoryButtons = {}
for _, cat in ipairs(ShopConfig.Categories) do
	local btn = create("TextButton", {
		Name = cat.id,
		Text = "",
		BackgroundColor3 = Color3.new(1,1,1),
		BackgroundTransparency = 0.9,
		Size = UDim2.new(0, 100, 0, 80),
		Parent = sidebar
	})

	local selectionInd = create("Frame", {
		BackgroundColor3 = Color3.new(1,1,1),
		Size = UDim2.new(0, 4, 1, 0),
		Visible = false,
		Parent = btn
	})

	-- Label
	create("TextLabel", {
		Text = cat.label,
		TextColor3 = Color3.new(1,1,1),
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,20),
		Position = UDim2.new(0,0,0.7,0),
		Parent = btn
	})

	-- Icon (Placeholder Text for now as Icons need asset ids)
	create("TextLabel", {
		Text = string.sub(cat.id, 1, 1),
		TextColor3 = Color3.new(1,1,1),
		TextSize = 24,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,40),
		Position = UDim2.new(0,0,0.2,0),
		Parent = btn
	})

	btn.MouseButton1Click:Connect(function()
		for _, b in pairs(categoryButtons) do
			b.BackgroundTransparency = 0.9
			b.Selection.Visible = false
		end
		btn.BackgroundTransparency = 0.8
		selectionInd.Visible = true
		updateItems(cat.id)
	end)

	categoryButtons[cat.id] = btn
	btn.Selection = selectionInd -- Attach for easy access
end

-- Select first category by default
if categoryButtons['Mejoras'] then
	categoryButtons['Mejoras'].BackgroundTransparency = 0.8
	categoryButtons['Mejoras'].Selection.Visible = true
end

-- Content Area
local contentArea = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 120, 0, 0),
	Size = UDim2.new(1, -370, 1, 0), -- Subtract sidebar and right panel
	ClipsDescendants = true,
	Parent = body
})

itemsGrid = create("ScrollingFrame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.new(1,1,1),
	ScrollBarImageTransparency = 0.8,
	Parent = contentArea
})
create("UIGridLayout", {
	CellSize = UDim2.new(0, 200, 0, 280),
	CellPadding = UDim2.new(0, 20, 0, 20),
	Parent = itemsGrid
})
create("UIPadding", {PaddingTop=UDim.new(0,20), PaddingLeft=UDim.new(0,20), Parent=itemsGrid})


-- Right Panel
local rightPanel = create("Frame", {
	BackgroundColor3 = Color3.new(1,1,1),
	BackgroundTransparency = 0.95,
	Position = UDim2.new(1, -250, 0, 0),
	Size = UDim2.new(0, 250, 1, 0),
	Parent = body
})
create("UIStroke", {Thickness=2, Color=Color3.new(1,1,1), Transparency=0.9, Parent=rightPanel})

-- Stats in Right Panel
local function createStatBox(parent, yPos, title, value, subValue)
    local box = create("Frame", {
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 0.25,
        Size = UDim2.new(1, -40, 0, 120),
        Position = UDim2.new(0, 20, 0, yPos),
        Parent = parent
    })
    create("UIStroke", {Color=Color3.new(1,1,1), Transparency=0.9, Parent=box})

    create("TextLabel", {
        Text = title,
        TextColor3 = COLORS.Orange,
        TextSize = 14,
        Font = Enum.Font.GothamBlack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,20),
        Position = UDim2.new(0,0,0,10),
        Parent = box
    })

    create("TextLabel", {
        Text = value,
        TextColor3 = Color3.new(1,1,1),
        TextSize = 48,
        Font = Enum.Font.GothamBlack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,60),
        Position = UDim2.new(0,0,0,30),
        Parent = box
    })

    -- Rainbow effect on value
    local grad = gradient:Clone()
    grad.Parent = box:GetChildren()[2] -- The value label
     task.spawn(function()
        while true do
            local tween = TweenService:Create(grad, TweenInfo.new(4, Enum.EasingStyle.Linear), {Rotation = 360})
            tween:Play()
            tween.Completed:Wait()
            grad.Rotation = 0
        end
    end)

    if subValue then
         create("Frame", { -- Progress bar bg
             BackgroundColor3 = Color3.new(0,0,0),
             BackgroundTransparency = 0.5,
             Size = UDim2.new(0.8, 0, 0, 10),
             Position = UDim2.new(0.1, 0, 0, 90),
             Parent = box
         }, {
             create("Frame", { -- Fill
                 BackgroundColor3 = COLORS.Orange,
                 Size = UDim2.new(0.7, 0, 1, 0),
                 BorderSizePixel = 0
             })
         })
    end
end

createStatBox(rightPanel, 20, "PISO ACTUAL", "42", true)

-- Streak Box
local streakBox = create("Frame", {
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 0.4,
    Size = UDim2.new(1, -40, 0, 80),
    Position = UDim2.new(0, 20, 0, 160),
    Parent = rightPanel
})
create("UIStroke", {Color=Color3.new(1,1,1), Transparency=0.9, Parent=streakBox})
create("TextLabel", {
    Text = "RACHA",
    TextColor3 = COLORS.Orange,
    TextSize = 12,
    Font = Enum.Font.GothamBlack,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(1, -20, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = streakBox
})
create("TextLabel", {
    Text = "¡Has completado 15 saltos sin fallar!",
    TextColor3 = Color3.new(0.7,0.7,0.7),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 30),
    Size = UDim2.new(1, -20, 0, 40),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = streakBox
})


-- Initial Load
updateItems('Mejoras')
