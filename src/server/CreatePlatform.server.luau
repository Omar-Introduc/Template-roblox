local CollectionService = game:GetService("CollectionService")

local platform = Instance.new("Part")
platform.Name = "PlataformaMagica"
platform.Anchored = true
platform.Size = Vector3.new(5, 1, 5)
platform.Position = Vector3.new(0, 5, 10)
platform.BrickColor = BrickColor.new("Bright blue")

-- Añadir el Tag "Crystal" para que CrystalService lo detecte
CollectionService:AddTag(platform, "Crystal")

platform.Parent = workspace
