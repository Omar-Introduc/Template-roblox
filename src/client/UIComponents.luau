-- src/client/UIComponents.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local UIComponents = {}

-- Utility to apply basic properties
local function applyProps(instance: Instance, props: {[string]: any})
    for k, v in pairs(props) do
        (instance :: any)[k] = v
    end
end

-- Helper to add UICorner
local function addCorner(parent: Instance, radius: UDim)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius
    corner.Parent = parent
    return corner
end

-- Helper to add UIPadding
local function addPadding(parent: Instance, padding: UDim)
    local p = Instance.new("UIPadding")
    p.PaddingTop = padding
    p.PaddingBottom = padding
    p.PaddingLeft = padding
    p.PaddingRight = padding
    p.Parent = parent
    return p
end

-- 1. Create Container (Frame with Corner)
function UIComponents.CreateContainer(props: {
    Name: string?,
    Size: UDim2?,
    Position: UDim2?,
    BackgroundColor3: Color3?,
    Transparency: number?,
    Parent: Instance?
})
    local frame = Instance.new("Frame")
    frame.Name = props.Name or "Container"
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = props.BackgroundColor3 or UITheme.Colors.BackgroundPanel
    frame.BackgroundTransparency = props.Transparency or 0
    frame.BorderSizePixel = 0

    addCorner(frame, UITheme.Layout.CornerRadiusMedium)

    if props.Parent then
        frame.Parent = props.Parent
    end

    return frame
end

-- 2. Create Label
function UIComponents.CreateLabel(props: {
    Name: string?,
    Text: string,
    Size: UDim2?,
    TextColor3: Color3?,
    TextSize: number?,
    Font: Enum.Font?,
    TextXAlignment: Enum.TextXAlignment?,
    Parent: Instance?
})
    local label = Instance.new("TextLabel")
    label.Name = props.Name or "Label"
    label.Text = props.Text
    label.Size = props.Size or UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.TextColor3 = props.TextColor3 or UITheme.Colors.TextPrimary
    label.TextSize = props.TextSize or UITheme.TextSizes.Body
    label.Font = props.Font or UITheme.Fonts.Body
    label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left

    if props.Parent then
        label.Parent = props.Parent
    end

    return label
end

-- 3. Create Button (ImageButton/TextButton with hover effects)
function UIComponents.CreateButton(props: {
    Name: string?,
    Text: string,
    Size: UDim2?,
    Position: UDim2?,
    BackgroundColor3: Color3?,
    Callback: (() -> ())?,
    Parent: Instance?
})
    local button = Instance.new("TextButton")
    button.Name = props.Name or "Button"
    button.Text = props.Text
    button.Size = props.Size or UDim2.new(0, 120, 0, 40)
    button.Position = props.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = props.BackgroundColor3 or UITheme.Colors.ButtonDefault
    button.TextColor3 = UITheme.Colors.TextPrimary
    button.Font = UITheme.Fonts.Bold
    button.TextSize = UITheme.TextSizes.Header
    button.AutoButtonColor = false -- Custom logic

    addCorner(button, UITheme.Layout.CornerRadiusSmall)

    -- Hover / Click Animations
    local originalColor = button.BackgroundColor3

    button.MouseEnter:Connect(function()
        TweenService:Create(button, UITheme.TweenInfo.Default, {
            BackgroundColor3 = UITheme.Colors.ButtonHover
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, UITheme.TweenInfo.Default, {
            BackgroundColor3 = originalColor
        }):Play()
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = UITheme.Colors.ButtonPress,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset * 0.95, button.Size.Y.Scale, button.Size.Y.Offset * 0.95)
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = UITheme.Colors.ButtonHover, -- Return to hover state
             Size = props.Size or UDim2.new(0, 120, 0, 40)
        }):Play()

        if props.Callback then
            props.Callback()
        end
    end)

    if props.Parent then
        button.Parent = props.Parent
    end

    return button
end

-- 4. Create Modal Window
function UIComponents.CreateModal(props: {
    Title: string,
    Size: UDim2?,
    OnClose: () -> (),
    Parent: Instance?
})
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Modal_" .. props.Title
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.Parent = screenGui

    -- Main Window
    local window = UIComponents.CreateContainer({
        Name = "Window",
        Size = props.Size or UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, 0, 0.5, 0), -- Center (needs AnchorPoint)
        BackgroundColor3 = UITheme.Colors.BackgroundMain,
        Parent = screenGui
    })
    window.AnchorPoint = Vector2.new(0.5, 0.5)

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.Parent = window

    local titleLabel = UIComponents.CreateLabel({
        Name = "Title",
        Text = props.Title,
        Size = UDim2.new(1, -60, 1, 0),
        Font = UITheme.Fonts.Header,
        TextSize = UITheme.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 20)
    padding.Parent = titleLabel

    -- Close Button
    local closeBtn = UIComponents.CreateButton({
        Name = "CloseButton",
        Text = "X",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -45, 0, 5),
        BackgroundColor3 = UITheme.Colors.AccentRed,
        Parent = header,
        Callback = props.OnClose
    })

    -- Content Container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -50)
    content.Position = UDim2.new(0, 0, 0, 50)
    content.BackgroundTransparency = 1
    content.Parent = window

    if props.Parent then
        screenGui.Parent = props.Parent
    end

    return screenGui, content
end

-- 5. Create Progress Bar
function UIComponents.CreateProgressBar(props: {
    Name: string?,
    Size: UDim2?,
    Color: Color3?,
    Parent: Instance?
})
    local container = Instance.new("Frame")
    container.Name = props.Name or "ProgressBar"
    container.Size = props.Size or UDim2.new(0, 200, 0, 20)
    container.BackgroundColor3 = Color3.new(0,0,0)
    container.BackgroundTransparency = 0.5

    addCorner(container, UDim.new(1, 0)) -- Pill shape

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0) -- Starts full
    fill.BackgroundColor3 = props.Color or UITheme.Colors.AccentGreen
    fill.BorderSizePixel = 0
    addCorner(fill, UDim.new(1, 0))
    fill.Parent = container

    if props.Parent then
        container.Parent = props.Parent
    end

    return container, fill
end

return UIComponents
