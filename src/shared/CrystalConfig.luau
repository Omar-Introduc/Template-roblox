local CrystalConfig = {}

CrystalConfig.Colors = {
    Default = Color3.fromRGB(0, 255, 255), -- Cyan
    Touched = Color3.fromRGB(255, 0, 255), -- Magenta
}

-- Configuración nueva
CrystalConfig.MaxTouches = 3      -- Se rompe al tercer toque
CrystalConfig.DebounceTime = 1.0  -- Espera 1 segundo entre toques para contar de nuevo

return CrystalConfig