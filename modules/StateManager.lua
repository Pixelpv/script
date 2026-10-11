local NS = getgenv().AutoFarmBF

local StateManager = {}
StateManager.currentState = "STOPPED"
StateManager.previousState = nil
StateManager.onEnter = {}
StateManager.onExit = {}

StateManager.transitions = {
    STOPPED     = {"STARTING", "RECOVERING"},
    STARTING    = {"GET_QUEST", "EQUIP_WEAPON", "FARMING", "RECOVERING", "STOPPED"},
    GET_QUEST   = {"EQUIP_WEAPON", "FARMING", "RECOVERING", "STOPPED"},
    EQUIP_WEAPON= {"FARMING", "RECOVERING", "STOPPED"},
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
-- STARTING — Ativa buffs, decide próximo passo
-- ============================================================
StateManager.onEnter["STARTING"] = function()
    if not qualquerFarmAtivo() then
        StateManager.setState("STOPPED")
        return
    end

    -- 1. Ativa buffs (Buso, Ken, Race V3/V4)
    if NS.Config.autoBuso or NS.Config.autoKen 
    or NS.Config.autoRaceV3 or NS.Config.autoRaceV4 then
        pcall(function()
            NS.BuffManager.applyOnce()
        end)
    end

    -- 2. Checa se precisa pegar quest
    if NS.Config.autoQuest then
        local quest = NS.LevelManager.getQuestRange()
        if quest and not NS.QuestManager.matchesCurrentQuest(quest) then
            StateManager.setState("GET_QUEST")
            return
        end
    end

    -- 3. Checa se precisa equipar arma
    if NS.Config.autoEquip then
        local char = game.Players.LocalPlayer.Character
        local toolEquipada = char and char:FindFirstChildOfClass("Tool")
        local tipoAtual = toolEquipada and NS.CombatManager.getToolType(toolEquipada)
        if tipoAtual ~= NS.Config.selectWeapon then
            StateManager.setState("EQUIP_WEAPON")
            return
        end
    end

    StateManager.setState("FARMING")
end

-- ============================================================
-- GET_QUEST — Aceita a quest
-- ============================================================
StateManager.onEnter["GET_QUEST"] = function()
    local quest = NS.LevelManager.getQuestRange()
    if quest then
        NS.QuestManager.acceptQuest(quest)
        task.wait(0.5)
    end

    -- Depois de aceitar, checa se precisa equipar
    if NS.Config.autoEquip then
        StateManager.setState("EQUIP_WEAPON")
    else
        StateManager.setState("FARMING")
    end
end

-- ============================================================
-- EQUIP_WEAPON — Equipa a arma escolhida
-- ============================================================
StateManager.onEnter["EQUIP_WEAPON"] = function()
    pcall(function()
        NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
    end)
    task.wait(0.3)
    StateManager.setState("FARMING")
end

-- ============================================================
-- FARMING — Loop principal
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

            -- Acha mob
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
            if not enemyRoot then
                task.wait(0.2)
                continue
            end

            local hrp = NS.HealthManager.getHRP()
            if not hrp then
                task.wait(0.2)
                continue
            end

            local distToEnemy = (enemyRoot.Position - hrp.Position).Magnitude

            NS.Logger.log("Atacando:", enemy.Name, "| dist:", math.floor(distToEnemy))

            -- 1. VOAR até o mob (se longe)
            if distToEnemy > 30 then
                NS.MovementManager.tp(
                    enemyRoot.CFrame * CFrame.new(0, NS.Config.farmHeight or 20, 0),
                    NS.Config.tweenSpeed or 300
                )
                task.wait(0.15)
                continue
            end

            -- 2. BRING MOB (puxa pra baixo)
            if NS.Config.bringMob then
                pcall(function()
                    NS.MovementManager.bringMob(enemy)
                end)
            end

            -- 3. FICAR em cima do mob
            pcall(function()
                NS.MovementManager.hoverAbove(
                    enemyRoot,
                    NS.Config.farmHeight or 20
                )
            end)

            -- 4. ATACAR
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

    -- Watchdog: reinicia se travar em STOPPED
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

    -- Watchdog: limpa hover se farm desligou
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
