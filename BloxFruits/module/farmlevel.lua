local FarmLevel = {}

local Deps = {}

local farmThread = nil
local farmRunning = false
local currentMob = nil

function FarmLevel.init(deps)
    Deps = deps or {}
end

local function getPlayer()
    return game:GetService("Players").LocalPlayer
end

local function getHRP()
    local plr = getPlayer()
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getLevel()
    local plr = getPlayer()
    if not plr or not plr:FindFirstChild("Data") then return 1 end
    local lvl = plr.Data:FindFirstChild("Level")
    return lvl and lvl.Value or 1
end

local function bringMobs(quest)
    if not Deps.Config.get("BringMob") then return end
    if not quest then return end
    
    local hrp = getHRP()
    if not hrp then return end
    
    local mobs = Deps.Detector.getAllMobsInRange(quest.mob, 250)
    if #mobs == 0 then return end
    
    local TweenService = game:GetService("TweenService")
    local targetPos = hrp.Position
    
    local count = 0
    for _, mob in ipairs(mobs) do
        if count >= 5 then break end
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
        if mobHRP and not mobHRP:GetAttribute("Bringing") then
            mobHRP:SetAttribute("Bringing", true)
            count = count + 1
            
            local dist = (mobHRP.Position - targetPos).Magnitude
            local duration = math.clamp(dist / 500, 0.2, 1.5)
            
            local tween = TweenService:Create(
                mobHRP,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { CFrame = CFrame.new(targetPos) }
            )
            
            tween:Play()
            tween.Completed:Once(function()
                if mobHRP and mobHRP.Parent then
                    mobHRP:SetAttribute("Bringing", false)
                end
            end)
        end
    end
end

local function killMob(mob)
    if not mob or not mob.Parent then return end
    
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not mobHRP then return end
    
    local height = Deps.Config.get("MobHeight") or 20
    local speed = Deps.Config.get("TeleportSpeed") or 300
    
    Deps.Weapon.equip()
    Deps.Teleporter.toMob(mob, height, speed)
end

local function handleQuest()
    local quest = Deps.Quest.getCurrent()
    if not quest then return nil end
    
    if not Deps.Quest.hasQuest() then
        if Deps.Config.get("AutoQuest") then
            local hrp = getHRP()
            if hrp and quest.npcPos then
                local dist = (hrp.Position - quest.npcPos.Position).Magnitude
                if dist > 15 then
                    Deps.Teleporter.toPosition(quest.npcPos)
                    return nil
                else
                    task.wait(1)
                    Deps.Quest.accept()
                    return nil
                end
            end
        end
        return nil
    end
    
    if not Deps.Quest.isCorrectQuest(quest.mob) then
        Deps.Quest.abandon()
        task.wait(0.5)
        return nil
    end
    
    return quest
end

function FarmLevel.start()
    if farmRunning then return end
    farmRunning = true
    
    farmThread = task.spawn(function()
        while farmRunning do
            if not Deps.Config.get("AutoFarmLevel") then
                task.wait(0.5)
                continue
            end
            
            pcall(function()
                local quest = handleQuest()
                if not quest then
                    task.wait(0.5)
                    return
                end
                
                if Deps.Config.get("BringMob") then
                    bringMobs(quest)
                end
                
                if currentMob and Deps.Detector.isAlive(currentMob) then
                    killMob(currentMob)
                else
                    local nearest = Deps.Detector.getNearestMob(quest.mob)
                    
                    if nearest then
                        currentMob = nearest
                        killMob(currentMob)
                    else
                        currentMob = nil
                        if quest.mobPos then
                            Deps.Teleporter.toPosition(quest.mobPos)
                        end
                    end
                end
            end)
            
            task.wait(0.15)
        end
    end)
end

function FarmLevel.stop()
    farmRunning = false
    currentMob = nil
    if farmThread then
        pcall(function() task.cancel(farmThread) end)
        farmThread = nil
    end
end

function FarmLevel.isRunning()
    return farmRunning
end

return FarmLevel