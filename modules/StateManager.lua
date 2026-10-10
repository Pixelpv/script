local NS = getgenv().AutoFarmBF

local StateManager = {}
StateManager.currentState = "IDLE"
StateManager.previousState = nil
StateManager.onEnter = {}
StateManager.onExit = {}

StateManager.transitions = {
    IDLE            = {"CHECKING_LEVEL", "RECOVERING"},
    CHECKING_LEVEL  = {"ACCEPTING_QUEST", "SEEKING_TARGET", "RECOVERING", "IDLE"},
    ACCEPTING_QUEST = {"SEEKING_TARGET", "RECOVERING", "IDLE"},
    SEEKING_TARGET  = {"COMBAT", "CHECKING_LEVEL", "RECOVERING", "IDLE"},
    COMBAT          = {"SEEKING_TARGET", "CHECKING_LEVEL", "RECOVERING", "IDLE"},
    RECOVERING      = {"CHECKING_LEVEL", "IDLE"},
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

StateManager.onEnter["IDLE"] = function() end

StateManager.onEnter["CHECKING_LEVEL"] = function()
    if not NS.Config.autoFarmLevel then
        StateManager.setState("IDLE")
        return
    end
    local quest = NS.LevelManager.getQuestRange()
    if not quest then
        StateManager.setState("IDLE")
        return
    end
    if NS.Config.autoQuest and not NS.QuestManager.matchesCurrentQuest(quest) then
        StateManager.setState("ACCEPTING_QUEST")
    else
        StateManager.setState("SEEKING_TARGET")
    end
end

StateManager.onEnter["ACCEPTING_QUEST"] = function()
    local quest = NS.LevelManager.getQuestRange()
    if quest then
        NS.QuestManager.acceptQuest(quest)
        task.wait(0.5)
    end
    StateManager.setState("SEEKING_TARGET")
end

StateManager.onEnter["SEEKING_TARGET"] = function()
    task.spawn(function()
        while StateManager.currentState == "SEEKING_TARGET" do
            if not NS.Config.autoFarmLevel then
                StateManager.setState("IDLE")
                return
            end
            local quest = NS.LevelManager.getQuestRange()
            local enemy
            if quest and quest.enemy then
                enemy = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
            end
            if not enemy then enemy = NS.TargetManager.findNearest() end
            if enemy then
                StateManager.setState("COMBAT")
                return
            end
            task.wait(0.3)
        end
    end)
end

StateManager.onEnter["COMBAT"] = function()
    task.spawn(function()
        while StateManager.currentState == "COMBAT" do
            if not NS.Config.autoFarmLevel then
                StateManager.setState("IDLE")
                return
            end
            local quest = NS.LevelManager.getQuestRange()
            local enemy
            if quest and quest.enemy then
                enemy = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
            end
            if not enemy then enemy = NS.TargetManager.findNearest() end
            if not enemy then
                StateManager.setState("SEEKING_TARGET")
                return
            end
            if NS.Config.hoverEnabled then
                NS.MovementManager.hoverAbove(enemy.HumanoidRootPart, NS.Config.hoverHeight)
            else
                NS.MovementManager.teleportTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
            end
            NS.CombatManager.attack()
            task.wait(NS.Config.attackDelay)
        end
    end)
end

StateManager.onEnter["RECOVERING"] = function()
    NS.MovementManager.stopFly()
    task.wait(3)
    StateManager.setState("CHECKING_LEVEL")
end

function StateManager.init()
    NS.HealthManager.onDeath(function()
        StateManager.setState("RECOVERING")
    end)
    NS.HealthManager.onRespawn(function()
        if NS.Config.autoFarmLevel then
            StateManager.setState("CHECKING_LEVEL")
        end
    end)
    NS.LevelManager.onLevelUp(function()
        if NS.Config.autoFarmLevel then
            StateManager.currentState = "SEEKING_TARGET"
            StateManager.setState("CHECKING_LEVEL")
        end
    end)
    NS.CombatManager.startKillAura()

    task.spawn(function()
        while true do
            task.wait(2)
            if NS.Config.autoFarmLevel
            and StateManager.getState() == "IDLE"
            and NS.HealthManager.isAlive() then
                StateManager.setState("CHECKING_LEVEL")
            end
        end
    end)
end

return StateManager
