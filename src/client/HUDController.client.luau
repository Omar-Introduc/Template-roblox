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
		-- Whitelist/Filter logic
		local isBuff = string.sub(name, 1, 5) == "Buff_"
		local isMultiplier = name == "PointMultiplier"
		local isShield = name == "HasShield"
		local isDoubleJump = name == "Owns_DoubleJump"
		
		if isBuff or isMultiplier or isShield or isDoubleJump then
			local timeLeft = 0
			local isTimer = false
			local displayValue = ""

			if type(val) == "number" then
				-- Check if it is a Timer (ends in _End)
				if string.sub(name, -4) == "_End" then
					if val > now then
						timeLeft = val - now
						isTimer = true
					else
						continue -- Expired timer
					end
				else
					-- It's a Stat (Speed, Jump, Multiplier)
					displayValue = tostring(val)
					if isMultiplier then displayValue = "x" .. displayValue end
				end
			elseif val == true then
				-- Permanent / Boolean
				displayValue = "ON"
			end

			foundBuffs[name] = true

			-- Crear/Actualizar UI
			local label = activeBuffLabels[name]
			if not label then
				local frame = Instance.new("Frame")
				frame.Name = name
				frame.Size = UDim2.new(0, 140, 0, 30)
				frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				frame.BackgroundTransparency = 0.6
				
				-- Gradient (Optional polish)
				local grad = Instance.new("UIGradient")
				grad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(40,40,40)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
				}
				grad.Parent = frame

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 6)
				corner.Parent = frame

				label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -10, 1, 0)
				label.Position = UDim2.new(0, 5, 0, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamBold
				label.TextColor3 = Color3.new(1, 1, 1)
				label.TextSize = 14
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = frame

				frame.Parent = buffsContainer
				activeBuffLabels[name] = label
			end

			-- Custom Naming Logic
			local cleanName = name
			if buffNames[name] then
				cleanName = buffNames[name]
			elseif isMultiplier then
				cleanName = "MULTIPLIER"
			elseif string.sub(name, 1, 5) == "Buff_" then
				cleanName = string.sub(name, 6):gsub("_End", "")
			end
			
			-- Final Text Logic
			if isTimer then
				label.Text = cleanName .. " " .. formatTime(timeLeft)
				label.TextColor3 = Color3.fromRGB(255, 200, 50) -- Orange/Yellow for timers
			else
				label.Text = cleanName .. " " .. displayValue
				label.TextColor3 = Color3.fromRGB(50, 255, 100) -- Green for active stats
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
