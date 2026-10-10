local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local TargetManager = {}

local EnemiesFolder = workspace:WaitForChild("Enemies")

local function isValidEnemy(enemy)
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return false end
    if humanoid.Health <= 0 then return false end
    if enemy == player.Character then return false end
    if Players:GetPlayerFromCharacter(enemy) then return false end
    return true
end

local function scanEnemies(origin, maxDistance, nameFilter)
    if not origin then return nil, math.huge end
    local nearest, nearestDist = nil, maxDistance or math.huge
    local lowerFilter = nameFilter and nameFilter:lower() or nil

    for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
        if isValidEnemy(enemy) then
            local root = enemy.HumanoidRootPart
            local distance = (root.Position - origin).Magnitude
            if distance < nearestDist then
                if not lowerFilter or enemy.Name:lower():find(lowerFilter, 1, true) then
                    nearestDist = distance
                    nearest = enemy
                end
            end
        end
    end

    return nearest, nearestDist
end

function TargetManager.findNearest(maxDistance)
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return nil end
    return scanEnemies(hrp.Position, maxDistance)
end

function TargetManager.findNearestQuestEnemy(enemyName, maxDistance)
    if not enemyName then return TargetManager.findNearest(maxDistance) end
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return nil end
    return scanEnemies(hrp.Position, maxDistance, enemyName)
end

function TargetManager.getTargetsInRange(range)
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return {} end
    local list = {}
    for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
        if isValidEnemy(enemy) then
            local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist <= range then table.insert(list, enemy) end
        end
    end
    return list
end

TargetManager.GetNearestEnemy = function(origin, maxDistance)
    return scanEnemies(origin, maxDistance)
end

return TargetManager
