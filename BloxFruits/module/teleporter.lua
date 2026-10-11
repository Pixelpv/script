local Teleporter = {}

local Deps = {}
local tpPart = nil
local activeTween = nil
local activeConn = nil
local isActive = false

function Teleporter.init(deps)
    Deps = deps or {}
    
    if tpPart and tpPart.Parent then
        tpPart:Destroy()
    end
    
    tpPart = Instance.new("Part")
    tpPart.Name = "AutoFarmLevel_TpPart"
    tpPart.Size = Vector3.new(1, 1, 1)
    tpPart.Anchored = true
    tpPart.CanCollide = false
    tpPart.CanTouch = false
    tpPart.CanQuery = false
    tpPart.Transparency = 1
    tpPart.Parent = workspace
end

local function getHRP()
    local plr = game:GetService("Players").LocalPlayer
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function stopActive()
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
    if activeConn then
        pcall(function() activeConn:Disconnect() end)
        activeConn = nil
    end
    isActive = false
end

function Teleporter.toPosition(targetCF, speed)
    if not tpPart or not tpPart.Parent then return end
    if not targetCF then return end
    
    local hrp = getHRP()
    if not hrp then return end
    
    stopActive()
    isActive = true
    
    speed = speed or Deps.Config.get("TeleportSpeed") or 300
    
    local dist = (targetCF.Position - hrp.Position).Magnitude
    if dist < 3 then
        isActive = false
        return
    end
    
    if hrp.Anchored then
        hrp.Anchored = false
        task.wait()
    end
    
    tpPart.CFrame = hrp.CFrame
    
    local duration = math.clamp(dist / speed, 0.05, 5)
    local TweenService = game:GetService("TweenService")
    
    activeTween = TweenService:Create(
        tpPart,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = targetCF }
    )
    
    activeConn = game:GetService("RunService").Heartbeat:Connect(function()
        if hrp and hrp.Parent then
            hrp.CFrame = tpPart.CFrame
        end
    end)
    
    activeTween:Play()
    activeTween.Completed:Wait()
    
    stopActive()
end

function Teleporter.toMob(mob, height, speed)
    if not mob or not mob.Parent then return end
    
    local hrp = getHRP()
    if not hrp then return end
    
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not mobHRP then return end
    
    height = height or Deps.Config.get("MobHeight") or 20
    
    local targetCF = mobHRP.CFrame * CFrame.new(0, height, 0)
    Teleporter.toPosition(targetCF, speed)
end

function Teleporter.toMobPosition(position, height, speed)
    if not position then return end
    
    height = height or Deps.Config.get("MobHeight") or 20
    
    local targetCF = CFrame.new(position) * CFrame.new(0, height, 0)
    Teleporter.toPosition(targetCF, speed)
end

function Teleporter.stop()
    stopActive()
end

function Teleporter.isTeleporting()
    return isActive
end

function Teleporter.destroy()
    stopActive()
    if tpPart and tpPart.Parent then
        tpPart:Destroy()
    end
    tpPart = nil
end

return Teleporter