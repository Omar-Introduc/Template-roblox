-- src/client/PointFeedback.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local PointAwarded = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PointAwarded")

local COLOR_CYCLE = {
    Color3.fromRGB(0, 170, 255),  -- Azul (Cyan profundo)
    Color3.fromRGB(255, 0, 0),    -- Rojo
    Color3.fromRGB(255, 255, 0),  -- Amarillo
    Color3.fromRGB(255, 0, 255)   -- Fucsia
}
local currentColorIndex = 1

local function createFloatingText(amount, position)
    local bb = Instance.new("BillboardGui")
    bb.Name = "PointFeedback"
    bb.Size = UDim2.new(0, 100, 0, 50)
    bb.Adornee = nil 
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    
    -- Aplicar color del ciclo
    label.TextColor3 = COLOR_CYCLE[currentColorIndex]
    currentColorIndex = (currentColorIndex % #COLOR_CYCLE) + 1
    
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.Text = "+" .. tostring(amount)
    label.Parent = bb
    
    local anchor = Instance.new("Part")
    anchor.Size = Vector3.new(1,1,1)
    anchor.Position = position
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Parent = workspace
    
    bb.Parent = anchor
    
    local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local goal = {
        StudsOffset = Vector3.new(0, 6, 0)
    }
    local fadeGoal = {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }
    
    local moveTween = TweenService:Create(bb, tweenInfo, goal)
    local fadeTween = TweenService:Create(label, tweenInfo, fadeGoal)
    
    moveTween:Play()
    fadeTween:Play()
    
    task.delay(1.1, function()
        anchor:Destroy()
    end)
end

PointAwarded.OnClientEvent:Connect(function(amount, position)
    task.spawn(createFloatingText, amount, position)
end)
