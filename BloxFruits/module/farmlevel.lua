local FarmLevel = {}

local Deps = {}

local farmThread = nil
local farmRunning = false
local currentMob = nil
local lastAcceptTime = 0
local lastBringTime = 0

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

local function bringMobs(quest)
    if not Deps.Config.get("BringMob") then return end
    if not quest then return end
    
    local hrp = getHRP()
    if not hrp then return end
    
    local mobs = Deps.Detector.getAllMobsInRange(quest.mob, 350)
    if #mobs == 0 then return end
    
    local TweenService = game:GetService("TweenService")
    local targetPos = hrp.Position
    
    local count = 0
    for _, mob in ipairs(mobs) do
        if count >= 8 then break end
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
        if mobHRP and not mobHRP:GetAttribute("Bringing") then
            mobHRP:SetAttribute("Bringing", true)
            count = count + 1
            
            local dist = (mobHRP.Position - targetPos).Magnitude
            if dist < 20 then
                mobHRP:SetAttribute("Bringing", false)
            else
                local duration = math.clamp(dist / 800, 0.1, 1.0)
                
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
end

local function goToMob(mob)
    if not mob or not mob.Parent then return end
    
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not mobHRP then return end
    
    local hrp = getHRP()
    if not hrp then return end
    
    local height = Deps.Config.get("MobHeight") or 20
    local dist = (mobHRP.Position - hrp.Position).Magnitude
    
    if dist < 8 then
        hrp.CFrame = mobHRP.CFrame * CFrame.new(0, height, 0)
    else
        Deps.Teleporter.toMob(mob, height)
    end
end

local function handleQuest()
    local quest = Deps.Quest.getCurrent()
    if not quest then return nil end
    
    local hasQuest = Deps.Quest.hasQuest()
    
    if not hasQuest then
        if not Deps.Config.get("AutoQuest") then return nil end
        
        local hrp = getHRP()
        if not hrp or not quest.npcPos then return nil end
        
        local dist = (hrp.Position - quest.npcPos.Position).Magnitude
        
        if dist > 15 then
            Deps.Teleporter.toPosition(quest.npcPos)
            return nil
        end
        
        local now = tick()
        if now - lastAcceptTime > 3 then
            lastAcceptTime = now
            Deps.Quest.accept()
        end
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
                    task.wait(0.3)
                    return
                end
                
                if Deps.Config.get("BringMob") then
                    local now = tick()
                    if now - lastBringTime > 1.5 then
                        lastBringTime = now
                        task.spawn(function()
                            bringMobs(quest)
                        end)
                    end
                end
                
                local mob = nil
                if currentMob and Deps.Detector.isAlive(currentMob) then
                    mob = currentMob
                else
                    mob = Deps.Detector.getNearestMob(quest.mob)
                    currentMob = mob
                end
                
                if mob then
                    Deps.Weapon.equip()
                    goToMob(mob)
                else
                    currentMob = nil
                    if quest.mobPos then
                        local hrp = getHRP()
                        if hrp then
                            local dist = (hrp.Position - quest.mobPos.Position).Magnitude
                            if dist > 50 then
                                Deps.Teleporter.toPosition(quest.mobPos)
                            end
                        end
                    end
                end
            end)
            
            task.wait(0.1)
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