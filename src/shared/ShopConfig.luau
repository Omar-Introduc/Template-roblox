-- src/shared/ShopConfig.luau
return {
    Categories = {
        Movement = {
            Title = "🚀 AGILIDAD",
            Items = {
                { Id = "Speed1", Name = "Velocidad I", Price = 10, Color = Color3.fromRGB(0, 255, 255), Type = "Speed", Value = 22 },
                { Id = "Speed2", Name = "Velocidad II", Price = 25, Color = Color3.fromRGB(0, 200, 255), Type = "Speed", Value = 30 },
                { Id = "Jump1", Name = "Salto I", Price = 15, Color = Color3.fromRGB(255, 255, 0), Type = "Jump", Value = 65 },
                { Id = "Jump2", Name = "Salto II", Price = 35, Color = Color3.fromRGB(255, 200, 0), Type = "Jump", Value = 85 },
            }
        },
        Aero = {
            Title = "☁️ AERODINÁMICA",
            Items = {
                { Id = "LowGrav", Name = "Baja Gravedad", Price = 50, Color = Color3.fromRGB(150, 0, 255), Type = "Gravity", Value = 0.4 },
                { Id = "DoubleJump", Name = "Doble Salto", Price = 150, Color = Color3.fromRGB(255, 255, 255), Type = "DoubleJump" },
                { Id = "Fly10", Name = "Vuelo (10s)", Price = 250, Color = Color3.fromRGB(100, 200, 255), Type = "Fly", Value = 10 },
            }
        },
        Survival = {
            Title = "🛡️ SUPERVIVENCIA",
            Items = {
                { Id = "Shield1", Name = "Escudo Fino", Price = 40, Color = Color3.fromRGB(255, 0, 100), Type = "Protect" },
                { Id = "Heal", Name = "Botiquín", Price = 30, Color = Color3.fromRGB(100, 255, 100), Type = "Heal" },
                { Id = "Immortality", Name = "Inmortal (5s)", Price = 500, Color = Color3.fromRGB(255, 215, 0), Type = "God", Value = 5 },
            }
        },
        Economy = {
            Title = "💰 ECONOMÍA",
            Items = {
                { Id = "DoublePoints", Name = "Puntos X2 (1m)", Price = 100, Color = Color3.fromRGB(255, 150, 0), Type = "Multiplier", Value = 2 },
                { Id = "TriplePoints", Name = "Puntos X3 (1m)", Price = 250, Color = Color3.fromRGB(255, 100, 0), Type = "Multiplier", Value = 3 },
            }
        }
    }
}
