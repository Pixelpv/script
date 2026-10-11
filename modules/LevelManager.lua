local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local LevelManager = {}
LevelManager._onLevelUp = {}

function LevelManager.getLevel()
    if player.Data and player.Data.Level then
        return player.Data.Level.Value
    end
    return 0
end

function LevelManager.getSea()
    local lvl = LevelManager.getLevel()
    if lvl >= 1500 then return "Third Sea" end
    if lvl >= 700 then return "Second Sea" end
    return "First Sea"
end

function LevelManager.getQuestRange()
    local lvl = LevelManager.getLevel()
    local sea = LevelManager.getSea()
    local quests = NS.Data.Quests[sea]
    if not quests then return nil end
    for _, q in ipairs(quests) do
        if lvl >= q.min and lvl <= q.max then return q end
    end
    return nil
end

function LevelManager.onLevelUp(cb) table.insert(LevelManager._onLevelUp, cb) end

function LevelManager.init()
    if player.Data and player.Data.Level then
        player.Data.Level.Changed:Connect(function(newLvl)
            for _, cb in ipairs(LevelManager._onLevelUp) do cb(newLvl) end
        end)
    end
end

return LevelManager
