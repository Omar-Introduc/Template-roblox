-- ShopUI (Client) - MEJORADO Y PROFESIONAL
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ItemsData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemsData"))
local CrystalConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CrystalConfig"))
local purchaseRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PurchaseItem")

-- Configuration
local COLORS = {
	Background = Color3.fromRGB(15, 15, 20),
	Overlay = Color3.fromRGB(30, 30, 40),
	Accent = CrystalConfig.Colors.Default, -- Cyan
	Success = Color3.fromRGB(0, 255, 150),
	Text = Color3.fromRGB(240, 240, 240),
	Close = Color3.fromRGB(255, 80, 80),
}

-- 1. Create Main Shop Menu
local screenGui = playerGui:FindFirstChild("ShopMenu") or Instance.new("ScreenGui", playerGui)
screenGui.Name = "ShopMenu"
screenGui.ResetOnSpawn = false

-- Shop Main Frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "MainFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Size = UDim2.fromScale(0.4, 0.55)
shopFrame.Position = UDim2.fromScale(0.5, 0.5)
shopFrame.BackgroundColor3 = COLORS.Background
shopFrame.BackgroundTransparency = 0.15
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ClipsDescendants = false -- Allow glow effect if added later
shopFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = shopFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = COLORS.Accent
stroke.Transparency = 0.5
stroke.Parent = shopFrame

-- Title Section
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "TIENDA DE OBJETOS"
title.Size = UDim2.fromScale(0.9, 0.15)
title.Position = UDim2.fromScale(0.05, 0.05)
title.TextColor3 = COLORS.Text
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.BackgroundTransparency = 1
title.Parent = shopFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Text = "X"
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = COLORS.Close
closeBtn.TextColor3 = COLORS.Text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.Parent = shopFrame

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(1, 0)
cCorner.Parent = closeBtn

-- Content Layout
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "ItemsList"
scrollingFrame.Size = UDim2.fromScale(0.9, 0.75)
scrollingFrame.Position = UDim2.fromScale(0.05, 0.22)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.ScrollBarImageColor3 = COLORS.Accent
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.Parent = shopFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.48, 0, 0, 120)
gridLayout.CellPadding = UDim2.fromScale(0.04, 0.04)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollingFrame

-- HUD Stats (Gems & Streak)
local gameHUD = playerGui:FindFirstChild("GameHUD") or Instance.new("ScreenGui", playerGui)
gameHUD.Name = "GameHUD"
gameHUD.ResetOnSpawn = false

local statsFrame = gameHUD:FindFirstChild("StatsFrame") or Instance.new("Frame")
if not gameHUD:FindFirstChild("StatsFrame") then
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.fromScale(0.2, 0.12)
	statsFrame.Position = UDim2.fromScale(0.02, 0.02)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = gameHUD
end

local gemLabel = statsFrame:FindFirstChild("GemLabel") or Instance.new("TextLabel")
if not statsFrame:FindFirstChild("GemLabel") then
	gemLabel.Name = "GemLabel"
	gemLabel.Size = UDim2.fromScale(1, 0.5)
	gemLabel.Text = "💎 Gems: 0"
	gemLabel.TextColor3 = Color3.new(1, 1, 0)
	gemLabel.Font = Enum.Font.GothamBold
	gemLabel.TextXAlignment = Enum.TextXAlignment.Left
	gemLabel.TextScaled = true
	gemLabel.BackgroundTransparency = 1
	gemLabel.Parent = statsFrame
end

local streakLabel = statsFrame:FindFirstChild("StreakLabel") or Instance.new("TextLabel")
if not statsFrame:FindFirstChild("StreakLabel") then
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.fromScale(1, 0.4)
	streakLabel.Position = UDim2.fromScale(0, 0.5)
	streakLabel.Text = "🔥 Streak: 0"
	streakLabel.TextColor3 = Color3.new(1, 0.5, 0)
	streakLabel.Font = Enum.Font.GothamBold
	streakLabel.TextXAlignment = Enum.TextXAlignment.Left
	streakLabel.TextScaled = true
	streakLabel.BackgroundTransparency = 1
	streakLabel.Parent = statsFrame
end

-- 2. Functions & Interactions
local function updateStats()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local gems = ls:WaitForChild("Gems")
		gems:GetPropertyChangedSignal("Value"):Connect(function()
			gemLabel.Text = "💎 Gems: " .. gems.Value
		end)
		gemLabel.Text = "💎 Gems: " .. gems.Value
	end
	
	player:GetAttributeChangedSignal("Streak"):Connect(function()
		local streak = player:GetAttribute("Streak") or 0
		local multiplier = 1
		if streak >= 20 then multiplier = 2
		elseif streak >= 10 then multiplier = 1.5 end
		streakLabel.Text = string.format("🔥 Streak: %d (%.1fx)", streak, multiplier)
		
		TweenService:Create(streakLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = UDim2.fromScale(1.1, 0.45)}):Play()
	end)
end
task.spawn(updateStats)

local shopDebounce = false
local function toggleShop(open)
	if shopDebounce then return end
	shopDebounce = true
	
	if open then
		shopFrame.Visible = true
		shopFrame.Size = UDim2.fromScale(0, 0)
		shopFrame.BackgroundTransparency = 1
		shopFrame.Position = UDim2.fromScale(0.5, 0.5)
		
		local tween = TweenService:Create(shopFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.4, 0.55),
			BackgroundTransparency = 0.15
		})
		tween:Play()
		tween.Completed:Connect(function() shopDebounce = false end)
	else
		local tween = TweenService:Create(shopFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			shopFrame.Visible = false
			shopDebounce = false
		end)
	end
