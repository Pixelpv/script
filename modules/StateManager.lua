local NS = getgenv().AutoFarmBF

local StateManager = {}
StateManager.currentState = "STOPPED"
StateManager.previousState = nil
StateManager.onEnter = {}
StateManager.onExit = {}

StateManager.transitions = {
    STOPPED     = {"STARTING", "RECOVERING"},
    STARTING    = {"FARMING", "RECOVERING", "STOPPED"},
    FARMING     = {"STARTING", "RECOVERING", "STOPPED"},
    RECOVERING  = {"STARTING", "STOPPED"},
}

function StateManager.canTransition(from, to)
    local allowed = StateManager.transitions[from]
    if not allowed then return false end
    for _, s in ipairs(allowed) do if s == to then return true end end
    return false
end

function StateManager.setState(newState)
    if StateManager.currentState == newState then return end
    if not StateManager.canTransition(StateManager.currentState, newState) then return end
    if StateManager.onExit[StateManager.currentState] then
        pcall(StateManager.onExit[StateManager.currentState])
    end
    StateManager.previousState = StateManager.currentState
    StateManager.currentState = newState
    NS.Logger.log("Estado:", StateManager.previousState, "->", newState)
    if StateManager.onEnter[newState] then
        pcall(StateManager.onEnter[newState])
    end
end

function StateManager.getState() return StateManager.currentState end

local function qualquerFarmAtivo()
    return NS.Config.autoFarmLevel or NS.Config.farmNearest
end

local function getModo()
    if NS.Config.autoFarmLevel then return "level" end
    if NS.Config.farmNearest then return "nearest" end
    return nil
end

StateManager.onEnter["STOPPED"] = function()
    pcall(function() NS.MovementManager.stopHover() end)
end

StateManager.onEnter["STARTING"] = function()
    if not qualquerFarmAtivo() then
        StateManager.setState("STOPPED")
        return
    end
    if NS.Config.autoBuso or NS.Config.autoKen
    or NS.Config.autoRaceV3 or NS.Config.autoRaceV4 then
        pcall(function() NS.BuffManager.applyOnce() end)
    end
    StateManager.setState("FARMING")
end

StateManager.onEnter["FARMING"] = function()
    task.spawn(function()
        local lastQuestCheck, lastEquipCheck = 0, 0

        while StateManager.currentState == "FARMING" do
            local modo = getModo()
            if not modo then
                StateManager.setState("STOPPED")
                return
            end

            -- Quest check a cada 3s
            if NS.Config.autoQuest and (tick() - lastQuestCheck > 3) then
                lastQuestCheck = tick()
                local quest = NS.LevelManager.getQuestRange()
                if quest and not NS.QuestManager.matchesCurrentQuest(quest) then
                    if quest.needEntrance and NS.MovementManager.requestEntrance then
                        pcall(function()
                            local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
                            CommF:InvokeServer("requestEntrance", quest.needEntrance)
                        end)
                        task.wait(1)
                    end
                    NS.QuestManager.acceptQuest(quest)
                    task.wait(0.5)
                end
            end

            -- Equip check a cada 2s
            if NS.Config.autoEquip and (tick() - lastEquipCheck > 2) then
                lastEquipCheck = tick()
                pcall(function()
                    NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
                end)
            end

            -- Acha mob
            local enemy, dist
            if modo == "level" then
                local quest = NS.LevelManager.getQuestRange()
                if quest and quest.enemy then
                    enemy, dist = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
                end
            end
            if modo == "nearest" then
                enemy, dist = NS.TargetManager.findNearest()
            end

            if not enemy then
                task.wait(0.5)
                continue
            end

            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local hrp = NS.HealthManager.getHRP()
            if not enemyRoot or not hrp then
                task.wait(0.2)
                continue
            end

            local distToEnemy = (enemyRoot.Position - hrp.Position).Magnitude

            -- Voa até o mob (se longe)
            if distToEnemy > 30 then
                pcall(function()
                    NS.MovementManager.tp(
                        enemyRoot.CFrame * CFrame.new(0, NS.Config.farmHeight or 20, 0),
                        NS.Config.tweenSpeed or 300
                    )
                end)
                task.wait(0.2)
                continue
            end

            -- Bring mob
            if NS.Config.bringMob then
                pcall(function() NS.MovementManager.bringMob(enemy) end)
            end

            -- Hover
            pcall(function()
                NS.MovementManager.hoverAbove(enemyRoot, NS.Config.farmHeight or 20)
            end)

            -- Ataca
            pcall(function() NS.CombatManager.attack() end)

            task.wait(NS.Config.attackDelay or 0.1)
        end
    end)
end

StateManager.onEnter["RECOVERING"] = function()
    pcall(function()
        NS.MovementManager.stopHover()
        NS.MovementManager.stopFly()
    end)
    task.wait(3)
    StateManager.setState("STARTING")
end

function StateManager.init()
    NS.HealthManager.onDeath(function()
        StateManager.setState("RECOVERING")
    end)
    NS.HealthManager.onRespawn(function()
        if qualquerFarmAtivo() then StateManager.setState("STARTING") end
    end)
    NS.LevelManager.onLevelUp(function()
        if qualquerFarmAtivo() then
            StateManager.currentState = "FARMING"
            StateManager.setState("STARTING")
        end
    end)
    pcall(function() NS.CombatManager.startKillAura() end)

    task.spawn(function()
        while true do
            task.wait(2)
            if qualquerFarmAtivo()
            and StateManager.getState() == "STOPPED"
            and NS.HealthManager.isAlive() then
                StateManager.setState("STARTING")
            end
        end
    end)
end

return StateManager
