local Quest = {}

local Deps = {}

local lastHasQuestTime = 0
local lastHasQuestState = false

function Quest.init(deps)
    Deps = deps or {}
end

local function getQuestModule()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    return ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
end

local function getPlayer()
    return game:GetService("Players").LocalPlayer
end

function Quest.hasQuest()
    local plr = getPlayer()
    if not plr then return false end
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return false end
    local main = pg:FindFirstChild("Main")
    if not main then return false end
    local quest = main:FindFirstChild("Quest")
    if not quest then return false end
    if not quest.Visible then return false end
    
    local container = quest:FindFirstChild("Container")
    if not container then return false end
    local questTitle = container:FindFirstChild("QuestTitle")
    if not questTitle then return false end
    local title = questTitle:FindFirstChild("Title")
    if not title or title.Text == "" then return false end
    
    return true
end

function Quest.getCurrentTitle()
    local plr = getPlayer()
    if not plr then return nil end
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("Main")
    if not main then return nil end
    local quest = main:FindFirstChild("Quest")
    if not quest or not quest.Visible then return nil end
    
    local container = quest:FindFirstChild("Container")
    if not container then return nil end
    local questTitle = container:FindFirstChild("QuestTitle")
    if not questTitle then return nil end
    local title = questTitle:FindFirstChild("Title")
    if not title then return nil end
    
    return title.Text
end

function Quest.getCurrent()
    local plr = getPlayer()
    if not plr or not plr:FindFirstChild("Data") then return nil end
    local level = plr.Data.Level.Value
    return Deps.Quests.getByLevel(level)
end

function Quest.accept()
    if Quest.hasQuest() then return false end
    
    local quest = Quest.getCurrent()
    if not quest then return false end
    
    local CommF = getQuestModule()
    if not CommF then return false end
    
    local ok = pcall(function()
        CommF:InvokeServer("StartQuest", quest.questName, quest.questId)
    end)
    
    return ok
end

function Quest.abandon()
    local CommF = getQuestModule()
    if not CommF then return false end
    
    local ok = pcall(function()
        CommF:InvokeServer("AbandonQuest")
    end)
    
    return ok
end

function Quest.getNPC()
    local quest = Quest.getCurrent()
    if not quest then return nil end
    return quest.npcPos
end

function Quest.getMobPos()
    local quest = Quest.getCurrent()
    if not quest then return nil end
    return quest.mobPos
end

function Quest.getMobName()
    local quest = Quest.getCurrent()
    if not quest then return nil end
    return quest.mob
end

return Quest