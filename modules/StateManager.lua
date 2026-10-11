local NS = getgenv().AutoFarmBF

local StateManager = {}
StateManager.currentState = "STOPPED"
StateManager.previousState = nil
StateManager.onEnter = {}
StateManager.onExit = {}

-- ============================================================
-- TRANSIÇÕES VÁLIDAS
-- ============================================================
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
    if not StateManager.canTransition(StateManager.currentState, newState) then
        NS.Logger.log("Transição bloqueada:", StateManager.currentState, "->", newState)
        return
    end

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
-- HELPERS
-- ============================================================
local function qualquerFarmAtivo()
    return NS.Config.autoFarmLevel or NS.Config.farmNearest
end

local function getModo()
    if NS.Config.autoFarmLevel then return "level" end
    if NS.Config.farmNearest then return "nearest" end
    return nil
end

-- ============================================================
-- ESTADO: STOPPED
-- ============================================================
StateManager.onEnter["STOPPED"] = function()
    pcall(function()
        NS.MovementManager.stopHover()
        NS.MovementManager.stopFly()
    end)
end

-- ============================================================
-- ESTADO: STARTING
-- ============================================================
StateManager.onEnter["STARTING"] = function()
    if not qualquerFarmAtivo() then
        StateManager.setState("STOPPED")
        return
    end

    -- Se Auto Quest está ligado, checa se precisa pegar quest
    if NS.Config.autoQuest then
        local quest = NS.LevelManager.getQuestRange()
        if quest and not NS.QuestManager.matchesCurrentQuest(quest) then
            StateManager.setState("GET_QUEST")
            return
        end
    end

    StateManager.setState("FARMING")
end

-- ============================================================
-- ESTADO: GET_QUEST
-- ============================================================
StateManager.onEnter["GET_QUEST"] = function()
    local quest = NS.LevelManager.getQuestRange()
    if quest then
        NS.QuestManager.acceptQuest(quest)
        task.wait(0.5)
    end
    StateManager.setState("FARMING")
end

-- ============================================================
-- ESTADO: FARMING (o loop principal)
-- ============================================================
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
            end

            -- ── MODO NEAREST ──
            if modo == "nearest" then
                enemy, dist = NS.TargetManager.findNearest()
            end

            if not enemy then
                NS.Logger.log("Nenhum mob disponível...")
                NS.MovementManager.stopHover()
                task.wait(0.5)
                continue
            end

            NS.Logger.log("Atacando:", enemy.Name, "| modo:", modo, "| dist:", math.floor(dist or 0))

            -- 1. BRING MOB: puxa o mob pra baixo de você
            if NS.Config.bringMob then
                pcall(function()
                    NS.MovementManager.bringMob(enemy)
                end)
            end

            -- 2. AUTO EQUIP: equipa a arma escolhida
            if NS.Config.autoEquip then
                pcall(function()
                    NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
                end)
            end

            -- 3. MOVIMENTO: sobe em cima do mob (hover)
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                if NS.Config.hoverEnabled ~= false then
                    pcall(function()
                        NS.MovementManager.hoverAbove(
                            enemyRoot,
                            NS.Config.farmHeight or 20
                        )
                    end)
                else
                    pcall(function()
                        NS.MovementManager.standNear(
                            enemyRoot,
                            NS.Config.farmDistance or 25,
                            NS.Config.farmHeight or 20
                        )
                    end)
                end
            end

            -- 4. ATAQUE
            pcall(function()
                NS.CombatManager.attack()
            end)

            task.wait(NS.Config.attackDelay or 0.1)
        end
    end)
end

-- ============================================================
-- ESTADO: RECOVERING (morreu)
-- ============================================================
StateManager.onEnter["RECOVERING"] = function()
    pcall(function()
        NS.MovementManager.stopHover()
        NS.MovementManager.stopFly()
    end)
    task.wait(3)
    StateManager.setState("STARTING")
end

-- ============================================================
-- INIT
-- ============================================================
function StateManager.init()
    -- Morte
    NS.HealthManager.onDeath(function()
        StateManager.setState("RECOVERING")
    end)

    -- Respawn
    NS.HealthManager.onRespawn(function()
        if qualquerFarmAtivo() then
            StateManager.setState("STARTING")
        end
    end)

    -- Level up
    NS.LevelManager.onLevelUp(function()
        if qualquerFarmAtivo() then
            StateManager.currentState = "FARMING"
            StateManager.setState("STARTING")
        end
    end)

    -- Kill Aura roda em paralelo
    pcall(function()
        NS.CombatManager.startKillAura()
    end)

    -- Watchdog: reinicia se cair em STOPPED sem razão
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

    -- Watchdog 2: limpa hover se farm desligou
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not qualquerFarmAtivo() then
                pcall(function()
                    NS.MovementManager.stopHover()
                end)
            end
        end
    end)

    NS.Logger.log("StateManager inicializado")
end

return StateManager
