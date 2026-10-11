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

-- ============================================================
-- HELPER: sincroniza estados e reinicia o StateManager
-- ============================================================
local function reiniciarEstado()
    if NS.Config.autoFarmLevel or NS.Config.farmNearest then
        NS.StateManager.currentState = "STOPPED"
        NS.StateManager.setState("STARTING")
    else
        NS.StateManager.currentState = "FARMING"
        NS.StateManager.setState("STOPPED")
    end
end

-- ============================================================
-- ABA: FARM → Main farm
-- ============================================================
local MainFarmGroup = Tabs.Farm:AddSection("Main farm")

MainFarmGroup:AddToggle("AutoFarmLevel", {
    Title = "Farm Level",
    Default = NS.Config.autoFarmLevel or false,
    Callback = function(value)
        NS.Config.autoFarmLevel = value
        reiniciarEstado()
    end,
})

MainFarmGroup:AddToggle("AutoQuest", {
    Title = "Auto Quest",
    Default = NS.Config.autoQuest or false,
    Callback = function(value)
        NS.Config.autoQuest = value
        if NS.Config.autoFarmLevel then
            reiniciarEstado()
        end
    end,
})

MainFarmGroup:AddToggle("FarmNearest", {
    Title = "Farm Nearest",
    Default = NS.Config.farmNearest or false,
    Callback = function(value)
        NS.Config.farmNearest = value
        reiniciarEstado()
    end,
})

-- ============================================================
-- ABA: CONFIG → Farm config
-- ============================================================
local FarmConfigGroup = Tabs.Config:AddSection("Farm config")

FarmConfigGroup:AddDropdown("SelectWeapon", {
    Title = "Select Weapon",
    Values = { "Sword", "Melee", "Gun", "Blox Fruit" },
    Default = NS.Config.selectWeapon or "Melee",
    Multi = false,
    Callback = function(value)
        NS.Config.selectWeapon = value
    end,
})

FarmConfigGroup:AddToggle("AutoEquip", {
    Title = "Auto Equip",
    Default = NS.Config.autoEquip or false,
    Callback = function(value)
        NS.Config.autoEquip = value
    end,
})

FarmConfigGroup:AddToggle("BringMob", {
    Title = "Bring Mob",
    Default = NS.Config.bringMob or false,
    Callback = function(value)
        NS.Config.bringMob = value
    end,
})

FarmConfigGroup:AddSlider("FarmDistance", {
    Title = "Farm Distance",
    Default = NS.Config.farmDistance or 25,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        NS.Config.farmDistance = value
    end,
})

FarmConfigGroup:AddToggle("FastAttack", {
    Title = "Fast Attack",
    Default = NS.Config.fastAttack or false,
    Callback = function(value)
        NS.Config.fastAttack = value
    end,
})

FarmConfigGroup:AddSlider("FarmHeight", {
    Title = "Farm Height",
    Default = NS.Config.farmHeight or 20,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        NS.Config.farmHeight = value
        NS.Config.hoverHeight = value
    end,
})

FarmConfigGroup:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Default = NS.Config.tweenSpeed or 300,
    Min = 100,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        NS.Config.tweenSpeed = value
        NS.MovementManager.TweenSpeedFar = value
    end,
})

-- ============================================================
-- ABA: CONFIG → Buffs
-- ============================================================
local BuffsGroup = Tabs.Config:AddSection("Buffs")

BuffsGroup:AddToggle("AutoBuso", {
    Title = "Auto Buso (Haki)",
    Default = NS.Config.autoBuso or false,
    Callback = function(value)
        NS.Config.autoBuso = value
    end,
})

BuffsGroup:AddToggle("AutoKen", {
    Title = "Auto Ken (Observation)",
    Default = NS.Config.autoKen or false,
    Callback = function(value)
        NS.Config.autoKen = value
    end,
})

BuffsGroup:AddToggle("AutoRaceV3", {
    Title = "Auto Race V3",
    Default = NS.Config.autoRaceV3 or false,
    Callback = function(value)
        NS.Config.autoRaceV3 = value
    end,
})

