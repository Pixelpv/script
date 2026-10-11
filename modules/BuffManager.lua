local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local BuffManager = {}
BuffManager._running = false

-- ============================================================
-- REMOTES
-- ============================================================
local function getCommF()
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    return R and R:FindFirstChild("CommF_")
end

local function getCommE()
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    return R and R:FindFirstChild("CommE_")
end

-- ============================================================
-- BUSO (Haki de Armamento)
-- ============================================================
local function hasBuso()
    local char = player.Character
    if not char then return false end
    return char:FindFirstChild("HasBuso") ~= nil
end

function BuffManager.activateBuso()
    if hasBuso() then return true end
    local CommF = getCommF()
    if not CommF then return false end
    pcall(function()
        CommF:InvokeServer("Buso")
    end)
    return true
end

-- ============================================================
-- KEN (Observation Haki)
-- ============================================================
local function hasKen()
    local char = player.Character
    if not char then return false end
    return CollectionService:HasTag(char, "Ken")
end

function BuffManager.activateKen()
    local CommE = getCommE()
    if not CommE then return false end
    pcall(function()
        CommE:FireServer("Ken", true)
    end)
    return true
end

-- ============================================================
-- RACE V3
-- ============================================================
function BuffManager.activateRaceV3()
    local CommE = getCommE()
    if not CommE then return false end
    pcall(function()
        CommE:FireServer("ActivateAbility")
    end)
    return true
end

-- ============================================================
-- RACE V4
-- ============================================================
function BuffManager.activateRaceV4()
    local char = player.Character
    if not char then return false end
    local raceEnergy = char:FindFirstChild("RaceEnergy")
    if raceEnergy and raceEnergy.Value == 1 then
        VirtualInputManager:SendKeyEvent(true, "Y", false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, "Y", false, game)
    end
    return true
end

-- ============================================================
-- APLICA TODOS OS BUFFS ATIVOS
-- ============================================================
function BuffManager.apply()
    if NS.Config.autoBuso then
        BuffManager.activateBuso()
    end
    if NS.Config.autoKen then
        BuffManager.activateKen()
    end
    if NS.Config.autoRaceV3 then
        BuffManager.activateRaceV3()
    end
    if NS.Config.autoRaceV4 then
        BuffManager.activateRaceV4()
    end
end

-- ============================================================
-- LOOP DE MANUTENÇÃO (roda enquanto farm estiver ativo)
-- ============================================================
function BuffManager.start()
    if BuffManager._running then return end
    BuffManager._running = true

    task.spawn(function()
        while BuffManager._running do
            task.wait(1)

            -- Só aplica se algum farm estiver ativo
            if NS.Config.autoFarmLevel or NS.Config.farmNearest then
                pcall(BuffManager.apply)
            end
        end
    end)

    NS.Logger.log("BuffManager: loop iniciado")
end

function BuffManager.stop()
    BuffManager._running = false
end

-- ============================================================
-- ATIVA BUFFS UMA VEZ (usado pelo StateManager no STARTING)
-- ============================================================
function BuffManager.applyOnce()
    pcall(BuffManager.apply)
    -- Espera um pouco pra garantir que o servidor processou
    task.wait(0.3)
end

return BuffManager
