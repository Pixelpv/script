local NS = getgenv().AutoFarmBF
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local MovementManager = {}
MovementManager._flyConn = nil
MovementManager._flyBV = nil
MovementManager._hoverBP = nil
MovementManager._hoverTarget = nil

function MovementManager.teleportTo(position)
    local hrp = NS.HealthManager.getHRP()
    if hrp then hrp.CFrame = CFrame.new(position) end
end

function MovementManager.hoverAbove(target, height)
    if not target then return end
    local pos = target.Position or target
    MovementManager._hoverTarget = pos + Vector3.new(0, height or 25, 0)

    local hrp = NS.HealthManager.getHRP()
    if not hrp then return end

    if not MovementManager._hoverBP or MovementManager._hoverBP.Parent ~= hrp then
        if MovementManager._hoverBP then MovementManager._hoverBP:Destroy() end
        MovementManager._hoverBP = Instance.new("BodyPosition")
        MovementManager._hoverBP.Name = "AutoFarmHover"
        MovementManager._hoverBP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        MovementManager._hoverBP.P = 50000
        MovementManager._hoverBP.D = 1000
        MovementManager._hoverBP.Parent = hrp
    end

    MovementManager._hoverBP.Position = MovementManager._hoverTarget
end

function MovementManager.stopHover()
    if MovementManager._hoverBP then
        MovementManager._hoverBP:Destroy()
        MovementManager._hoverBP = nil
    end
    MovementManager._hoverTarget = nil
end

function MovementManager.ascend(studs)
    local hrp = NS.HealthManager.getHRP()
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, studs or 50, 0) end
end

function MovementManager.descend(studs)
    local hrp = NS.HealthManager.getHRP()
    if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, studs or 50, 0) end
end

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

return MovementManager
