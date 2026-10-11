local NS = getgenv().AutoFarmBF

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Farm BF",
    SubTitle = "v3.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Farm     = Window:AddTab({ Title = "Farm",       Icon = "sprout" }),
    Buffs    = Window:AddTab({ Title = "Buffs",      Icon = "shield" }),
    Coleta   = Window:AddTab({ Title = "Coleta",     Icon = "package" }),
    Fly      = Window:AddTab({ Title = "Voo & Hover",Icon = "plane" }),
    Config   = Window:AddTab({ Title = "Config",     Icon = "settings" }),
}

-- ============================================================
-- HELPER: reinicia o StateManager
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
        if NS.Config.autoFarmLevel then reiniciarEstado() end
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
-- ABA: FARM → Farm config
-- ============================================================
local FarmConfigGroup = Tabs.Farm:AddSection("Farm config")

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

FarmConfigGroup:AddToggle("FastAttack", {
    Title = "Fast Attack",
    Default = NS.Config.fastAttack or false,
    Callback = function(value)
        NS.Config.fastAttack = value
    end,
})

FarmConfigGroup:AddSlider("FarmDistance", {
    Title = "Farm Distance",
    Default = NS.Config.farmDistance or 25,
    Min = 5, Max = 100, Rounding = 0,
    Callback = function(value)
        NS.Config.farmDistance = value
    end,
})

FarmConfigGroup:AddSlider("FarmHeight", {
    Title = "Farm Height",
    Default = NS.Config.farmHeight or 20,
    Min = 5, Max = 100, Rounding = 0,
    Callback = function(value)
        NS.Config.farmHeight = value
        NS.Config.hoverHeight = value
    end,
})

FarmConfigGroup:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Default = NS.Config.tweenSpeed or 300,
    Min = 100, Max = 1000, Rounding = 0,
    Callback = function(value)
        NS.Config.tweenSpeed = value
        NS.MovementManager.TweenSpeedFar = value
    end,
})

FarmConfigGroup:AddSlider("AttackDelay", {
    Title = "Attack Delay",
    Default = NS.Config.attackDelay or 0.1,
    Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(value)
        NS.Config.attackDelay = value
    end,
})

-- ============================================================
-- ABA: FARM → Bring config
-- ============================================================
local BringConfigGroup = Tabs.Farm:AddSection("Bring config")

BringConfigGroup:AddSlider("BringRange", {
    Title = "Bring Range (studs)",
    Default = NS.Config.bringRange or 235,
    Min = 50, Max = 1000, Rounding = 0,
    Callback = function(value)
        NS.Config.bringRange = value
    end,
})

BringConfigGroup:AddSlider("MaxBringMobs", {
    Title = "Max Bring Mobs",
    Default = NS.Config.maxBringMobs or 3,
    Min = 1, Max = 10, Rounding = 0,
    Callback = function(value)
        NS.Config.maxBringMobs = value
    end,
})

-- ============================================================
-- ABA: BUFFS
-- ============================================================
local BuffsGroup = Tabs.Buffs:AddSection("Buffs Automáticos")

BuffsGroup:AddToggle("AutoBuso", {
    Title = "Auto Buso (Haki de Armamento)",
    Default = NS.Config.autoBuso or false,
    Callback = function(value)
        NS.Config.autoBuso = value
    end,
})

BuffsGroup:AddToggle("AutoKen", {
    Title = "Auto Ken (Observation Haki)",
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
-- ABA: BUFFS → Skills
-- ============================================================
local SkillsGroup = Tabs.Buffs:AddSection("Skills Automáticas")

SkillsGroup:AddToggle("AutoSkill", {
    Title = "Auto Skill (Z X C V)",
    Default = NS.Config.autoSkill or false,
    Callback = function(value)
        NS.Config.autoSkill = value
    end,
})

SkillsGroup:AddSlider("SkillDelay", {
    Title = "Delay entre Skills",
    Default = NS.Config.skillDelay or 0.8,
    Min = 0.2, Max = 3, Rounding = 1,
    Callback = function(value)
        NS.Config.skillDelay = value
    end,
})

SkillsGroup:AddToggle("KillAura", {
    Title = "Kill Aura",
    Default = NS.Config.killAura or false,
    Callback = function(value)
        NS.Config.killAura = value
    end,
})

-- ============================================================
-- ABA: COLETA
-- ============================================================
local CollectGroup = Tabs.Coleta:AddSection("Coleta Automática")

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

CollectGroup:AddToggle("AutoCollectChest", {
    Title = "Auto Coletar Baús",
    Default = NS.Config.autoCollectChest or false,
    Callback = function(value)
        NS.Config.autoCollectChest = value
    end,
})

CollectGroup:AddToggle("AutoCollectBerry", {
    Title = "Auto Coletar Berries",
    Default = NS.Config.autoCollectBerry or false,
    Callback = function(value)
        NS.Config.autoCollectBerry = value
    end,
})

CollectGroup:AddSlider("CollectRange", {
    Title = "Raio de Coleta",
    Default = NS.Config.collectRange or 300,
    Min = 50, Max = 1000, Rounding = 0,
    Callback = function(value)
        NS.Config.collectRange = value
    end,
})

-- ============================================================
-- ABA: VOO & HOVER
-- ============================================================
local FlyGroup = Tabs.Fly:AddSection("Configurações de Voo")

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
    Min = 20, Max = 300, Rounding = 0,
    Callback = function(value)
        NS.Config.flySpeed = value
    end,
})

FlyGroup:AddSlider("FlyHeight", {
    Title = "Altura padrão do Fly",
    Default = NS.Config.flyHeight or 50,
    Min = 10, Max = 200, Rounding = 0,
    Callback = function(value)
        NS.Config.flyHeight = value
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
-- ABA: VOO & HOVER → Hover
-- ============================================================
local HoverGroup = Tabs.Fly:AddSection("Hover")

HoverGroup:AddToggle("HoverEnabled", {
    Title = "Hover em cima do inimigo",
    Default = NS.Config.hoverEnabled ~= false,
    Callback = function(value)
        NS.Config.hoverEnabled = value
    end,
})

HoverGroup:AddSlider("HoverHeight", {
    Title = "Altura do Hover",
    Default = NS.Config.hoverHeight or 20,
    Min = 5, Max = 100, Rounding = 0,
    Callback = function(value)
        NS.Config.hoverHeight = value
        NS.Config.farmHeight = value
    end,
})

-- ============================================================
-- ABA: CONFIG
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
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end,
})

-- ============================================================
-- ABA: CONFIG → Save/Load info
-- ============================================================
local InfoGroup = Tabs.Config:AddSection("Info")

InfoGroup:AddParagraph({
    Title = "Auto Farm BF v3.0",
    Content = "Hub modular com StateMachine + Fluent UI.\nSalvamento automático ativo."
})

InfoGroup:AddParagraph({
    Title = "⚠️ Aviso",
    Content = "Usar scripts no Blox Fruits viola os ToS da Roblox e pode resultar em banimento permanente."
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
-- SAVE MANAGER
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
