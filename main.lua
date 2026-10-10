local BASE = "https://raw.githubusercontent.com/Pixelpv/script/main/"

getgenv().AutoFarmBF = getgenv().AutoFarmBF or {}
local NS = getgenv().AutoFarmBF

local function load(path)
    local url = BASE .. path
    local src = game:HttpGet(url)
    local fn = loadstring(src)
    if not fn then error("[AutoFarm] Falha ao carregar: " .. path) end
    return fn()
end

NS.Config          = load("config.lua")

NS.Data            = NS.Data or {}
NS.Data.Quests     = load("data/quests.lua")
NS.Data.Islands    = load("data/islands.lua")
NS.Data.Tools      = load("data/tools.lua")
NS.Logger          = load("modules/Logger.lua")
NS.HealthManager   = load("modules/HealthManager.lua")
NS.LevelManager    = load("modules/LevelManager.lua")
NS.QuestManager    = load("modules/QuestManager.lua")
NS.TargetManager   = load("modules/TargetManager.lua")
NS.MovementManager = load("modules/MovementManager.lua")
NS.CombatManager   = load("modules/CombatManager.lua")
NS.StateManager    = load("modules/StateManager.lua")

NS.Logger.log("Módulos carregados")

NS.HealthManager.init()
NS.LevelManager.init()
NS.QuestManager.init()
NS.StateManager.init()

load("ui/RayfieldUI.lua")

NS.Logger.log("Sistema inicializado")
