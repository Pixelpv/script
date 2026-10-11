local AFK = {}

local Deps = {}

local idledConn = nil
local running = false

function AFK.init(deps)
    Deps = deps or {}
end

local function getPlayer()
    return game:GetService("Players").LocalPlayer
end

function AFK.start()
    if running then return end
    running = true
    
    local plr = getPlayer()
    if not plr then return end
    
    idledConn = plr.Idled:Connect(function()
        if not Deps.Config.get("AutoFarmLevel") then return end
        if not Deps.Config.get("AntiAFK") then return end
        
        local vu = game:GetService("VirtualUser")
        local camera = workspace.CurrentCamera
        
        pcall(function()
            vu:CaptureController()
            vu:Button2Down(Vector2.new(0, 0), camera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), camera.CFrame)
        end)
    end)
end

function AFK.stop()
    running = false
    if idledConn then
        pcall(function() idledConn:Disconnect() end)
        idledConn = nil
    end
end

function AFK.isRunning()
    return running
end

return AFK