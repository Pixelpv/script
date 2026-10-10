local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local HealthManager = {}
local _hrp, _humanoid = nil, nil

HealthManager._onDeath = {}
HealthManager._onRespawn = {}

function HealthManager.getHRP()
    if _hrp and _hrp.Parent then return _hrp end
    local char = player.Character
    if char then _hrp = char:FindFirstChild("HumanoidRootPart") end
    return _hrp
end

function HealthManager.getHumanoid()
    if _humanoid and _humanoid.Parent then return _humanoid end
    local char = player.Character
    if char then _humanoid = char:FindFirstChildOfClass("Humanoid") end
    return _humanoid
end

function HealthManager.getHealth()
    local h = HealthManager.getHumanoid()
    return h and h.Health or 0
end

function HealthManager.isAlive()
    return HealthManager.getHealth() > 0
end

function HealthManager.resetCharacter()
    local h = HealthManager.getHumanoid()
    if h then h.Health = 0 end
end

function HealthManager.onDeath(cb) table.insert(HealthManager._onDeath, cb) end
function HealthManager.onRespawn(cb) table.insert(HealthManager._onRespawn, cb) end

local function bindHumanoid(h)
    h.Died:Connect(function()
        for _, cb in ipairs(HealthManager._onDeath) do cb() end
    end)
end

function HealthManager.init()
    if player.Character then
        _humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        _hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if _humanoid then bindHumanoid(_humanoid) end
    end
    player.CharacterAdded:Connect(function(char)
        _humanoid = char:WaitForChild("Humanoid")
        _hrp = char:WaitForChild("HumanoidRootPart")
        bindHumanoid(_humanoid)
        task.wait(0.5)
        for _, cb in ipairs(HealthManager._onRespawn) do cb() end
    end)
end

return HealthManager
