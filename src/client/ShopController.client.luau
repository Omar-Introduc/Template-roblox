-- src/client/ShopController.client.luau
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")
local ShopConfig = require(ReplicatedStorage.Shared.ShopConfig)

-- Require our UI tools
-- Locate UIComponents relative to this script (assumed sibling in PlayerScripts)
local UIComponentsModule = script.Parent:WaitForChild("UIComponents")
local UIComponents = require(UIComponentsModule)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

print("🛒 ShopController: Initializing...")

-- State
local shopGui: ScreenGui?
local contentFrame: Frame?
local currentCategory = "Movement" -- Default
local itemContainer: ScrollingFrame?

-- Function to handle purchase
local function purchaseItem(itemId: string, price: number, button: TextButton)
	local originalText = button.Text
	local originalColor = button.BackgroundColor3

	button.Text = "..."
	button.BackgroundColor3 = UITheme.Colors.ButtonDisabled

	local success, msg = BuyItemFunction:InvokeServer(itemId)

	if success then
		button.Text = "OWNED"
		button.BackgroundColor3 = UITheme.Colors.AccentGreen
		-- Play success sound/effect here if possible
		task.delay(1, function()
			button.Text = "BUY" -- Or keep as owned?
			-- Usually we check ownership, but let's reset for now or check attributes
			-- Ideally we update the button state based on ownership
			button.BackgroundColor3 = originalColor
		end)
	else
		button.Text = "NO FUNDS"
		button.BackgroundColor3 = UITheme.Colors.AccentRed
		task.delay(1.5, function()
			button.Text = originalText
			button.BackgroundColor3 = originalColor
		end)
	end
end

-- Render Items for a Category
local function renderItems(categoryKey: string)
	if not itemContainer then return end

	-- Clear existing
	for _, child in pairs(itemContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local categoryData = ShopConfig.Categories[categoryKey]
	if not categoryData then return end

	for _, item in ipairs(categoryData.Items) do
		-- Item Card
		local card = UIComponents.CreateContainer({
			Name = item.Id,
			Size = UDim2.new(0, 160, 0, 200), -- Card Size
			BackgroundColor3 = UITheme.Colors.BackgroundItem,
			Parent = itemContainer
		})

		-- Color Strip / Image Placeholder
		local strip = Instance.new("Frame")
		strip.Size = UDim2.new(1, 0, 0, 80)
		strip.BackgroundColor3 = item.Color or Color3.fromRGB(100, 100, 100)
		strip.BorderSizePixel = 0

		-- Round top corners only? Hard with UICorner on parent.
		-- Let's just put it inside and let parent clip?
		-- UICorner on parent clips descendants? Yes if ClipDescendants = true?
		-- Actually Frame doesn't clip by default unless ClipsDescendants is true.
		card.ClipsDescendants = true
		strip.Parent = card

		-- Title
		UIComponents.CreateLabel({
			Text = item.Name,
			Size = UDim2.new(1, -10, 0, 40),
			Position = UDim2.new(0, 5, 0, 85),
			Font = UITheme.Fonts.Bold,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card
		})

		-- Price
		local priceText = item.Price > 0 and ("$" .. item.Price) or "FREE"
		if item.CurrencyType == "Robux" then priceText = "R$ " .. item.Price end

		UIComponents.CreateLabel({
			Text = priceText,
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 0, 120),
			TextColor3 = UITheme.Colors.TextHighlight,
			Font = UITheme.Fonts.Body,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card
		})

		-- Buy Button
		local btnText = "BUY"
		local btnColor = UITheme.Colors.ButtonDefault

		-- Check ownership (if possible via attributes)
		if Player:GetAttribute("Owns_" .. item.Id) then
			btnText = "OWNED"
			btnColor = UITheme.Colors.ButtonDisabled
		end

		UIComponents.CreateButton({
			Text = btnText,
			Size = UDim2.new(0, 100, 0, 30),
			Position = UDim2.new(0.5, -50, 1, -40),
			BackgroundColor3 = btnColor,
			Parent = card,
			Callback = function()
				purchaseItem(item.Id, item.Price, nil) -- Passing button is tricky inside callback closure if not ref'd
				-- We need the button instance. The CreateButton returns it.
			end
		})
		-- Hack to get button instance for callback:
		local btn = card:FindFirstChild("Button") :: TextButton
		-- Reconnect callback properly with button ref
		btn.MouseButton1Click:Connect(function()
             -- Only allow buy if not owned or consumable
             -- Consumables: Multipliers, Health?
             -- For now just run purchase logic
             purchaseItem(item.Id, item.Price, btn)
		end)
	end
end

-- Create the Shop UI
local function createShopUI()
	if shopGui then shopGui:Destroy() end

	local gui, content = UIComponents.CreateModal({
		Title = "SHOP",
		Size = UDim2.new(0, 800, 0, 500),
		OnClose = function()
			shopGui.Enabled = false
		end,
		Parent = PlayerGui
	})
	shopGui = gui
	contentFrame = content

	-- Categories Sidebar
	local sidebar = UIComponents.CreateContainer({
		Name = "Sidebar",
		Size = UDim2.new(0, 200, 1, 0),
		BackgroundColor3 = UITheme.Colors.BackgroundPanel,
		Parent = contentFrame
	})

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.Padding = UDim.new(0, 5)
	sidebarLayout.Parent = sidebar

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = sidebar

	-- Category Buttons
	local categories = {"Movement", "Aero", "Survival", "Economy", "Beasts", "Robux"}

	for _, cat in ipairs(categories) do
		UIComponents.CreateButton({
			Name = cat,
			Text = ShopConfig.Categories[cat].Title,
			Size = UDim2.new(1, -20, 0, 40),
			BackgroundColor3 = (cat == currentCategory) and UITheme.Colors.AccentCyan or UITheme.Colors.ButtonDefault,
			Parent = sidebar,
			Callback = function()
				currentCategory = cat
				renderItems(cat)
				-- Update button colors? Needs tracking.
			end
		})
	end

	-- Items Grid Area
	local itemsArea = Instance.new("ScrollingFrame")
	itemsArea.Name = "ItemsArea"
	itemsArea.Size = UDim2.new(1, -210, 1, 0)
	itemsArea.Position = UDim2.new(0, 210, 0, 0)
	itemsArea.BackgroundTransparency = 1
	itemsArea.BorderSizePixel = 0
	itemsArea.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto sizing needed
	itemsArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemsArea.Parent = contentFrame
	itemContainer = itemsArea

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 160, 0, 200)
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.Parent = itemsArea

	local areaPadding = Instance.new("UIPadding")
	areaPadding.PaddingTop = UDim.new(0, 10)
	areaPadding.PaddingLeft = UDim.new(0, 10)
	areaPadding.Parent = itemsArea

	-- Render initial category
	renderItems(currentCategory)

	-- Start hidden
	shopGui.Enabled = false
end

-- Open Shop Button (HUD)
local openShopBtn = UIComponents.CreateButton({
	Text = "SHOP",
	Size = UDim2.new(0, 100, 0, 40),
	Position = UDim2.new(0, 20, 0.5, 0), -- Left side
	BackgroundColor3 = UITheme.Colors.AccentPurple,
	Parent = PlayerGui:WaitForChild("GameHUD") -- Attach to HUD
})
openShopBtn.Name = "OpenShopButton"
openShopBtn.MouseButton1Click:Connect(function()
	if not shopGui then createShopUI() end
	shopGui.Enabled = true
end)

createShopUI()

print("✨ ShopController: UI Built.")
