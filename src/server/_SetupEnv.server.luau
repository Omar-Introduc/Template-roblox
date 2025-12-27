--[[
    _SetupEnv.server.luau
    This script mocks the asset environment expected by LevelGenerator.
    It creates game.ReplicatedStorage.Assets.Juego1 and populates it with dummy models.
    This ensures LevelGenerator can run without errors in a test environment.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function ensureAsset(parent, name, size)
	if parent:FindFirstChild(name) then return end

	-- Using Part instead of MeshPart for reliability in mock environment
	-- In the real environment, these would be the actual MeshParts provided by the user.
	local part = Instance.new("MeshPart")
	part.Name = name
	part.Size = size or Vector3.new(4, 1, 4)
	part.Anchored = true
	part.Parent = parent
end

-- Create structure: ReplicatedStorage.Assets.Juego1
local assetsFolder = ensureFolder(ReplicatedStorage, "Assets")
local juego1Folder = ensureFolder(assetsFolder, "Juego1")

-- Create dummy assets
ensureAsset(juego1Folder, "Lobby", Vector3.new(20, 1, 20))
ensureAsset(juego1Folder, "Plataforma", Vector3.new(6, 1, 6))

print("✅ Environment Setup: Assets.Juego1 created.")
