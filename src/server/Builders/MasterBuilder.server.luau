-- src/server/Builders/MasterBuilder.server.luau
-- ESTE SCRIPT ES SOLO PARA DESARROLLO. NO DEBE CORRER EN EL JUEGO FINAL.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Referencia a la carpeta de constructores
local BuildersFolder = script.Parent

print("🏗️ [MasterBuilder] Iniciando generación de Prefabs...")

-- Lista de módulos constructores a ejecutar
local builders = {
	require(BuildersFolder:WaitForChild("ShopBuilder")),
	require(BuildersFolder:WaitForChild("HUDBuilder"))
}

for _, builderModule in ipairs(builders) do
	if builderModule.Build then
		print("🔨 Construyendo: " .. (builderModule.Name or "Sin Nombre"))

		-- Ejecutamos la construcción
		-- Le pasamos un 'Target' (donde queremos que aparezca el prefab)
		local success, result = pcall(function()
			builderModule.Build()
		end)

		if success then
			print("✅ Éxito.")
		else
			warn("❌ Error: " .. tostring(result))
		end
	else
		warn("⚠️ Módulo sin función .Build()")
	end
end

print("🏁 [MasterBuilder] Generación finalizada. ¡Guarda tus Prefabs y desactiva este script!")
