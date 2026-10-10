local NS = getgenv().AutoFarmBF

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm BF | v3.0",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Sistema modular",
    ConfigurationSaving = {Enabled=true, FolderName="AutoFarmBFv3", FileName="config"},
    KeySystem = false,
})

local FarmTab = Window:CreateTab("🌾 Farm", 4483362458)
FarmTab:CreateToggle({
    Name = "Auto Farm Level", CurrentValue = false, Flag = "AutoFarmLevel",
    Callback = function(v)
        NS.Config.autoFarmLevel = v
        if v then
            NS.StateManager.setState("CHECKING_LEVEL")
        else
            NS.StateManager.setState("IDLE")
        end
    end,
})
FarmTab:CreateToggle({
    Name = "Auto Quest", CurrentValue = false, Flag = "AutoQuest",
    Callback = function(v) NS.Config.autoQuest = v end,
})
FarmTab:CreateToggle({
    Name = "Auto Skill (Z X C V)", CurrentValue = false, Flag = "AutoSkill",
    Callback = function(v) NS.Config.autoSkill = v end,
})
FarmTab:CreateToggle({
    Name = "Kill Aura", CurrentValue = false, Flag = "KillAura",
    Callback = function(v) NS.Config.killAura = v end,
})

local FlyTab = Window:CreateTab("✈️ Voo & Hover", 4483362458)
FlyTab:CreateToggle({
    Name = "Hover em cima do inimigo", CurrentValue = true, Flag = "HoverEnabled",
    Callback = function(v) NS.Config.hoverEnabled = v end,
})
FlyTab:CreateSlider({
    Name = "Altura do Hover", Range = {5, 80}, Increment = 1, Suffix = " studs",
    CurrentValue = 25, Flag = "HoverHeight",
    Callback = function(v) NS.Config.hoverHeight = v end,
})
FlyTab:CreateToggle({
    Name = "Fly (W/A/S/D)", CurrentValue = false, Flag = "FlyEnabled",
    Callback = function(v)
        NS.Config.flyEnabled = v
        if v then NS.MovementManager.startFly() else NS.MovementManager.stopFly() end
    end,
})
FlyTab:CreateSlider({
    Name = "Velocidade do Fly", Range = {20, 300}, Increment = 10, Suffix = " studs/s",
    CurrentValue = 80, Flag = "FlySpeed",
    Callback = function(v) NS.Config.flySpeed = v end,
})
FlyTab:CreateButton({
    Name = "⬆️ Subir 50 studs",
    Callback = function() NS.MovementManager.ascend(50) end,
})
FlyTab:CreateButton({
    Name = "⬇️ Descer 50 studs",
    Callback = function() NS.MovementManager.descend(50) end,
})

local ConfigTab = Window:CreateTab("⚙️ Config", 4483362458)
ConfigTab:CreateSlider({
    Name = "Delay de ataque", Range = {0.05, 1}, Increment = 0.05, Suffix = "s",
    CurrentValue = 0.1, Flag = "AttackDelay",
    Callback = function(v) NS.Config.attackDelay = v end,
})
ConfigTab:CreateSlider({
    Name = "Raio do Kill Aura", Range = {10, 150}, Increment = 5, Suffix = " studs",
    CurrentValue = 50, Flag = "KillAuraRange",
    Callback = function(v) NS.Config.killAuraRange = v end,
})
ConfigTab:CreateToggle({
    Name = "Debug", CurrentValue = false, Flag = "Debug",
    Callback = function(v) NS.Config.debug = v end,
})
ConfigTab:CreateButton({
    Name = "🔄 Resetar personagem",
    Callback = function() NS.HealthManager.resetCharacter() end,
})

local StatusTab = Window:CreateTab("📊 Status", 4483362458)
local statusPara = StatusTab:CreateParagraph({
    Title = "Sistema",
    Content = "Estado: IDLE | Nível: -- | Quest: --"
})

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local lvl = NS.LevelManager.getLevel()
            local q = NS.LevelManager.getQuestRange()
            local questName = q and q.quest or "--"
            local enemy = q and q.enemy or "--"
            local state = NS.StateManager.getState()
            statusPara:Set({
                Title = "Sistema",
                Content = string.format(
                    "Estado: %s | Nível: %d | Quest: %s (%s)",
                    state, lvl, questName, enemy
                )
            })
        end)
    end
end)

Rayfield:Notify({
    Title = "Auto Farm BF v3.0",
    Content = "Sistema modular carregado!",
    Duration = 5,
    Image = 4483362458,
})
