-- src/client/CharacterMechanics.client.luau
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

--------------------------------------------------------------------------------
-- DOUBLE JUMP LOGIC
--------------------------------------------------------------------------------
local canDoubleJump = false
local hasDoubleJumped = false

UserInputService.JumpRequest:Connect(function()
    if not character or not humanoid or not character:IsDescendantOf(Workspace) then return end

    -- Verificar si tiene el atributo (permanente o temporal si se implementara así)
    local hasDoubleJumpBuff = character:GetAttribute("Buff_DoubleJump") == true

    if hasDoubleJumpBuff then
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall and not hasDoubleJumped then
            hasDoubleJumped = true

            -- Aplicar impulso
            local oldPower = humanoid.JumpPower
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

            -- Efecto visual opcional (sonido o particula)
        end
    end
end)

humanoid.StateChanged:Connect(function(oldState, newState)
    if newState == Enum.HumanoidStateType.Landed then
        hasDoubleJumped = false
    end
end)

--------------------------------------------------------------------------------
-- FLIGHT LOGIC
--------------------------------------------------------------------------------
local flightBv = nil -- BodyVelocity (simple y efectivo para vuelo básico)
local flightBg = nil -- BodyGyro

local function updateFlight(dt)
    if not character or not rootPart or not humanoid then return end

    local flyEndTime = character:GetAttribute("Buff_Fly_End")
    local isFlying = flyEndTime and os.time() < flyEndTime

    if isFlying then
        -- Activar vuelo si no existe
        if not flightBv then
            flightBv = Instance.new("BodyVelocity")
            flightBv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flightBv.Velocity = Vector3.zero
            flightBv.Name = "FlightVelocity"
            flightBv.Parent = rootPart

            flightBg = Instance.new("BodyGyro")
            flightBg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flightBg.CFrame = rootPart.CFrame
            flightBg.Name = "FlightGyro"
            flightBg.Parent = rootPart

            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end

        -- Calcular dirección basada en cámara y input
        local moveDir = humanoid.MoveDirection
        local lookDir = camera.CFrame.LookVector

        -- Velocidad de vuelo (base 50)
        local flySpeed = 50

        -- Si hay input de movimiento, volar relativo a la cámara
        -- Si no, quedarse quieto (hover)

        if moveDir.Magnitude > 0 then
            -- Convertir moveDir (relativo al personaje) a espacio de mundo realineado con cámara
            -- Pero humanoid.MoveDirection ya es relativo a la cámara en modo normal.
            -- Simplemente multiplicamos MoveDirection por velocidad, pero queremos volar HACIA DONDE MIRAMOS si pulsamos adelante.

            -- Estrategia simple: Usar la dirección de la cámara si se presiona W
            -- Pero MoveDirection es plano XZ.

            -- Vamos a usar el vector de cámara para 'adelante' puro.
            local camCFrame = camera.CFrame
            local forward = camCFrame.LookVector
            local right = camCFrame.RightVector
            local up = camCFrame.UpVector

            -- Descomponer input (UserInputService es mejor aqui pero MoveDirection es facil)
            -- Aproximación simple:
            local targetVel = Vector3.zero

            -- Detectar inputs básicos para "subir/bajar" con Espacio/Control es ideal,
            -- pero la solicitud dice "Habilitar la tecla de volar (Espacio doble)".
            -- El prompt original: "Cuando compras 'Vuelo (10s)'... permite volar (puedes usar AlignPosition...)"

            -- Usaremos MoveDirection para movimiento plano y Cámara para pitch.
            targetVel = moveDir * flySpeed

            -- Hack para subir/bajar mirando arriba/abajo
            -- Si nos movemos, ajustamos la componente Y según la camara
            if moveDir.Magnitude > 0 then
                 -- Proyectar movimiento en la dirección de la vista
                 targetVel = camera.CFrame:VectorToWorldSpace(Vector3.new(humanoid.MoveDirection.X, 0, -humanoid.MoveDirection.Z)) * flySpeed -- Esto no es correcto porque MoveDirection ya es WorldSpace.

                 -- Mejor: MoveDirection es WorldSpace XZ.
                 -- Si miramos arriba, queremos ir arriba.
                 -- Vamos a simplemente setear la velocidad a MoveDirection * Speed + ajuste de altura según cámara pitch si estamos avanzando.

                 targetVel = humanoid.MoveDirection * flySpeed

                 -- Añadir componente vertical basada en LookVector si avanzamos
                 -- (Esto es un vuelo estilo 'noclip' simplificado)
                 local forwardDot = humanoid.MoveDirection:Dot(camera.CFrame.LookVector * Vector3.new(1,0,1))
                 if forwardDot > 0.5 then -- Si nos movemos 'hacia adelante'
                      targetVel = camera.CFrame.LookVector * flySpeed
                 end
            end

            -- Tecla espacio para subir (Input pasivo)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                targetVel = targetVel + Vector3.new(0, 30, 0)
            end

            flightBv.Velocity = Vector3.new(targetVel.X, targetVel.Y, targetVel.Z)

            -- Rotar personaje hacia la cámara
            flightBg.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camera.CFrame.LookVector)
        else
             flightBv.Velocity = Vector3.zero
        end

        -- Mantener estado Physics para evitar gravedad
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    else
        -- Desactivar vuelo si existe
        if flightBv then
            flightBv:Destroy()
            flightBv = nil
        end
        if flightBg then
            flightBg:Destroy()
            flightBg = nil
        end

        if humanoid:GetState() == Enum.HumanoidStateType.Physics then
             humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

RunService.RenderStepped:Connect(updateFlight)
