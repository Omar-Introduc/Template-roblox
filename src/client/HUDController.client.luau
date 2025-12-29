-- src/client/HUDController.client.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Esperar a que se carguen los leaderstats
local leaderstats = player:WaitForChild("leaderstats", 10)
local crStat = leaderstats and leaderstats:WaitForChild("CR", 10)

if not crStat then
    warn("HUDController: No se encontró 'leaderstats' o 'CR'. El HUD no se iniciará.")
    return
end

-- Crear la Interfaz (ScreenGui)
local gui = Instance.new("ScreenGui")
gui.Name = "MoneyHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Crear el contenedor de Dinero
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

local label = Instance.new("TextLabel")
label.Name = "ValueLabel"
label.Size = UDim2.new(1, -20, 1, 0)
label.Position = UDim2.new(0, 10, 0, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.FredokaOne
label.TextSize = 24
label.TextColor3 = Color3.fromRGB(0, 255, 255)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "CR: " .. tostring(crStat.Value)
label.Parent = moneyFrame

-- Función para actualizar el dinero
local function updateMoney()
    label.Text = "CR: " .. tostring(crStat.Value)
end
crStat.Changed:Connect(updateMoney)

--------------------------------------------------------------------------------
-- SISTEMA DE BUFFS (Visualización)
--------------------------------------------------------------------------------

local buffsContainer = Instance.new("Frame")
buffsContainer.Name = "BuffsContainer"
buffsContainer.Size = UDim2.new(0, 200, 0, 300) -- Espacio vertical para apilar buffs
buffsContainer.Position = UDim2.new(0, 20, 1, -380) -- Encima del dinero
buffsContainer.BackgroundTransparency = 1
buffsContainer.Parent = gui

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
listLayout.Parent = buffsContainer

-- Mapa de Buffs a Textos Amigables
local BUFF_NAMES = {
    ["Buff_Fly_End"] = "VUELO",
    ["Buff_God_End"] = "INMORTAL",
    ["Buff_Multiplier_End"] = "PUNTOS X2",
    ["Buff_DoubleJump"] = "DOBLE SALTO" -- Este es booleano, tratamiento especial
}

-- Cache de Frames de Buffs
local activeBuffFrames = {}

local function getTimeRemaining(endTime)
    local remaining = endTime - os.time()
    if remaining < 0 then return 0 end
    return remaining
end

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

local function updateBuffs()
    local character = player.Character
    if not character then
        -- Limpiar todo si no hay personaje
        for _, frame in pairs(activeBuffFrames) do frame:Destroy() end
        table.clear(activeBuffFrames)
        return
    end

    local attributes = character:GetAttributes()
    local foundBuffs = {}

    -- 1. Procesar atributos
    for name, value in pairs(attributes) do
        if BUFF_NAMES[name] then
            foundBuffs[name] = true

            -- Determinar texto y si debe mostrarse
            local shouldShow = false
            local timeText = ""

            if type(value) == "number" then
                -- Es un timestamp
                local remaining = getTimeRemaining(value)
                if remaining > 0 then
                    shouldShow = true
                    timeText = formatTime(remaining)
                end
            elseif type(value) == "boolean" and value == true then
                -- Es un estado permanente (ej. Doble Salto)
                shouldShow = true
                timeText = "∞"
            end

            if shouldShow then
                local buffFrame = activeBuffFrames[name]
                if not buffFrame then
                    -- Crear Frame nuevo
                    buffFrame = Instance.new("Frame")
                    buffFrame.Size = UDim2.new(1, 0, 0, 30)
                    buffFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    buffFrame.BackgroundTransparency = 0.6
                    buffFrame.BorderSizePixel = 0

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 6)
                    corner.Parent = buffFrame

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(0.6, -5, 1, 0)
                    nameLabel.Position = UDim2.new(0, 5, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Font = Enum.Font.FredokaOne
                    nameLabel.TextSize = 14
                    nameLabel.TextColor3 = Color3.new(1, 1, 1)
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.Text = BUFF_NAMES[name]
                    nameLabel.Parent = buffFrame

                    local timerLabel = Instance.new("TextLabel")
                    timerLabel.Name = "Timer"
                    timerLabel.Size = UDim2.new(0.4, -5, 1, 0)
                    timerLabel.Position = UDim2.new(0.6, 0, 0, 0)
                    timerLabel.BackgroundTransparency = 1
                    timerLabel.Font = Enum.Font.Code
                    timerLabel.TextSize = 14
                    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    timerLabel.TextXAlignment = Enum.TextXAlignment.Right
                    timerLabel.Text = timeText
                    timerLabel.Parent = buffFrame

                    buffFrame.Parent = buffsContainer
                    activeBuffFrames[name] = buffFrame
                else
                    -- Actualizar Timer
                    local tLabel = buffFrame:FindFirstChild("Timer")
                    if tLabel then tLabel.Text = timeText end
                end
            else
                -- Expirado pero sigue el atributo (raro, pero posible)
                if activeBuffFrames[name] then
                    activeBuffFrames[name]:Destroy()
                    activeBuffFrames[name] = nil
                end
            end
        end
    end

    -- 2. Limpiar frames de buffs que ya no existen en atributos
    for name, frame in pairs(activeBuffFrames) do
        if not foundBuffs[name] then
            frame:Destroy()
            activeBuffFrames[name] = nil
        end
    end
end

-- Ejecutar loop de actualización
RunService.Heartbeat:Connect(updateBuffs)

print("HUDController: Sistema de Buffs activado.")
