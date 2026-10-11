local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local QuestManager = {}

local function getCommF()
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    return R and R:FindFirstChild("CommF_")
end

function QuestManager.hasActiveQuest()
    local ok, res = pcall(function()
        return player.PlayerGui.Main.Quest.Visible
    end)
    return ok and res
end

function QuestManager.getActiveQuestName()
    local ok, res = pcall(function()
        if player.PlayerGui.Main.Quest.Visible then
            return player.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
        end
    end)
    return ok and res or nil
end

function QuestManager.acceptQuest(questData)
    if not questData then return false end
    local CommF = getCommF()
    if not CommF then return false end

    local ok, err = pcall(function()
        CommF:InvokeServer("StartQuest", questData.quest, questData.num)
    end)
    if not ok then
        NS.Logger.warn("Falha ao aceitar quest:", err)
        return false
    end
    return true
end

function QuestManager.abandonQuest()
    local CommF = getCommF()
    if not CommF then return end
    pcall(function() CommF:InvokeServer("
