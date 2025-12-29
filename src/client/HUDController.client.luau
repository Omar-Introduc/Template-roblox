-- src/client/HUDController.client.luau
--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Esperar a que se carguen los leaderstats
local leaderstats = player:WaitForChild("leaderstats", 10)
local crStat = leaderstats and leaderstats:WaitForChild("CR", 10) --[[@as NumberValue]]

if not crStat then
	warn("HUDController: No se encontró 'leaderstats' o 'CR'. El HUD no se iniciará.")
	return
end

-- Crear la Interfaz (ScreenGui)
local gui = Instance.new("ScreenGui")
gui.Name = "MoneyHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Crear el contenedor/fondo (Money)
local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyContainer"
moneyFrame.Size = UDim2.new(0, 200, 0, 50)
moneyFrame.Position = UDim2.new(0, 20, 1, -70) -- Esquina inferior izquierda
moneyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
moneyFrame.BackgroundTransparency = 0.5
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = moneyFrame

-- Texto del dinero
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "ValueLabel"
moneyLabel.Size = UDim2.new(1, -20, 1, 0)
moneyLabel.Position = UDim2.new(0, 10, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.FredokaOne
moneyLabel.TextSize = 24
moneyLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- Cian Neón
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Text = "CR: " .. tostring(crStat.Value)
moneyLabel.Parent = moneyFrame

-- Buffs Container (Barra de Efectos Activos)
local buffsContainer = Instance.new("Frame")
buffsContainer.Name = "BuffsContainer"
buffsContainer.Size = UDim2.new(0, 400, 0, 40)
buffsContainer.Position = UDim2.new(0, 20, 1, -120) -- Arriba del dinero
buffsContainer.BackgroundTransparency = 1
buffsContainer.Parent = gui

local buffsLayout = Instance.new("UIListLayout")
buffsLayout.FillDirection = Enum.FillDirection.Horizontal
buffsLayout.SortOrder = Enum.SortOrder.LayoutOrder
buffsLayout.Padding = UDim.new(0, 10)
buffsLayout.Parent = buffsContainer

-- Cache de labels para no recrear
local activeBuffLabels = {}

-- Función para actualizar el dinero
local function updateMoney()
	moneyLabel.Text = "CR: " .. tostring(crStat.Value)
end
crStat.Changed:Connect(updateMoney)
updateMoney()

-- Función auxiliar para formatear tiempo
local function formatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

-- Mapa de nombres bonitos
local buffNames = {
	["Buff_Fly_End"] = "VUELO",
	["Buff_God_End"] = "INMORTAL",
	["Buff_Multiplier_End"] = "PUNTOS X2",
	["Buff_Gravity_End"] = "GRAVEDAD",
	["Buff_DoubleJump"] = "DOBLE SALTO"
}

-- Update Buffs loop
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local now = os.time()
	local attributes = character:GetAttributes()
	local foundBuffs = {}

	for name, val in pairs(attributes) do
		if string.sub(name, 1, 5) == "Buff_" then
			-- Determinar si mostrar
			local timeLeft = 0
			local isTemp = false

			if type(val) == "number" then
				-- Timestamp
				if val > now then
					timeLeft = val - now
					isTemp = true
				else
					continue -- Expirado
				end
			elseif val == true then
				-- Permanente
			end

			foundBuffs[name] = true

			-- Crear/Actualizar UI
			local label = activeBuffLabels[name]
			if not label then
				local frame = Instance.new("Frame")
				frame.Name = name
				frame.Size = UDim2.new(0, 120, 0, 30)
				frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				frame.BackgroundTransparency = 0.6

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 6)
				corner.Parent = frame

				label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamBold
				label.TextColor3 = Color3.new(1, 1, 1)
				label.TextSize = 14
				label.Parent = frame

				frame.Parent = buffsContainer
				activeBuffLabels[name] = label -- Guardamos la referencia al Label
			end

			-- Actualizar Texto
			local displayName = buffNames[name] or name
			if isTemp then
				label.Text = displayName .. " " .. formatTime(timeLeft)
			else
				label.Text = displayName
			end
		end
	end

	-- Limpiar UI de buffs que ya no existen
	for name, label in pairs(activeBuffLabels) do
		if not foundBuffs[name] then
			label.Parent:Destroy() -- Destruir el Frame contenedor
			activeBuffLabels[name] = nil
		end
	end
end)

print("HUDController: Interfaz actualizada cargada.")
