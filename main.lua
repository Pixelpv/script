local BASE = "https://raw.githubusercontent.com/Pixelpv/script/main/"

getgenv().AutoFarmBF = getgenv().AutoFarmBF or {}
local NS = getgenv().AutoFarmBF

local function load(path)
    local url = BASE .. path
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if not ok or not src or #src == 0 then
        error("[AutoFarm] HTTP falhou: " .. path)
    end
    local fn, err = loadstring(src)
    if not fn then
        error("[AutoFarm] Syntax error em " .. path .. ": " .. tostring(err))
    end
    local ok2, result = pcall(fn)
    if not ok2 then
        error("[AutoFarm] Runtime error em " .. path .. ": " .. tostring(result))
    end
    return result
end

-- 1. Config
NS.Config = load("config.lua")

-- 2. Data
NS.Data          = NS.Data or {}
NS.Data.Quests   = load("data/quests.lua")
NS.Data.Islands  = load("data/islands.lua")
NS.Data.Tools    = load("data/tools.lua")

-- 3. Logger (agora seguro, porque temos Config)
NS.Logger = load("modules/Logger.lua")

-- 4. Core
NS.HealthManager   = load("modules/HealthManager.lua")
NS.LevelManager    = load("modules/LevelManager.lua")
NS.QuestManager    = load("modules/QuestManager.lua")

-- 5. Dependem de core
NS.TargetManager   = load("modules/TargetManager.lua")
NS.MovementManager = load("modules/MovementManager.lua")
NS.CombatManager   = load("modules/CombatManager.lua")

-- 6. Coordenador
NS.StateManager    = load("modules/StateManager.lua")

NS.Logger.log("Módulos carregados")

-- Init (ordem importa)
NS.HealthManager.init()
NS.LevelManager.init()
NS.QuestManager.init()
NS.StateManager.init()

-- UI
load("ui/FluentUI.lua")

NS.Logger.log("Sistema inicializado")
