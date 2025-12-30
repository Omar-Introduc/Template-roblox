-- src/client/HUDController.client.luau
--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer :: Player

if not player then
	return
end

-- Esperar a que se carguen los leaderstats
local leaderstats = player:WaitForChild("leaderstats", 10) :: Folder?
if not leaderstats then
	warn("HUDController: No se encontró 'leaderstats'. El HUD no se iniciará.")
	return
end

local crStatInstance = (leaderstats :: Folder):WaitForChild("CR", 10)

if not crStatInstance or not crStatInstance:IsA("IntValue") then
	warn("HUDController: No se encontró 'leaderstats' o 'CR'. El HUD no se iniciará.")
	return
end

local crStat = crStatInstance :: IntValue

-- Crear la Interfaz (ScreenGui)
local gui = Instance.new("ScreenGui") :: ScreenGui
gui.Name = "MoneyHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui") :: PlayerGui

-- Crear el contenedor/fondo (Money)
local moneyFrame = Instance.new("Frame") :: Frame
moneyFrame.Name = "MoneyContainer"
moneyFrame.Size = UDim2.new(0, 200, 0, 50)
moneyFrame.Position = UDim2.new(0, 20, 1, -70) -- Esquina inferior izquierda
moneyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
moneyFrame.BackgroundTransparency = 0.5
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = gui

local uiCorner = Instance.new("UICorner") :: UICorner
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = moneyFrame

-- Texto del dinero
local moneyLabel = Instance.new("TextLabel") :: TextLabel
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
local buffsContainer = Instance.new("Frame") :: Frame
buffsContainer.Name = "BuffsContainer"
buffsContainer.Size = UDim2.new(0, 400, 0, 40)
buffsContainer.Position = UDim2.new(0, 20, 1, -120) -- Arriba del dinero
buffsContainer.BackgroundTransparency = 1
buffsContainer.Parent = gui

local buffsLayout = Instance.new("UIListLayout") :: UIListLayout
buffsLayout.FillDirection = Enum.FillDirection.Horizontal
buffsLayout.SortOrder = Enum.SortOrder.LayoutOrder
buffsLayout.Padding = UDim.new(0, 10)
buffsLayout.Parent = buffsContainer

-- Cache de labels para no recrear
local activeBuffLabels: { [string]: TextLabel } = {}

-- Función para actualizar el dinero
local function updateMoney()
	moneyLabel.Text = "CR: " .. tostring(crStat.Value)
end
crStat.Changed:Connect(updateMoney)
updateMoney()

-- Función auxiliar para formatear tiempo
local function formatTime(seconds: number): string
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d", m, s)
end

-- Mapa de nombres bonitos
local buffNames: { [string]: string } = {
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
	local foundBuffs: { [string]: boolean } = {}

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

			if typeof(val) == "number" then
				local v = val :: number
				-- Check if it is a Timer (ends in _End)
				if string.sub(name, -4) == "_End" then
					if v > now then
						timeLeft = v - now
						isTimer = true
					else
						continue -- Expired timer
					end
				else
					-- It's a Stat (Speed, Jump, Multiplier)
					displayValue = tostring(v)
					if isMultiplier then displayValue = "x" .. displayValue end
				end
			elseif typeof(val) == "boolean" then
				local v = val :: boolean
				if v == true then
					displayValue = "ON"
				else
					continue
				end
			else
				continue
			end

			foundBuffs[name] = true

			-- Crear/Actualizar UI
			local existingLabel = activeBuffLabels[name]
			local finalLabel: TextLabel

			if not existingLabel then
				local frame = Instance.new("Frame") :: Frame
				frame.Name = name
				frame.Size = UDim2.new(0, 140, 0, 30)
				frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				frame.BackgroundTransparency = 0.6
				
				local grad = Instance.new("UIGradient") :: UIGradient
				grad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(40,40,40)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
				}
				grad.Parent = frame

				local corner = Instance.new("UICorner") :: UICorner
				corner.CornerRadius = UDim.new(0, 6)
				corner.Parent = frame

				local newLabel = Instance.new("TextLabel") :: TextLabel
				newLabel.Size = UDim2.new(1, -10, 1, 0)
				newLabel.Position = UDim2.new(0, 5, 0, 0)
				newLabel.BackgroundTransparency = 1
				newLabel.Font = Enum.Font.GothamBold
				newLabel.TextColor3 = Color3.new(1, 1, 1)
				newLabel.TextSize = 14
				newLabel.TextXAlignment = Enum.TextXAlignment.Left
				newLabel.Parent = frame

				frame.Parent = buffsContainer
				activeBuffLabels[name] = newLabel
				finalLabel = newLabel
			else
				finalLabel = existingLabel
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
				finalLabel.Text = cleanName .. " " .. formatTime(timeLeft)
				finalLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
			else
				finalLabel.Text = cleanName .. " " .. displayValue
				finalLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
			end
		end
	end

	-- Limpiar UI
	for name, label in pairs(activeBuffLabels) do
		if not foundBuffs[name] then
			local labelParent = label.Parent
			if labelParent then
				labelParent:Destroy()
			end
			activeBuffLabels[name] = nil
		end
	end
end)

print("HUDController: Interfaz actualizada cargada.")

