local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local TargetManager = {}

-- Coleta mobs de vários containers possíveis
local function getAllMobs()
    local mobs = {}
    local seen = {}

    local function scan(container)
        if not container then return end
        for _, obj in ipairs(container:GetChildren()) do
            if not seen[obj] and obj:FindFirstChild("Humanoid") then
                seen[obj] = true
                table.insert(mobs, obj)
            end
            -- Se for Model/Folder, varre um nível abaixo
            if (obj:IsA("Model") or obj:IsA("Folder")) and not obj:FindFirstChild("Humanoid") then
                for _, child in ipairs(obj:GetChildren()) do
                    if not seen[child] and child:FindFirstChild("Humanoid") then
                        seen[child] = true
                        table.insert(mobs, child)
                    end
                end
            end
        end
    end

    scan(workspace)
    scan(workspace:FindFirstChild("Enemies"))
    scan(workspace:FindFirstChild("Characters"))
    scan(workspace:FindFirstChild("NPCs"))

    return mobs
end

TargetManager.getAllMobs = getAllMobs

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
    for _, mob in ipairs(getAllMobs()) do
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
    for _, mob in ipairs(getAllMobs()) do
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
    for _, mob in ipairs(getAllMobs()) do
        if TargetManager.isValidTarget(mob) then
            local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist <= range then table.insert(list, mob) end
        end
    end
    return list
end

return TargetManager
