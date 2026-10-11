local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local BuffManager = {}
BuffManager._running = false

local function getCommF()
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    return R and R:FindFirstChild("CommF_")
end

local function getCommE()
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    return R and R:FindFirstChild("CommE_")
end

local function hasBuso()
    local char = player.Character
    return char and char:FindFirstChild("HasBuso") ~= nil
end

function BuffManager.activateBuso()
    if hasBuso() then return true end
    local CommF = getCommF()
    if not CommF then return false end
    pcall(function() CommF:InvokeServer("Buso") end)
    return true
end

function BuffManager.activateKen()
    local CommE = getCommE()
    if not CommE then return false end
    pcall(function() CommE:FireServer("Ken", true) end)
    return true
end

function BuffManager.activateRaceV3()
    local CommE = getCommE()
    if not CommE then return false end
    pcall(function() CommE:FireServer("ActivateAbility") end)
    return true
end

function BuffManager.activateRaceV4()
    local char = player.Character
    if not char then return false end
    local re = char:FindFirstChild("RaceEnergy")
    if re and re.Value == 1 then
        VirtualInputManager:SendKeyEvent(true, "Y", false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, "Y", false, game)
    end
    return true
end

function BuffManager.apply()
    if NS.Config.autoBuso then BuffManager.activateBuso() end
    if NS.Config.autoKen then BuffManager.activateKen() end
    if NS.Config.autoRaceV3 then BuffManager.activateRaceV3() end
    if NS.Config.autoRaceV4 then BuffManager.activateRaceV4() end
end

function BuffManager.start()
    if BuffManager._running then return end
    BuffManager._running = true
    task.spawn(function()
        while BuffManager._running do
            task.wait(1)
            if NS.Config.autoFarmLevel or NS.Config.farmNearest then
                pcall(BuffManager.apply)
            end
        end
    end)
end

function BuffManager.applyOnce()
    pcall(BuffManager.apply)
    task.wait(0.3)
end

function BuffManager.stop() BuffManager._running = false end

return BuffManager
