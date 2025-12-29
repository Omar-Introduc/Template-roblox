-- src/client/ShopController.client.luau
-- ¡LÓGICA PURA! Sin Instance.new() visuales.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")
local ShopConfig = require(ReplicatedStorage.Shared.ShopConfig)

-- Referencia al Prefab ya existente (que creaste con el Builder)
local shopUI = PlayerGui:WaitForChild("ShopUI_Prefab", 5)

if not shopUI then
	warn("⚠️ [ShopController] 'ShopUI_Prefab' no encontrado en PlayerGui. Ejecuta 'MasterBuilder' para generarlo.")
	return
end

local mainFrame = shopUI:WaitForChild("MainFrame")
local container = mainFrame:WaitForChild("ItemsContainer")
local closeBtn = mainFrame:FindFirstChild("CloseButton")

local function setupItemLogic(itemFrame, itemData)
	local buyBtn = itemFrame:FindFirstChild("BuyButton")
	if not buyBtn then return end

	-- Lógica de interacción
	buyBtn.MouseButton1Click:Connect(function()
		local success, msg = BuyItemFunction:InvokeServer(itemData.Id)
		if success then
			print("Compra exitosa!")
		else
			warn("Fallo: " .. msg)
			-- Feedback visual de error
			local originalText = buyBtn.Text
			local originalColor = buyBtn.TextColor3

			buyBtn.Text = "SIN SALDO" -- O "ERROR"
			buyBtn.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rojo

			task.delay(1, function()
				if buyBtn then
					buyBtn.Text = originalText
					buyBtn.TextColor3 = originalColor
				end
			end)
		end
	end)
end

-- Aquí solo rellenas datos, no creas estilos
local function populateShop()
	-- Buscar el template que dejamos en el prefab
	local template = container:FindFirstChild("ItemTemplate")
	if not template then return end
	template.Visible = false -- Ocultar el original

	for _, category in pairs(ShopConfig.Categories) do
		for _, item in ipairs(category.Items) do
			local newItem = template:Clone()
			newItem.Name = item.Id
			newItem.Visible = true
			newItem.Parent = container

			-- Asignar datos (Color, Texto) al prefab existente
			newItem.BackgroundColor3 = item.Color
			-- (Asumiendo que el prefab tiene un TextLabel llamado 'Title')
			if newItem:FindFirstChild("Title") then
				newItem.Title.Text = item.Name
			end

			setupItemLogic(newItem, item)
		end
	end
end

local function toggleShop(visible)
	mainFrame.Visible = visible
end

if closeBtn then
	closeBtn.MouseButton1Click:Connect(function()
		toggleShop(false)
	end)
end

-- Inicialización
populateShop()
toggleShop(false) -- Empezar cerrado

print("✨ [Client] ShopController (Limpio) cargado.")
