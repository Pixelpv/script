local NS = getgenv().AutoFarmBF

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Farm BF",
    SubTitle = "v3.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "sprout" }),
    Config = Window:AddTab({ Title = "Config", Icon = "settings" }),
}

local MainFarmGroup = Tabs.Farm:AddSection("Main farm")

MainFarmGroup:AddToggle("AutoFarmLevel", {
    Title = "Farm Level",
    Default = false,
    Callback = function(value)
        NS.Config.autoFarmLevel = value
        if value then
            NS.StateManager.currentState = "STOPPED"
            NS.StateManager.setState("STARTING")
        else
            NS.StateManager.currentState = "FARMING"
            NS.StateManager.setState("STOPPED")
        end
    end,
})

MainFarmGroup:AddToggle("AutoQuest", {
    Title = "Auto Quest",
    Default = false,
    Callback = function(value)
        NS.Config.autoQuest = value
        if NS.Config.autoFarmLevel then
            NS.StateManager.currentState = "FARMING"
            NS.StateManager.setState("STARTING")
        end
    end,
})

MainFarmGroup:AddToggle("FarmNearest", {
    Title = "Farm Nearest",
    Default = false,
    Callback = function(value)
        NS.Config.farmNearest = value
    end,
})

local FarmConfigGroup = Tabs.Config:AddSection("Farm config")

FarmConfigGroup:AddDropdown("SelectWeapon", {
    Title = "Select Weapon",
    Values = { "Sword", "Melee", "Gun", "Blox Fruit" },
    Default = "Melee",
    Multi = false,
    Callback = function(value)
        NS.Config.selectWeapon = value
    end,
})

FarmConfigGroup:AddToggle("AutoEquip", {
    Title = "Auto Equip",
    Default = false,
    Callback = function(value)
        NS.Config.autoEquip = value
    end,
})

FarmConfigGroup:AddToggle("BringMob", {
    Title = "Bring Mob",
    Default = false,
    Callback = function(value)
        NS.Config.bringMob = value
    end,
})

FarmConfigGroup:AddSlider("FarmDistance", {
    Title = "Farm Distance",
    Default = 25,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        NS.Config.farmDistance = value
    end,
})

FarmConfigGroup:AddToggle("FastAttack", {
    Title = "Fast Attack",
    Default = false,
    Callback = function(value)
        NS.Config.fastAttack = value
    end,
})

FarmConfigGroup:AddSlider("FarmHeight", {
    Title = "Farm Height",
    Default = 25,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        NS.Config.farmHeight = value
        NS.Config.hoverHeight = value
    end,
})

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local lvl = NS.LevelManager.getLevel()
            local q = NS.LevelManager.getQuestRange()
            local state = NS.StateManager.getState()
            Window:SetSubTitle(string.format(
                "Lv. %d | %s | %s",
                lvl, state, q and q.quest or "--"
            ))
        end)
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AutoFarmBF")
SaveManager:SetFolder("AutoFarmBF/Configs")
SaveManager:BuildConfigSection(Tabs.Config)
InterfaceManager:ApplyToTab(Tabs.Config)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title = "Auto Farm BF",
    Content = "UI carregada com sucesso",
    Duration = 5,
})

NS.Logger.log("Fluent UI carregada")
