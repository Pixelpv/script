local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local LevelManager = {}

LevelManager.questTable = {
    {min=0,   max=9,   quest="BanditQuest1", num=1, enemy="Bandit",             island="Starter Island"},
    {min=10,  max=14,  quest="JungleQuest",  num=1, enemy="Monkey",             island="Jungle"},
    {min=15,  max=29,  quest="JungleQuest",  num=2, enemy="Gorilla",            island="Jungle"},
    {min=30,  max=39,  quest="BuggyQuest1",  num=1, enemy="Pirate",             island="Pirate Village"},
    {min=40,  max=54,  quest="BuggyQuest1",  num=2, enemy="Brute",              island="Pirate Village"},
    {min=55,  max=59,  quest="BuggyQuest1",  num=3, enemy="Chef",               island="Pirate Village"},
    {min=60,  max=74,  quest="DesertQuest",  num=1, enemy="Desert Bandit",      island="Desert"},
    {min=75,  max=89,  quest="DesertQuest",  num=2, enemy="Desert Officer",     island="Desert"},
    {min=90,  max=99,  quest="SnowQuest",    num=1, enemy="Snow Bandit",        island="Frozen Village"},
    {min=100, max=104, quest="SnowQuest",    num=2, enemy="Snowman",            island="Frozen Village"},
    {min=105, max=119, quest="SnowQuest",    num=3, enemy="Yeti",               island="Frozen Village"},
    {min=120, max=129, quest="MarineQuest2", num=1, enemy="Chief Petty Officer",island="Marine Ford"},
    {min=130, max=149, quest="MarineQuest2", num=2, enemy="Vice Admiral",       island="Marine Ford"},
    {min=150, max=174, quest="SkyQuest",     num=1, enemy="Sky Bandit",         island="Skylands"},
    {min=175, max=189, quest="SkyQuest",     num=2, enemy="Dark Master",        island="Skylands"},
}

LevelManager._onLevelUp = {}

function LevelManager.getLevel()
    if player.Data and player.Data.Level then
        return player.Data.Level.Value
    end
    return 0
end

function LevelManager.getQuestRange()
    local lvl = LevelManager.getLevel()
    for _, q in ipairs(LevelManager.questTable) do
        if lvl >= q.min and lvl <= q.max then return q end
    end
    return nil
end

function LevelManager.isMaxLevel()
    return LevelManager.getLevel() >= 2450
end

function LevelManager.getProgress()
    local q = LevelManager.getQuestRange()
    if not q then return 0 end
    return ((LevelManager.getLevel() - q.min) / (q.max - q.min)) * 100
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
