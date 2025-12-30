-- src/shared/ShopConfig.luau
return {
    Categories = {
        Movement = {
            Title = "🚀 AGILIDAD",
            Items = {
                { Id = "Speed1", Name = "Velocidad I", Price = 10, Color = Color3.fromRGB(0, 255, 255), Type = "Speed", Value = 22, Implemented = true },
                { Id = "Speed2", Name = "Velocidad II", Price = 25, Color = Color3.fromRGB(0, 200, 255), Type = "Speed", Value = 30, Implemented = true },
                { Id = "Jump1", Name = "Salto I", Price = 15, Color = Color3.fromRGB(255, 255, 0), Type = "Jump", Value = 65, Implemented = true },
                { Id = "Jump2", Name = "Salto II", Price = 35, Color = Color3.fromRGB(255, 200, 0), Type = "Jump", Value = 85, Implemented = true },
            }
        },
        Aero = {
            Title = "☁️ AERODINÁMICA",
            Items = {
                { Id = "LowGrav", Name = "Baja Gravedad", Price = 50, Color = Color3.fromRGB(150, 0, 255), Type = "Gravity", Value = 0.4, Implemented = true },
                { Id = "DoubleJump", Name = "Doble Salto", Price = 150, Color = Color3.fromRGB(255, 255, 255), Type = "DoubleJump", Implemented = true },
                { Id = "Fly10", Name = "Vuelo (10s)", Price = 250, Color = Color3.fromRGB(100, 200, 255), Type = "Fly", Value = 10, Implemented = true },
                { Id = "SlowFall", Name = "Caída Lenta", Price = 75, Color = Color3.fromRGB(200, 200, 255), Type = "SlowFall", Implemented = false },
            }
        },
        Survival = {
            Title = "🛡️ SUPERVIVENCIA",
            Items = {
                { Id = "Shield1", Name = "Escudo Fino", Price = 40, Color = Color3.fromRGB(255, 0, 100), Type = "Protect", Implemented = true },
                { Id = "Heal", Name = "Botiquín", Price = 30, Color = Color3.fromRGB(100, 255, 100), Type = "Heal", Implemented = true },
                { Id = "Immortality", Name = "Inmortal (5s)", Price = 500, Color = Color3.fromRGB(255, 215, 0), Type = "God", Value = 5, Implemented = true },
                { Id = "Resurrection", Name = "Resurrir", Price = 1000, Color = Color3.fromRGB(0, 255, 150), Type = "ExtraLife", Implemented = false },
            }
        },
        Economy = {
            Title = "💰 ECONOMÍA",
            Items = {
                { Id = "DoublePoints", Name = "Puntos X2 (1m)", Price = 100, Color = Color3.fromRGB(255, 150, 0), Type = "Multiplier", Value = 2, Implemented = true, CurrencyType = "CR" },
                { Id = "TriplePoints", Name = "Puntos X3 (1m)", Price = 250, Color = Color3.fromRGB(255, 100, 0), Type = "Multiplier", Value = 3, Implemented = true, CurrencyType = "CR" },
                { Id = "PointShield", Name = "Seguro Puntos", Price = 150, Color = Color3.fromRGB(200, 150, 255), Type = "SavePoints", Implemented = false, CurrencyType = "CR" },
                { Id = "TaxExempt", Name = "Sin Impuestos", Price = 300, Color = Color3.fromRGB(150, 255, 200), Type = "Discount", Implemented = false, CurrencyType = "CR" },
            }
        },
        Beasts = {
            Title = "🐾 CRIATURAS",
            Items = {
                { Id = "Beast_Gato_Common", Name = "Gato Callejero", Price = 50, Rarity = "Common", Type = "Companion", Implemented = true },
                { Id = "Beast_Gato_Rare", Name = "Gato Siamés", Price = 150, Rarity = "Rare", Type = "Companion", Implemented = true },
                { Id = "Beast_Gato_Mystic", Name = "Gato Cósmico", Price = 500, Rarity = "Mystic", Type = "Companion", Implemented = true },
            }
        },
        Robux = {
            Title = "💎 TIENDA ROBUX",
            Items = {
                { Id = "PermX2", Name = "X2 Puntos (Eterno)", Price = 499, Color = Color3.fromRGB(85, 255, 127), Type = "Multiplier", Value = 2, Implemented = true, CurrencyType = "Robux", GamePassId = 0 },
                { Id = "RobuxItem2", Name = "Próximamente", Price = 0, Color = Color3.fromRGB(150, 150, 150), Type = "None", Implemented = false, CurrencyType = "Robux" },
                { Id = "RobuxItem3", Name = "Próximamente", Price = 0, Color = Color3.fromRGB(150, 150, 150), Type = "None", Implemented = false, CurrencyType = "Robux" },
                { Id = "RobuxItem4", Name = "Próximamente", Price = 0, Color = Color3.fromRGB(150, 150, 150), Type = "None", Implemented = false, CurrencyType = "Robux" },
                { Id = "RobuxItem5", Name = "Próximamente", Price = 0, Color = Color3.fromRGB(150, 150, 150), Type = "None", Implemented = false, CurrencyType = "Robux" },
                { Id = "RobuxItem6", Name = "Próximamente", Price = 0, Color = Color3.fromRGB(150, 150, 150), Type = "None", Implemented = false, CurrencyType = "Robux" },
            }
        }
    }
}
