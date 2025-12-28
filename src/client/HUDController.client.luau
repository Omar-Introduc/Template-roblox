-- src/client/HUDController.client.luau
local Players = game:GetService("Players")
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

-- Crear el contenedor/fondo (opcional, aquí lo haremos simple pero bonito)
local frame = Instance.new("Frame")
frame.Name = "MoneyContainer"
frame.Size = UDim2.new(0, 200, 0, 50)
frame.Position = UDim2.new(0, 20, 1, -70) -- Esquina inferior izquierda
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = frame

-- Texto del dinero
local label = Instance.new("TextLabel")
label.Name = "ValueLabel"
label.Size = UDim2.new(1, -20, 1, 0)
label.Position = UDim2.new(0, 10, 0, 0) -- Margen izquierdo
label.BackgroundTransparency = 1
label.Font = Enum.Font.FredokaOne
label.TextSize = 24
label.TextColor3 = Color3.fromRGB(0, 255, 255) -- Cian Neón
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "CR: " .. tostring(crStat.Value)
label.Parent = frame

-- Función para actualizar el texto
local function updateHUD()
    label.Text = "CR: " .. tostring(crStat.Value)
end

-- Conectar evento de cambio
crStat.Changed:Connect(updateHUD)

-- Inicializar texto
updateHUD()

print("HUDController: Interfaz de dinero cargada.")