end

closeBtn.MouseButton1Click:Connect(function()
	toggleShop(false)
end)

-- Create Item Cards
for _, item in ipairs(ItemsData.Powerups) do
	local card = Instance.new("Frame")
	card.Name = item.Id
	card.BackgroundColor3 = COLORS.Overlay
	card.Parent = scrollingFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 1
	cardStroke.Color = COLORS.Accent
	cardStroke.Transparency = 0.8
	cardStroke.Parent = card

	local itemName = Instance.new("TextLabel")
	itemName.Text = item.Name
	itemName.Size = UDim2.fromScale(0.9, 0.25)
	itemName.Position = UDim2.fromScale(0.05, 0.1)
	itemName.TextColor3 = COLORS.Text
	itemName.Font = Enum.Font.GothamBold
	itemName.TextScaled = true
	itemName.BackgroundTransparency = 1
	itemName.Parent = card

	local itemDesc = Instance.new("TextLabel")
	itemDesc.Text = item.Description
	itemDesc.Size = UDim2.fromScale(0.9, 0.3)
	itemDesc.Position = UDim2.fromScale(0.05, 0.35)
	itemDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
	itemDesc.Font = Enum.Font.Gotham
	itemDesc.TextScaled = true
	itemDesc.BackgroundTransparency = 1
	itemDesc.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyButton"
	buyBtn.Text = "💎 " .. item.Price
	buyBtn.Size = UDim2.fromScale(0.8, 0.25)
	buyBtn.Position = UDim2.fromScale(0.1, 0.68)
	buyBtn.BackgroundColor3 = COLORS.Accent
	buyBtn.TextColor3 = COLORS.Background
	buyBtn.Font = Enum.Font.GothamBlack
	buyBtn.TextSize = 18
	buyBtn.Parent = card

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = buyBtn

	-- Interactions
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.Success, 
			Size = UDim2.fromScale(0.85, 0.28),
			Position = UDim2.fromScale(0.075, 0.665)
		}):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.Accent, 
			Size = UDim2.fromScale(0.8, 0.25),
			Position = UDim2.fromScale(0.1, 0.68)
		}):Play()
	end)

	buyBtn.MouseButton1Click:Connect(function()
		purchaseRemote:FireServer(item.Id)
		
		-- Feedback
		local originalColor = buyBtn.BackgroundColor3
		buyBtn.BackgroundColor3 = Color3.new(1, 1, 1)
		task.wait(0.1)
		buyBtn.BackgroundColor3 = originalColor
	end)
end

-- Level 1 Popup Logic
local hasShowedPopup = false
local function checkLevelPopup()
	local ls = player:WaitForChild("leaderstats", 10)
	if not ls then return end
	local stage = ls:WaitForChild("Stage")
	
	local function onStageChanged()
		if stage.Value == 0 and not hasShowedPopup then
			hasShowedPopup = true
			task.wait(2) -- Un poco más de tiempo para que cargue el mundo
			toggleShop(true)
		end
	end
	
	stage:GetPropertyChangedSignal("Value"):Connect(onStageChanged)
	onStageChanged()
end
task.spawn(checkLevelPopup)

-- 3D Floating Sign Animation & Interaction
local function setupPhysicalSign(sign)
	print("🛠️ [CLIENT] Configurando anuncio físico interactivo: " .. sign.Name)
	-- 1. Bobbing Animation
	local startPos = sign.Position
	local info = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local goal = {Position = startPos + Vector3.new(0, 1.5, 0)}
	TweenService:Create(sign, info, goal):Play()
	
	-- 2. Click Interaction (Main Open Shop)
	local gui = sign:WaitForChild("ShopDisplay", 5)
	if not gui then return end
	local frame = gui:WaitForChild("Frame", 5)
	if not frame then return end
	
	-- Main CTA button opens the 2D shop
	local mainBtn = frame:FindFirstChild("BuyButton", true)
	if mainBtn then
		mainBtn.MouseButton1Click:Connect(function()
			toggleShop(true)
		end)
	end

	-- 3. News Ticker Logic
	local newsFlash = frame:FindFirstChild("NewsFlash")
	local messages = {
		"🚨 ¡EL VOLCÁN DEL NIVEL 3 ESTÁ ACTIVÁNDOSE! 🚨",
		"💎 ¡CRISTALES DOBLES EN EL NIVEL 2 HOY! 💎",
		"📰 REPORTE: El 90% de los jugadores caen al agua.",
		"🛒 ¡OFERTA! Mejoras baratas aquí mismo."
	}

	task.spawn(function()
		local i = 1
		while sign.Parent do
			if newsFlash then
				-- Cambiar mensaje
				newsFlash.Text = messages[i]
				i = (i % #messages) + 1
				
				-- Efecto de parpadeo visual
				for _ = 1, 3 do
					newsFlash.Visible = false
					task.wait(0.2)
					newsFlash.Visible = true
					task.wait(0.2)
				end
			end
			task.wait(5)
		end
	end)
end

-- Check current and future signs
for _, child in ipairs(game.Workspace:GetChildren()) do
	if child.Name == "FloatingShopSign" then
		task.spawn(setupPhysicalSign, child)
	end
end

game.Workspace.ChildAdded:Connect(function(child)
	if child.Name == "FloatingShopSign" then
		task.spawn(setupPhysicalSign, child)
	end
end)

-- Keybind Toggle
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		toggleShop(not shopFrame.Visible)
	end
end)

print("🛒 ShopMenu: Active. Press 'M' to toggle.")
