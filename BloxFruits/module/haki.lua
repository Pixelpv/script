local Haki = {}

local Deps = {}

local busoThread = nil
local busoRunning = false

function Haki.init(deps)
    Deps = deps or {}
end

local function getPlayer()
    return game:GetService("Players").LocalPlayer
end

local function getChar()
    return getPlayer().Character
end

local function getCommF()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    return remotes:FindFirstChild("CommF_")
end

function Haki.hasBuso()
    local char = getChar()
    if not char then return false end
    return char:FindFirstChild("HasBuso") ~= nil
end

function Haki.activateBuso()
    local CommF = getCommF()
    if not CommF then return false end
    
    local ok = pcall(function()
        CommF:InvokeServer("Buso")
    end)
    
    return ok
end

function Haki.startBuso()
    if busoRunning then return end
    busoRunning = true
    
    busoThread = task.spawn(function()
        while busoRunning do
            if not Deps.Config.get("AutoFarmLevel") then
                task.wait(0.5)
                continue
            end
            if not Deps.Config.get("AutoBusoHaki") then
                task.wait(0.5)
                continue
            end
            
            local char = getChar()
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not Haki.hasBuso() then
                        Haki.activateBuso()
                    end
                end
            end
            task.wait(1)
        end
    end)
end

function Haki.stopBuso()
    busoRunning = false
    if busoThread then
        pcall(function() task.cancel(busoThread) end)
        busoThread = nil
    end
end

function Haki.isRunning()
    return busoRunning
end

return Haki