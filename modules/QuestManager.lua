local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local QuestManager = {}

function QuestManager.hasActiveQuest()
    local ok, result = pcall(function()
        return player.PlayerGui.Main.Quest.Visible
    end)
    return ok and result
end

function QuestManager.getActiveQuestName()
    local ok, result = pcall(function()
        if player.PlayerGui.Main.Quest.Visible then
            return player.PlayerGui.Main.Quest.Title.Text
        end
    end)
    return ok and result or nil
end

function QuestManager.acceptQuest(questData)
    if not questData then return false end
    local ok, err = pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
            :InvokeServer("StartQuest", questData.quest, questData.num)
    end)
    if not ok then
        NS.Logger.warn("Falha ao aceitar quest:", err)
        return false
    end
    return true
end

function QuestManager.matchesCurrentQuest(questData)
    if not QuestManager.hasActiveQuest() then return false end
    if not questData then return false end
    local title = QuestManager.getActiveQuestName()
    if not title then return false end
    return title:lower():find(questData.enemy:lower()) ~= nil
end

function QuestManager.init() end

return QuestManager
