function Combat.fastAttack()
    if fastAttackRunning then return end
    fastAttackRunning = true
    
    fastAttackThread = task.spawn(function()
        local attackRemote, hitRemote = getAttackRemotes()
        if not attackRemote or not hitRemote then
            fastAttackRunning = false
            return
        end
        
        while fastAttackRunning do
            if not Deps.Config.get("AutoFarmLevel") then
                task.wait(0.5)
                continue
            end
            if not Deps.Config.get("FastAttack") then
                task.wait(0.5)
                continue
            end
            
            local char = getPlayer().Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local tool = getEquippedTool()
                    if tool and tool.ToolTip ~= "Gun" then
                        local enemies, basePart = collectEnemiesInRange(100)
                        if #enemies > 0 and basePart then
                            pcall(function()
                                attackRemote:FireServer(0)
                                hitRemote:FireServer(basePart, enemies)
                            end)
                        end
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end

function Combat.autoClick()
    if autoClickRunning then return end
    autoClickRunning = true
    
    autoClickThread = task.spawn(function()
        while autoClickRunning do
            if not Deps.Config.get("AutoFarmLevel") then
                task.wait(0.5)
                continue
            end
            if not Deps.Config.get("AutoClick") then
                task.wait(0.5)
                continue
            end
            
            local char = getPlayer().Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and char:FindFirstChildOfClass("Tool") then
                    local vu = game:GetService("VirtualUser")
                    pcall(function()
                        vu:CaptureController()
                        vu:Button1Down(Vector2.new(1280, 672))
                    end)
                end
            end
            task.wait(0.1)
        end
    end)
end