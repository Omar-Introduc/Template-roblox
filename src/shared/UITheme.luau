-- src/shared/UITheme.luau
--!strict
-- Defines the central visual style for the game UI (Colors, Typography, Sizing)

local UITheme = {}

-- Color Palette
UITheme.Colors = {
    -- Backgrounds
    BackgroundMain = Color3.fromRGB(20, 20, 25),    -- Dark Slate/Black
    BackgroundPanel = Color3.fromRGB(35, 35, 45),   -- Slightly lighter container
    BackgroundItem = Color3.fromRGB(50, 50, 60),    -- For cards/items

    -- Text
    TextPrimary = Color3.fromRGB(255, 255, 255),    -- White
    TextSecondary = Color3.fromRGB(180, 180, 180),  -- Light Grey
    TextHighlight = Color3.fromRGB(255, 215, 0),    -- Gold for emphasis

    -- Accents (Neon Style)
    AccentCyan = Color3.fromRGB(0, 255, 255),       -- Cyan (Movement/Speed)
    AccentPurple = Color3.fromRGB(170, 0, 255),     -- Purple (Gravity/Magic)
    AccentGreen = Color3.fromRGB(0, 255, 100),      -- Green (Health/Success)
    AccentRed = Color3.fromRGB(255, 50, 50),        -- Red (Danger/Close)
    AccentOrange = Color3.fromRGB(255, 150, 0),     -- Orange (Economy)

    -- Interactive
    ButtonDefault = Color3.fromRGB(60, 60, 200),
    ButtonHover = Color3.fromRGB(80, 80, 240),
    ButtonPress = Color3.fromRGB(40, 40, 180),
    ButtonDisabled = Color3.fromRGB(60, 60, 60),
}

-- Typography
UITheme.Fonts = {
    Header = Enum.Font.FredokaOne, -- Fun, chunky font for headers
    Body = Enum.Font.GothamMedium, -- Clean, readable font for body text
    Bold = Enum.Font.GothamBold,
}

UITheme.TextSizes = {
    Title = 32,
    Header = 24,
    SubHeader = 18,
    Body = 14,
    Small = 12,
}

-- Layout / Spacing
UITheme.Layout = {
    CornerRadiusSmall = UDim.new(0, 4),
    CornerRadiusMedium = UDim.new(0, 8),
    CornerRadiusLarge = UDim.new(0, 16),

    PaddingSmall = UDim.new(0, 4),
    PaddingMedium = UDim.new(0, 8),
    PaddingLarge = UDim.new(0, 16),

    IconSizeSmall = UDim2.fromOffset(20, 20),
    IconSizeMedium = UDim2.fromOffset(32, 32),
}

-- Animations
UITheme.TweenInfo = {
    Default = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

return UITheme
