--[[
    🎨 Template Showcase System

    Responsabilidad: Visualizar todas las plantillas disponibles en una fila organizada.
    Espera a que PrefabFactory termine de cargar los assets.
    Elimina duplicados y muestra solo modelos únicos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ROW_SPACING_GAP = 10 -- Espacio mínimo entre modelos
local START_POSITION = Vector3.new(-100, 5, 20) -- Posición inicial (delante del spawn que está en -50Z)

local function createNameTag(model, name)
	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "NameTag"
	bbGui.Size = UDim2.new(0, 300, 0, 100)
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

-- Genera una firma única para el objeto basada en sus propiedades visuales
local function getSignature(obj)
    local sig = obj.ClassName .. "_" .. obj.Name

    if obj:IsA("BasePart") then
        sig = sig .. string.format("_Size:%.1f,%.1f,%.1f_Color:%s_Mat:%s",
            obj.Size.X, obj.Size.Y, obj.Size.Z,
            tostring(obj.Color),
            tostring(obj.Material))

    elseif obj:IsA("Model") then
        local children = obj:GetChildren()
        table.sort(children, function(a, b) return a.Name < b.Name end)

        sig = sig .. "_ChildCount:" .. #children

        -- Incluir PrimaryPart en la firma si existe
        if obj.PrimaryPart then
             sig = sig .. string.format("_PPSize:%.1f,%.1f,%.1f_PPColor:%s",
                obj.PrimaryPart.Size.X, obj.PrimaryPart.Size.Y, obj.PrimaryPart.Size.Z,
                tostring(obj.PrimaryPart.Color))
        end
    end

    return sig
end

local function getObjectSize(obj)
    if obj:IsA("BasePart") then
        return obj.Size
    elseif obj:IsA("Model") then
        local cf, size = obj:GetBoundingBox()
        return size
    end
    return Vector3.new(5, 5, 5) -- Default fallback
end

local function generateID(index)
    local letterIndex = math.floor((index - 1) / 99) + 1
    local number = (index - 1) % 99 + 1
    local letter = string.char(64 + letterIndex)

    -- Limit to 3 chars: [Letter][Number] or [Letter][Number][Number]
    -- Example: A1, A9, A10, A99

    return letter .. number
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

    local uniqueItems = {} -- Lista ordenada de items únicos para mostrar
    local seenSignatures = {} -- Mapa de firmas a índice en uniqueItems

    -- Recorrer niveles ordenadamente
    for i = 1, 10 do -- Asumimos max 10 niveles por seguridad
        local folderName = "Level" .. i
        local folder = templates:FindFirstChild(folderName)

        if folder then
            -- Obtener items y ordenarlos por nombre para consistencia
            local items = folder:GetChildren()
            table.sort(items, function(a, b) return a.Name < b.Name end)

            for _, item in ipairs(items) do
                local sig = getSignature(item)

                if seenSignatures[sig] then
                    -- Ya visto, agregamos el nivel actual a su lista de niveles
                    local entry = uniqueItems[seenSignatures[sig]]
                    table.insert(entry.levels, i)
                else
                    -- Nuevo item único
                    local entry = {
                        obj = item,
                        levels = {i},
                        sig = sig,
                        name = item.Name
                    }
                    table.insert(uniqueItems, entry)
                    seenSignatures[sig] = #uniqueItems
                end
            end
        end
    end

    -- Visualización
    local currentX = START_POSITION.X
    local zPos = START_POSITION.Z

    print("✨ Mostrando " .. #uniqueItems .. " objetos únicos.")

    for index, entry in ipairs(uniqueItems) do
        local original = entry.obj
        local clone = original:Clone()
        clone.Name = "Showcase_" .. original.Name
        clone.Parent = Workspace

        anchorModel(clone)

        local size = getObjectSize(clone)
        -- Centrar basado en el tamaño actual
        local xPos = currentX + (size.X / 2)
        local yPos = START_POSITION.Y + (size.Y / 2)

        local cf = CFrame.new(xPos, yPos, zPos)
        if clone:IsA("Model") then
            clone:PivotTo(cf)
        elseif clone:IsA("BasePart") then
            clone.CFrame = cf
        end

        -- Formatear lista de niveles
        local levelStr = "Levels: " .. table.concat(entry.levels, ", ")
        if #entry.levels > 5 then
            levelStr = "Levels: " .. entry.levels[1] .. "..." .. entry.levels[#entry.levels] .. " (" .. #entry.levels .. " total)"
        end

        -- Generar ID único corto (A1, A2...)
        local shortID = generateID(index)

        -- Mostrar principalmente el ID como se solicitó
        createNameTag(clone, shortID)

        -- Avanzar cursor
        currentX = currentX + size.X + ROW_SPACING_GAP
    end

    print("✨ Visualización completada.")
end

-- Ejecutar en un hilo separado por seguridad
task.spawn(runShowcase)
