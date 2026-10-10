local NS = getgenv().AutoFarmBF

local StateManager = {}
StateManager.currentState = "STOPPED"
StateManager.previousState = nil
StateManager.onEnter = {}
StateManager.onExit = {}

StateManager.transitions = {
    STOPPED     = {"STARTING", "RECOVERING"},
    STARTING    = {"GET_QUEST", "FARMING", "RECOVERING", "STOPPED"},
    GET_QUEST   = {"FARMING", "RECOVERING", "STOPPED"},
    FARMING     = {"STARTING", "RECOVERING", "STOPPED"},
    RECOVERING  = {"STARTING", "STOPPED"},
}

function StateManager.canTransition(from, to)
    local allowed = StateManager.transitions[from]
    if not allowed then return false end
    for _, s in ipairs(allowed) do
        if s == to then return true end
    end
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

function StateManager.getState()
    return StateManager.currentState
end

-- ============================================================
-- ESTADOS
-- ============================================================

StateManager.onEnter["STOPPED"] = function() end

StateManager.onEnter["STARTING"] = function()
    if not NS.Config.autoFarmLevel then
        StateManager.setState("STOPPED")
        return
    end

    local quest = NS.LevelManager.getQuestRange()
    if not quest then
        NS.Logger.warn("Nenhuma quest para o nível atual")
        StateManager.setState("STOPPED")
        return
    end

    if NS.Config.autoQuest and not NS.QuestManager.matchesCurrentQuest(quest) then
        StateManager.setState("GET_QUEST")
    else
        StateManager.setState("FARMING")
    end
end

StateManager.onEnter["GET_QUEST"] = function()
    local quest = NS.LevelManager.getQuestRange()
    if quest then
        NS.QuestManager.acceptQuest(quest)
        task.wait(0.5)
    end
    StateManager.setState("FARMING")
end

StateManager.onEnter["FARMING"] = function()
    task.spawn(function()
        while StateManager.currentState == "FARMING" do
            if not NS.Config.autoFarmLevel then
                StateManager.setState("STOPPED")
                return
            end

            local quest = NS.LevelManager.getQuestRange()
            local enemy, dist

            -- Prioridade: inimigo da quest (se autoQuest ativo)
            if NS.Config.autoQuest and quest and quest.enemy then
                enemy, dist = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
            end

            -- Fallback: qualquer inimigo próximo (Farm Nearest)
            if not enemy and NS.Config.farmNearest then
                enemy, dist = NS.TargetManager.findNearest(NS.Config.farmRange)
            end

            -- Último fallback: qualquer inimigo (garante que não trave)
            if not enemy then
                enemy, dist = NS.TargetManager.findNearest(NS.Config.farmRange)
            end

            if not enemy then
                NS.Logger.log("Sem inimigos em alcance...")
                task.wait(0.5)
                continue
            end

            NS.Logger.log("Atacando:", enemy.Name, "dist:", math.floor(dist))

            -- Auto Equip
            if NS.Config.autoEquip then
                NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
            end

            -- Bring Mob: puxa o mob até você
            if NS.Config.bringMob then
                NS.MovementManager.bringMob(enemy)
            end

            -- Movimento: hover (em cima) ou stand (na frente)
            if NS.Config.bringMob then
                NS.MovementManager.hoverAbove(
                    enemy.HumanoidRootPart,
                    NS.Config.farmHeight
                )
            else
                NS.MovementManager.standNear(
                    enemy.HumanoidRootPart,
                    NS.Config.farmDistance,
                    NS.Config.farmHeight
                )
            end

            -- Atacar
            NS.CombatManager.attack()

            task.wait(NS.Config.attackDelay)
        end
    end)
end

StateManager.onEnter["RECOVERING"] = function()
    NS.MovementManager.stopFly()
    NS.MovementManager.stopHover()
    task.wait(3)
    StateManager.setState("STARTING")
end

-- ============================================================
-- INIT
-- ============================================================
function StateManager.init()
    NS.HealthManager.onDeath(function()
        StateManager.setState("RECOVERING")
    end)

    NS.HealthManager.onRespawn(function()
        if NS.Config.autoFarmLevel then
            StateManager.setState("STARTING")
        end
    end)

    NS.LevelManager.onLevelUp(function()
        if NS.Config.autoFarmLevel then
            StateManager.currentState = "FARMING"
            StateManager.setState("STARTING")
        end
    end)

    NS.CombatManager.startKillAura()

    -- Watchdog
    task.spawn(function()
        while true do
            task.wait(2)
            if NS.Config.autoFarmLevel
            and StateManager.getState() == "STOPPED"
            and NS.HealthManager.isAlive() then
                StateManager.setState("STARTING")
            end
        end
    end)
end

return StateManager
