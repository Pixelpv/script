local NS = getgenv().AutoFarmBF
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local MovementManager = {}
MovementManager._block = nil
MovementManager._flyConn = nil
MovementManager._flyBV = nil
MovementManager._hoverBP = nil
MovementManager._followConn = nil
MovementManager._shouldTween = false

-- ============================================================
-- CONFIGURAÇÕES DE TWEEN
-- ============================================================
MovementManager.TweenSpeedFar = 300
MovementManager.TweenSpeedNear = 900
MovementManager.TweenNearThreshold = 90

-- ============================================================
-- INICIALIZAÇÃO (cria o bloco invisível)
-- ============================================================
function MovementManager.init()
    if MovementManager._block and MovementManager._block.Parent then
        return
    end

    local old = workspace:FindFirstChild("AutoFarmBF_Block")
    if old then old:Destroy() end

    local block = Instance.new("Part")
    block.Name = "AutoFarmBF_Block"
    block.Size = Vector3.new(1, 1, 1)
    block.Anchored = true
    block.CanCollide = false
    block.CanTouch = false
    block.CanQuery = false
    block.Transparency = 1
    block.Parent = workspace

    MovementManager._block = block

    -- Character segue o bloco
    MovementManager._followConn = RunService.Stepped:Connect(function()
        local hrp = NS.HealthManager.getHRP()
        if not hrp or not MovementManager._block then return end

        local blockPos = MovementManager._block.Position
        local hrpPos = hrp.Position
        local dist = (hrpPos - blockPos).Magnitude

        if dist <= 200 then
            hrp.CFrame = MovementManager._block.CFrame
        else
            MovementManager._block.CFrame = hrp.CFrame
        end
    end)

    -- Noclip enquanto tweena
    RunService.Stepped:Connect(function()
        if MovementManager._shouldTween then
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)

    NS.Logger.log("MovementManager: bloco de tween criado")
end

-- ============================================================
-- TELEPORTE SUAVE (Tween)
-- ============================================================
function MovementManager.tp(targetCFrame, speed)
    if not MovementManager._block then
        MovementManager.init()
    end

    local hrp = NS.HealthManager.getHRP()
    if not hrp or not MovementManager._block then return end

    local dist = (targetCFrame.Position - hrp.Position).Magnitude
    speed = speed or (dist <= MovementManager.TweenNearThreshold 
        and MovementManager.TweenSpeedNear 
        or MovementManager.TweenSpeedFar)

    MovementManager._shouldTween = true

    local duration = math.max(dist / speed, 0.05)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(MovementManager._block, info, { CFrame = targetCFrame })
    tween:Play()

    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            task.wait(0.1)
        end
        MovementManager._shouldTween = false
    end)

    return tween
end

-- ============================================================
-- TELEPORTE INSTANTÂNEO (fallback)
-- ============================================================
function MovementManager.teleportTo(position)
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end

    if MovementManager._block then
        MovementManager._block.CFrame = CFrame.new(position)
    end
    hrp.CFrame = CFrame.new(position)
end

-- ============================================================
-- HOVER ACIMA DO ALVO
-- ============================================================
function MovementManager.hoverAbove(target, height)
    if not target then return end

    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end

    if MovementManager._hoverBP then
        MovementManager._hoverBP:Destroy()
    end

    local pos = (target.Position or target) + Vector3.new(0, height or 25, 0)

    local bp = Instance.new("BodyPosition")
    bp.Name = "AutoFarmHover"
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.P = 50000
    bp.D = 1000
    bp.Position = pos
    bp.Parent = hrp

    MovementManager._hoverBP = bp
end

-- ============================================================
-- STAND NEAR (ficar na frente do mob)
-- ============================================================
function MovementManager.standNear(target, distance, height)
    if not target then return end
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end

    MovementManager.stopHover()

    local pos = target.Position or target
    local offset = (hrp.Position - pos).Unit * (distance or 25)
    local dest = pos + offset + Vector3.new(0, height or 5, 0)

    if MovementManager._block then
        MovementManager._block.CFrame = CFrame.new(dest)
    end
    hrp.CFrame = CFrame.new(dest)
end

-- ============================================================
-- BRING MOB (puxa o mob pra você)
-- ============================================================
function MovementManager.bringMob(mob)
    if not mob then return end
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end

    local mobHrp = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChild("Humanoid")
    if not mobHrp or not hum then return end

    mobHrp.CFrame = CFrame.new(hrp.Position)
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    mobHrp.CanCollide = true

    pcall(function()
        sethiddenproperty(player, "SimulationRadius", math.huge)
    end)
end

-- ============================================================
-- STOP HOVER
-- ============================================================
function MovementManager.stopHover()
    if MovementManager._hoverBP then
        MovementManager._hoverBP:Destroy()
        MovementManager._hoverBP = nil
    end
end

-- ============================================================
-- ASCEND / DESCEND
-- ============================================================
function MovementManager.ascend(studs)
    local hrp = NS.HealthManager.getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, studs or 50, 0)
    end
end

function MovementManager.descend(studs)
    local hrp = NS.HealthManager.getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame - Vector3.new(0, studs or 50, 0)
    end
end

-- ============================================================
-- FLY MANUAL
-- ============================================================
function MovementManager.startFly()
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end
    MovementManager.stopHover()
    if MovementManager._flyBV then MovementManager._flyBV:Destroy() end

    MovementManager._flyBV = Instance.new("BodyVelocity")
    MovementManager._flyBV.Name = "AutoFarmFly"
    MovementManager._flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    MovementManager._flyBV.Velocity = Vector3.zero
    MovementManager._flyBV.Parent = hrp

    if MovementManager._flyConn then MovementManager._flyConn:Disconnect() end
    MovementManager._flyConn = RunService.RenderStepped:Connect(function()
        if not NS.Config.flyEnabled then return end
        local hrp2 = NS.HealthManager.getHRP()
        if not hrp2 or not MovementManager._flyBV then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit * NS.Config.flySpeed end
        MovementManager._flyBV.Velocity = dir
    end)
end

function MovementManager.stopFly()
    if MovementManager._flyConn then
        MovementManager._flyConn:Disconnect()
        MovementManager._flyConn = nil
    end
    if MovementManager._flyBV then
        MovementManager._flyBV:Destroy()
        MovementManager._flyBV = nil
    end
end

-- ============================================================
-- REQUEST ENTRANCE (para ilhas especiais)
-- ============================================================
function MovementManager.requestEntrance(position)
    pcall(function()
        local Remotes = ReplicatedStorage:WaitForChild("Remotes")
        Remotes.CommF_:InvokeServer("requestEntrance", position)
    end)
end

return MovementManager
