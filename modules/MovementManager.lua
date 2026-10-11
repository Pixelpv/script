local NS = getgenv().AutoFarmBF
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local MovementManager = {}
MovementManager._block = nil
MovementManager._followConn = nil
MovementManager._flyConn = nil
MovementManager._flyBV = nil
MovementManager._shouldTween = false

MovementManager.TweenSpeedFar = 300
MovementManager.TweenSpeedNear = 900
MovementManager.TweenNearThreshold = 90

-- ============================================================
-- INIT
-- ============================================================
function MovementManager.init()
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj.Name == "AutoFarmHover" or obj.Name == "AutoFarmFly" then
                    obj:Destroy()
                end
            end
        end
    end

    if not MovementManager._block or not MovementManager._block.Parent then
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

        MovementManager._followConn = RunService.Stepped:Connect(function()
            local hrp = NS.HealthManager.getHRP()
            if not hrp or not MovementManager._block then return end
            local dist = (hrp.Position - MovementManager._block.Position).Magnitude
            if dist <= 200 then
                hrp.CFrame = MovementManager._block.CFrame
            else
                MovementManager._block.CFrame = hrp.CFrame
            end
        end)
    end
end

-- ============================================================
-- TWEEN SUAVE (voar até o alvo)
-- ============================================================
function MovementManager.tp(targetCFrame, speed)
    if not MovementManager._block then MovementManager.init() end
    local hrp = NS.HealthManager.getHRP()
    if not hrp or not MovementManager._block then return end

    local dist = (targetCFrame.Position - hrp.Position).Magnitude
    speed = speed or (dist <= MovementManager.TweenNearThreshold
        and MovementManager.TweenSpeedNear or MovementManager.TweenSpeedFar)

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
-- TELEPORTE INSTANTÂNEO
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
-- HOVER (só pra compatibilidade, não é mais usado no FARMING)
-- ============================================================
function MovementManager.hoverAbove(target, height)
    if not target then return end
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end
    local pos = (target.Position or target) + Vector3.new(0, height or 20, 0)
    hrp.CFrame = CFrame.new(pos)
end

function MovementManager.stopHover()
    -- Não faz nada agora, mas mantém a API pra não quebrar nada
end

-- ============================================================
-- BRING MOB (puxa o mob pra baixo de você)
-- ============================================================
function MovementManager.bringMob(mob)
    if not mob then return end
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end

    local mobHrp = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChild("Humanoid")
    if not mobHrp or not hum then return end

    mobHrp.CFrame = CFrame.new(hrp.Position)
    mobHrp.CanCollide = false
    hum.WalkSpeed = 0
    hum.JumpPower = 0

    local animator = hum:FindFirstChild("Animator")
    if animator then
        pcall(function() animator:Destroy() end)
    end
end

-- ============================================================
-- ASCEND / DESCEND
-- ============================================================
function MovementManager.ascend(studs)
    local hrp = NS.HealthManager.getHRP()
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, studs or 50, 0) end
end

function MovementManager.descend(studs)
    local hrp = NS.HealthManager.getHRP()
    if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, studs or 50, 0) end
end

-- ============================================================
-- FLY
-- ============================================================
function MovementManager.startFly()
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end
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

return MovementManager
