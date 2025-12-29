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
-- Asumimos que el UI ya está en PlayerGui porque lo pusiste en StarterGui
-- NOTA: Si este WaitForChild se queda pegado, es porque no has corrido el Builder
-- y movido el resultado a StarterGui.
local shopUI = PlayerGui:WaitForChild("ShopUI_Prefab")
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

-- Escuchar eventos para abrir la tienda (si existieran)
-- Por ahora, dejaremos que otro script controle la visibilidad si es necesario,
-- o agregamos un botón de apertura si el usuario lo requiere.
-- En la versión anterior había un 'ShopBoardController' que probablemente maneje la apertura.

print("✨ [Client] ShopController (Limpio) cargado.")
