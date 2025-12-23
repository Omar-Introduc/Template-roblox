-- ItemsData (Shared)
local ItemsData = {
	Powerups = {
		{
			Id = "SpeedCoil",
			Name = "Speed Coil",
			Description = "Increases speed to 25 for 30s",
			Price = 50,
			Duration = 30,
			Value = 25,
			Attribute = "SpeedBonus"
		},
		{
			Id = "GravityBoots",
			Name = "Gravity Boots",
			Description = "Increases jump power for 30s",
			Price = 100,
			Duration = 30,
			Value = 70, -- Standard is 50
			Attribute = "JumpBonus"
		},
		{
			Id = "CheckpointSave",
			Name = "Ghost Checkpoint",
			Description = "Respawn one time where you fell",
			Price = 200,
			Duration = 0, -- Instant use
			Value = 1,
			Attribute = "HasGhostCheckpoint"
		},
		{
			Id = "PinguinoNavideño",
			Name = "Pinguino Navideño",
			Description = "Slide like a penguin! Extreme speed boost for 45s.",
			Price = 500,
			Duration = 45,
			Value = 40,
			Attribute = "PenguinMode"
		}
	}
}

return ItemsData
