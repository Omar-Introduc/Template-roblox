-- src/server/Builders/ShopBuilder.luau
local ShopBuilder = {}
ShopBuilder.Name = "Tienda Glassmorphism"

function ShopBuilder.Build()
	-- 1. Crear el ScreenGui o SurfaceGui contenedor
	-- Nota: Lo ponemos en StarterGui para que puedas copiarlo facilmente
	local gui = Instance.new("ScreenGui")
	gui.Name = "ShopUI_Prefab"
	gui.ResetOnSpawn = false
	gui.Parent = game:GetService("StarterGui") -- Destino temporal

	-- 2. Lógica visual (Extraída de tu ShopController original)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.5, 0, 0.7, 0) -- Ajustado para pantalla
	mainFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainFrame.BackgroundTransparency = 0.15 -- Glassmorphism
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	-- UIStroke (Borde Neón)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 255, 255)
	stroke.Thickness = 4
	stroke.Parent = mainFrame

	-- UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 230, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 200))
	})
	gradient.Rotation = 45
	gradient.Parent = mainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = mainFrame

	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn
	closeBtn.Parent = mainFrame

	-- Contenedor de Items (ScrollingFrame)
	local content = Instance.new("ScrollingFrame")
	content.Name = "ItemsContainer"
	content.Size = UDim2.new(1, -20, 1, -80)
	content.Position = UDim2.new(0, 10, 0, 60)
	content.BackgroundTransparency = 1
	content.Parent = mainFrame

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 150, 0, 200)
	layout.Parent = content

	-- Creamos UN item de ejemplo (Template) para clonar después
	local itemTemplate = Instance.new("Frame")
	itemTemplate.Name = "ItemTemplate"
	itemTemplate.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	itemTemplate.BackgroundTransparency = 0.5
	itemTemplate.Parent = content

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 10)
	itemCorner.Parent = itemTemplate

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.2, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = itemTemplate

	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyButton"
	buyBtn.Size = UDim2.new(0.8, 0, 0.2, 0)
	buyBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
	buyBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	buyBtn.Text = "Buy"
	buyBtn.Parent = itemTemplate
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = buyBtn

	print("   -> UI creada en StarterGui. ¡Ahora guárdala como Prefab!")
end

return ShopBuilder