BuffsGroup:AddToggle("AutoRaceV4", {
    Title = "Auto Race V4",
    Default = NS.Config.autoRaceV4 or false,
    Callback = function(value)
        NS.Config.autoRaceV4 = value
    end,
})

-- ============================================================
-- ABA: CONFIG → Coleta
-- ============================================================
local CollectGroup = Tabs.Config:AddSection("Coleta")

CollectGroup:AddToggle("AutoCollectFruit", {
    Title = "Auto Coletar Frutas",
    Default = NS.Config.autoCollectFruit or false,
    Callback = function(value)
        NS.Config.autoCollectFruit = value
    end,
})

CollectGroup:AddToggle("AutoCollectTool", {
    Title = "Auto Coletar Tools",
    Default = NS.Config.autoCollectTool or false,
    Callback = function(value)
        NS.Config.autoCollectTool = value
    end,
})

CollectGroup:AddSlider("CollectRange", {
    Title = "Raio de Coleta",
    Default = NS.Config.collectRange or 300,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        NS.Config.collectRange = value
    end,
})

-- ============================================================
-- ABA: CONFIG → Voo & Hover
-- ============================================================
local FlyGroup = Tabs.Config:AddSection("Voo & Hover")

FlyGroup:AddToggle("HoverEnabled", {
    Title = "Hover em cima do inimigo",
    Default = NS.Config.hoverEnabled ~= false,
    Callback = function(value)
        NS.Config.hoverEnabled = value
    end,
})

FlyGroup:AddToggle("FlyEnabled", {
    Title = "Fly (W/A/S/D)",
    Default = NS.Config.flyEnabled or false,
    Callback = function(value)
        NS.Config.flyEnabled = value
        if value then
            NS.MovementManager.startFly()
        else
            NS.MovementManager.stopFly()
        end
    end,
})

FlyGroup:AddSlider("FlySpeed", {
    Title = "Velocidade do Fly",
    Default = NS.Config.flySpeed or 80,
    Min = 20,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        NS.Config.flySpeed = value
    end,
})

FlyGroup:AddButton({
    Title = "⬆️ Subir 50 studs",
    Callback = function()
        NS.MovementManager.ascend(50)
    end,
})

FlyGroup:AddButton({
    Title = "⬇️ Descer 50 studs",
    Callback = function()
        NS.MovementManager.descend(50)
    end,
})

-- ============================================================
-- ABA: CONFIG → Debug
-- ============================================================
local DebugGroup = Tabs.Config:AddSection("Debug")

DebugGroup:AddToggle("DebugMode", {
    Title = "Debug (logs no console)",
    Default = NS.Config.debug or false,
    Callback = function(value)
        NS.Config.debug = value
    end,
})

DebugGroup:AddButton({
    Title = "🔄 Destravar personagem",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("BodyPosition") or obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                        obj:Destroy()
                    end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.Sit = false
                end
            end
        end
        Fluent:Notify({
            Title = "Debug",
            Content = "Personagem destravado",
            Duration = 3,
        })
    end,
})

DebugGroup:AddButton({
    Title = "🔄 Resetar personagem",
    Callback = function()
        local hum = game.Players.LocalPlayer.Character 
            and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})

-- ============================================================
-- SUBTÍTULO: status em tempo real
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local lvl = NS.LevelManager.getLevel()
            local q = NS.LevelManager.getQuestRange()
            local state = NS.StateManager.getState()
            local modo = "OFF"
            if NS.Config.autoFarmLevel then modo = "Level"
            elseif NS.Config.farmNearest then modo = "Nearest" end

            Window:SetSubTitle(string.format(
                "Lv. %d | %s | %s | %s",
                lvl, state, modo, q and q.quest or "--"
            ))
        end)
    end
end)

-- ============================================================
-- SAVE MANAGER (sempre por último)
-- ============================================================
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
