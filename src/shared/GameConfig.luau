--!strict

export type GameConfig = {
	COUNTDOWN_TIME: number,
	FALL_DELAY: number,
	RESET_DELAY: number,
	TAG_PLATFORMA: string,
	ESPACIO_ENTRE_BORDES: number,
}

local GameConfig: GameConfig = {
	COUNTDOWN_TIME = 3,
	FALL_DELAY = 2,
	RESET_DELAY = 5,
	TAG_PLATFORMA = "PlataformaCaida",
	ESPACIO_ENTRE_BORDES = 5,
}

return GameConfig
