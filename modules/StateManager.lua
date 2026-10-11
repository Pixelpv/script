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

local function qualquerFarmAtivo()
    return NS.Config.autoFarmLevel or NS.Config.farmNearest
end

local function getModo()
    if NS.Config.autoFarmLevel then return "level" end
    if NS.Config.farmNearest then return "nearest" end
    return nil
end

-- ============================================================
-- STOPPED
-- ============================================================
StateManager.onEnter["STOPPED"] = function()
    pcall(function()
        NS.MovementManager.stopHover()
        NS.MovementManager.stopFly()
    end)
end

-- ============================================================
-- STARTING — Ativa buffs e vai pro FARMING
-- ============================================================
StateManager.onEnter["STARTING"] = function()
    if not qualquerFarmAtivo() then
        StateManager.setState("STOPPED")
        return
    end

    -- Ativa buffs uma vez
    if NS.Config.autoBuso or NS.Config.autoKen 
    or NS.Config.autoRaceV3 or NS.Config.autoRaceV4 then
        pcall(function()
            NS.BuffManager.applyOnce()
        end)
    end

    StateManager.setState("FARMING")
end

-- ============================================================
-- FARMING — Loop principal
-- ============================================================
StateManager.onEnter["FARMING"] = function()
    task.spawn(function()
        local lastQuestCheck = 0
        local lastEquipCheck = 0

        while StateManager.currentState == "FARMING" do

            local modo = getModo()
            if not modo then
                StateManager.setState("STOPPED")
                return
            end

            -- ============================================
            -- VERIFICA QUEST A CADA 3s
            -- ============================================
            if NS.Config.autoQuest and (tick() - lastQuestCheck > 3) then
                lastQuestCheck = tick()
                local quest = NS.LevelManager.getQuestRange()
                if quest and not NS.QuestManager.matchesCurrentQuest(quest) then
                    NS.Logger.log("Quest desatualizada, re-aceitando...")
                    NS.QuestManager.acceptQuest(quest)
                    task.wait(0.5)
                end
            end

            -- ============================================
            -- VERIFICA ARMA A CADA 2s
            -- ============================================
            if NS.Config.autoEquip and (tick() - lastEquipCheck > 2) then
                lastEquipCheck = tick()
                pcall(function()
                    NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
                end)
            end

            -- ============================================
            -- ACHA MOB
            -- ============================================
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
                NS.Logger.log("Nenhum mob disponível...")
                NS.MovementManager.stopHover()
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

            -- ============================================
            -- DIST > 30: VOA ATÉ O MOB
            -- ============================================
            if distToEnemy > 30 then
                NS.MovementManager.stopHover()
                pcall(function()
                    NS.MovementManager.tp(
                        enemyRoot.CFrame * CFrame.new(0, NS.Config.farmHeight or 20, 0),
                        NS.Config.tweenSpeed or 300
                    )
                end)
                task.wait(0.2)
                continue
            end

            -- ============================================
            -- DIST <= 30: BRING MOB + ATTACK
            -- ============================================
            NS.Logger.log("Atacando:", enemy.Name, "| dist:", math.floor(distToEnemy))

            -- 1. Bring Mob: puxa o mob pra baixo de você
            if NS.Config.bringMob then
                pcall(function()
                    NS.MovementManager.bringMob(enemy)
                end)
            end

            -- 2. Fica em cima (CFrame direto, SEM BodyPosition)
            pcall(function()
                local targetPos = enemyRoot.Position + Vector3.new(0, NS.Config.farmHeight or 20, 0)
                hrp.CFrame = CFrame.new(targetPos)
            end)

            -- 3. Ataca
            pcall(function()
                NS.CombatManager.attack()
            end)

            task.wait(NS.Config.attackDelay or 0.1)
        end
    end)
end

-- ============================================================
-- RECOVERING
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

    pcall(function()
        NS.CombatManager.startKillAura()
    end)

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
