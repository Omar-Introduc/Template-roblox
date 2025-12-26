--[[
    🎨 Template Showcase System

    Responsabilidad: Visualizar todas las plantillas disponibles en una fila organizada.
    Espera a que PrefabFactory termine de cargar los assets.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ROW_SPACING = 30 -- Espacio entre modelos
local START_POSITION = Vector3.new(-100, 5, 20) -- Posición inicial (delante del spawn que está en -50Z)

local function createNameTag(model, name)
	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "NameTag"
	bbGui.Size = UDim2.new(0, 200, 0, 50)
	bbGui.StudsOffset = Vector3.new(0, 5, 0)
	bbGui.AlwaysOnTop = true

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = name
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = bbGui

	bbGui.Parent = model
    -- Si es un modelo, el Adornee es la PrimaryPart, si no, la parte misma
    if model:IsA("Model") and model.PrimaryPart then
        bbGui.Adornee = model.PrimaryPart
    elseif model:IsA("BasePart") then
        bbGui.Adornee = model
    end
end

local function anchorModel(model)
    if model:IsA("Model") then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
            end
        end
    elseif model:IsA("BasePart") then
        model.Anchored = true
    end
end

local function runShowcase()
    print("⏳ Esperando a PrefabFactory...")

    -- Esperar a que la carpeta Templates exista
    local templates = ReplicatedStorage:WaitForChild("Templates", 30)
    if not templates then
        warn("❌ No se encontró la carpeta Templates.")
        return
    end

    -- Esperar señal de listo
    -- PrefabFactory pone el atributo en la carpeta Templates
    if not templates:GetAttribute("PrefabReady") then
        templates:GetAttributeChangedSignal("PrefabReady"):Wait()
    end
    print("✅ Templates listos. Iniciando visualización...")

    local currentX = START_POSITION.X
    local zPos = START_POSITION.Z

    -- Recorrer niveles ordenadamente
    for i = 1, 10 do -- Asumimos max 10 niveles por seguridad
        local folderName = "Level" .. i
        local folder = templates:FindFirstChild(folderName)

        if folder then
            print("   📂 Procesando " .. folderName)

            -- Obtener items y ordenarlos por nombre para consistencia
            local items = folder:GetChildren()
            table.sort(items, function(a, b) return a.Name < b.Name end)

            for _, item in ipairs(items) do
                local clone = item:Clone()
                clone.Name = folderName .. "_" .. item.Name
                clone.Parent = Workspace

                -- Asegurar que está anclado
                anchorModel(clone)

                -- Posicionar
                local cf = CFrame.new(currentX, START_POSITION.Y, zPos)
                if clone:IsA("Model") then
                    clone:PivotTo(cf)
                elseif clone:IsA("BasePart") then
                    clone.CFrame = cf
                end

                -- Etiqueta
                createNameTag(clone, item.Name .. "\n(" .. folderName .. ")")

                currentX = currentX + ROW_SPACING
            end

            -- Separación extra entre niveles
            currentX = currentX + 20
        end
    end

    print("✨ Visualización completada.")
end

-- Ejecutar en un hilo separado por seguridad
task.spawn(runShowcase)
