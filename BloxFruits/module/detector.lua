local Detector = {}

local Deps = {}

function Detector.init(deps)
    Deps = deps or {}
end

local function getHRP()
    local plr = game:GetService("Players").LocalPlayer
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getEnemiesFolder()
    return workspace:FindFirstChild("Enemies")
end

function Detector.isAlive(mob)
    if not mob or not mob.Parent then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

function Detector.mobExists(name)
    local folder = getEnemiesFolder()
    if not folder then return false end
    for _, mob in ipairs(folder:GetChildren()) do
        if mob.Name == name and Detector.isAlive(mob) then
            return true
        end
    end
    return false
end

function Detector.getMobs(name)
    local folder = getEnemiesFolder()
    if not folder then return {} end
    
    local result = {}
    for _, mob in ipairs(folder:GetChildren()) do
        if mob.Name == name and Detector.isAlive(mob) then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(result, mob)
            end
        end
    end
    return result
end

function Detector.getNearestMob(name)
    local hrp = getHRP()
    if not hrp then return nil end
    
    local folder = getEnemiesFolder()
    if not folder then return nil end
    
    local nearest = nil
    local shortest = math.huge
    
    for _, mob in ipairs(folder:GetChildren()) do
        if mob.Name == name and Detector.isAlive(mob) then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            if mobHRP then
                local dist = (mobHRP.Position - hrp.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = mob
                end
            end
        end
    end
    
    return nearest
end

function Detector.getAllMobsInRange(name, range)
    local hrp = getHRP()
    if not hrp then return {} end
    
    local folder = getEnemiesFolder()
    if not folder then return {} end
    
    local result = {}
    for _, mob in ipairs(folder:GetChildren()) do
        if mob.Name == name and Detector.isAlive(mob) then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            if mobHRP then
                local dist = (mobHRP.Position - hrp.Position).Magnitude
                if dist <= range then
                    table.insert(result, mob)
                end
            end
        end
    end
    return result
end

function Detector.getNPC(name)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local npcs = ReplicatedStorage:FindFirstChild("NPCs")
    if not npcs then return nil end
    
    for _, npc in ipairs(npcs:GetChildren()) do
        if npc.Name == name then
            return npc
        end
    end
    return nil
end

function Detector.getAllQuestMobs(quest)
    if not quest then return {} end
    return Detector.getMobs(quest.mob)
end

function Detector.getNearestQuestMob(quest)
    if not quest then return nil end
    return Detector.getNearestMob(quest.mob)
end

return Detector