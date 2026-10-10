local NS = getgenv().AutoFarmBF
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local CombatManager = {}
CombatManager._auraRunning = false

function CombatManager.attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0, 0))
end

function CombatManager.useSkill(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

function CombatManager.useAllSkills()
    for _, key in ipairs({"Z", "X", "C", "V"}) do
        CombatManager.useSkill(key)
    end
end

function CombatManager.startKillAura()
    if CombatManager._auraRunning then return end
    CombatManager._auraRunning = true
    task.spawn(function()
        while CombatManager._auraRunning do
            task.wait(NS.Config.attackDelay)
            if not NS.Config.killAura then continue end
            local targets = NS.TargetManager.getTargetsInRange(NS.Config.killAuraRange)
            for _, mob in ipairs(targets) do
                if NS.Config.hoverEnabled then
                    NS.MovementManager.hoverAbove(mob.HumanoidRootPart, NS.Config.hoverHeight)
                end
                CombatManager.attack()
            end
        end
    end)
end

function CombatManager.stopKillAura()
    CombatManager._auraRunning = false
end

return CombatManager
