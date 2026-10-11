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

local function qualquerFarmAtivo()
    return NS.Config.autoFarmLevel or NS.Config.farmNearest
end

-- Decide qual modo usar (mutuamente exclusivo)
local function getModo()
    if NS.Config.autoFarmLevel then return "level" end
    if NS.Config.farmNearest then return "nearest" end
    return nil
end

-- ============================================================
-- ESTADOS
-- ============================================================

StateManager.onEnter["STOPPED"] = function() end

StateManager.onEnter["STARTING"] = function()
    if not qualquerFarmAtivo() then
        StateManager.setState("STOPPED")
        return
    end

    -- Auto Quest só age se Auto Quest estiver ligado
    if NS.Config.autoQuest then
        local quest = NS.LevelManager.getQuestRange()
        if quest and not NS.QuestManager.matchesCurrentQuest(quest) then
            StateManager.setState("GET_QUEST")
            return
        end
    end

    StateManager.setState("FARMING")
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

            local modo = getModo()
            if not modo then
                StateManager.setState("STOPPED")
                return
            end

            local enemy, dist

            -- ── MODO LEVEL ──
            if modo == "level" then
                local quest = NS.LevelManager.getQuestRange()
                if quest and quest.enemy then
                    enemy, dist = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
                end
                -- Se a quest não tem mob definido, cai pro nearest só pra não travar
                if not enemy then
                    enemy, dist = NS.TargetManager.findNearest()
                end
            end

            -- ── MODO NEAREST ──
            if modo == "nearest" then
                enemy, dist = NS.TargetManager.findNearest()
            end

            if not enemy then
                NS.Logger.log("Nenhum mob disponível...")
                task.wait(0.5)
                continue
            end

            NS.Logger.log("Atacando:", enemy.Name, "| modo:", modo, "| dist:", math.floor(dist or 0))

            if NS.Config.autoEquip then
                NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
            end

            if NS.Config.bringMob then
                NS.MovementManager.bringMob(enemy)
            end

            if NS.Config.bringMob then
                NS.MovementManager.hoverAbove(enemy.HumanoidRootPart, NS.Config.farmHeight)
            else
                NS.MovementManager.standNear(
                    enemy.HumanoidRootPart,
                    NS.Config.farmDistance,
                    NS.Config.farmHeight
                )
            end

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
        if qualquerFarmAtivo() then
            StateManager.setState("STARTING")
        end
    end)

    NS.LevelManager.onLevelUp(function()
        if qualquerFarmAtivo() then
            StateManager.currentState = "FARMING"
            StateManager.setState("STARTING")
        end
    end)

    NS.CombatManager.startKillAura()

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
