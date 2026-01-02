-- src/server/Builders/HUDBuilder.luau
local HUDBuilder = {}
HUDBuilder.Name = "HUD Builder"

function HUDBuilder.Build()
	warn("HUDBuilder is DEPRECATED. The HUD is now generated at runtime by src/client/HUDController.client.luau using UIComponents.")
	-- No operation
end

return HUDBuilder
