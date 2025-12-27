local ShopConfig = {}

ShopConfig.Categories = {
	{ id = 'Mejoras', icon = 'rbxassetid://6031091531', label = 'SALTOS' },
	{ id = 'Utilidad', icon = 'rbxassetid://6031243319', label = 'BASE' },
	{ id = 'Efectos', icon = 'rbxassetid://6031243319', label = 'RASTROS' }
}

ShopConfig.Items = {
	['Mejoras'] = {
		{ id = 1, name = 'Resorte de Cobre', price = 400, type = 'coins', rarity = 'BÁSICO', effect = '+10% Salto', color = Color3.fromHex('#b45309'), img = '🌀' },
		{ id = 2, name = 'Botas de Vapor', price = 1800, type = 'coins', rarity = 'RARO', effect = '+25% Velocidad', color = Color3.fromHex('#fbbf24'), img = '👟' },
		{ id = 3, name = 'Bobina de Gravedad', price = 45, type = 'gems', rarity = 'ÉPICO', effect = 'Gravedad x0.5', color = Color3.fromHex('#38bdf8'), img = '🌪️' },
		{ id = 4, name = 'Doble Salto', price = 120, type = 'gems', rarity = 'MÍTICO', effect = 'Salto Extra', color = Color3.fromHex('#a855f7'), img = '🚀' },
	},
	['Utilidad'] = {
		{ id = 5, name = 'Checkpoint', price = 500, type = 'coins', rarity = 'RARO', effect = 'Punto de guardado', color = Color3.fromHex('#4ade80'), img = '🚩' },
		{ id = 6, name = 'Escudo de Caída', price = 30, type = 'gems', rarity = 'ÉPICO', effect = 'Inmunidad caída', color = Color3.fromHex('#f43f5e'), img = '🛡️' },
	},
	['Efectos'] = {
		{ id = 7, name = 'Rastro de Fuego', price = 1000, type = 'coins', rarity = 'RARO', effect = 'Efecto visual', color = Color3.fromHex('#f97316'), img = '🔥' },
		{ id = 8, name = 'Aura de Cristal', price = 60, type = 'gems', rarity = 'MÍTICO', effect = 'Brillo Épico', color = Color3.fromHex('#22d3ee'), img = '✨' },
	}
}

return ShopConfig
