local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local TargetManager = {}

function TargetManager.isValidTarget(mob)
    return mob:FindFirstChild("Humanoid")
       and mob:FindFirstChild("HumanoidRootPart")
       and mob.Humanoid.Health > 0
       and mob ~= player.Character
       and not Players:GetPlayerFromCharacter(mob)
end

function TargetManager.findNearest()
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, mob in ipairs(workspace:GetChildren()) do
        if TargetManager.isValidTarget(mob) then
            local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < bestDist then best, bestDist = mob, dist end
        end
    end
    return best, bestDist
end

function TargetManager.findNearestQuestEnemy(enemyName)
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, mob in ipairs(workspace:GetChildren()) do
        if TargetManager.isValidTarget(mob) and mob.Name:lower():find(enemyName:lower()) then
            local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < bestDist then best, bestDist = mob, dist end
        end
    end
    return best, bestDist
end

function TargetManager.getTargetsInRange(range)
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return {} end
    local list = {}
    for _, mob in ipairs(workspace:GetChildren()) do
        if TargetManager.isValidTarget(mob) then
            local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist <= range then table.insert(list, mob) end
        end
    end
    return list
end

return TargetManager
