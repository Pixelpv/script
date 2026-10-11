local UI = {}

local Deps = {}

function UI.init(deps)
    Deps = deps or {}
end

local function getFluent()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end

function UI.create()
    local Fluent = getFluent()

    local Window = Fluent:CreateWindow({
        Title = "Auto Farm Level",
        SubTitle = "Blox Fruits",
        TabWidth = 140,
        Size = UDim2.fromOffset(520, 480),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift,
    })

    Deps.Fluent = Fluent
    Deps.Window = Window

    UI.buildFarmTab(Fluent, Window)
    UI.buildConfigTab(Fluent, Window)

    Fluent:Notify({
        Title = "Auto Farm Level",
        Content = "Script carregado! RightShift para minimizar",
        Duration = 5,
    })

    return Window
end

function UI.buildFarmTab(Fluent, Window)
    local Tab = Window:AddTab({ Title = "Farm", Icon = "sword" })

    Tab:AddSection("Main Farm")

    local autoFarmToggle = Tab:AddToggle("AutoFarmLevel", {
        Title = "Auto Farm Level",
        Description = "Farm automático de level",
        Default = Deps.Config.get("AutoFarmLevel"),
    })

    autoFarmToggle:OnChanged(function(value)
        Deps.Config.set("AutoFarmLevel", value)
        if value then
            Deps.FarmLevel.start()
        else
            Deps.FarmLevel.stop()
        end
    end)

    local autoQuestToggle = Tab:AddToggle("AutoQuest", {
        Title = "Auto Quest",
        Description = "Aceita quest automaticamente",
        Default = Deps.Config.get("AutoQuest"),
    })

    autoQuestToggle:OnChanged(function(value)
        Deps.Config.set("AutoQuest", value)
    end)
end

function UI.buildConfigTab(Fluent, Window)
    local Tab = Window:AddTab({ Title = "Config", Icon = "settings" })

    Tab:AddSection("Farm Config")

    local weaponDropdown = Tab:AddDropdown("SelectWeapon", {
        Title = "Select Weapon",
        Description = "Tipo de arma",
        Values = { "Melee", "Sword", "Gun", "Demon Fruit" },
        Multi = false,
        Default = Deps.Config.get("SelectWeapon"),
    })

    weaponDropdown:OnChanged(function(value)
        Deps.Config.set("SelectWeapon", value)
    end)

    local speedSlider = Tab:AddSlider("TeleportSpeed", {
        Title = "Velocidade Tween",
        Description = "Velocidade do teleporte",
        Default = Deps.Config.get("TeleportSpeed"),
        Min = 100,
        Max = 2000,
        Rounding = 0,
    })

    speedSlider:OnChanged(function(value)
        Deps.Config.set("TeleportSpeed", value)
    end)

    local heightSlider = Tab:AddSlider("MobHeight", {
        Title = "Altura do Mob",
        Description = "Altura acima do mob (studs)",
        Default = Deps.Config.get("MobHeight"),
        Min = 5,
        Max = 60,
        Rounding = 0,
    })

    heightSlider:OnChanged(function(value)
        Deps.Config.set("MobHeight", value)
    end)

    local autoEquipToggle = Tab:AddToggle("AutoEquip", {
        Title = "Auto Equip",
        Description = "Mantém a arma equipada",
        Default = Deps.Config.get("AutoEquip"),
    })

    autoEquipToggle:OnChanged(function(value)
        Deps.Config.set("AutoEquip", value)
        if value then
            Deps.Weapon.startAutoEquip()
        else
            Deps.Weapon.stopAutoEquip()
        end
    end)

    local bringMobToggle = Tab:AddToggle("BringMob", {
        Title = "Bring Mob",
        Description = "Traz os mobs da quest até você",
        Default = Deps.Config.get("BringMob"),
    })

    bringMobToggle:OnChanged(function(value)
        Deps.Config.set("BringMob", value)
    end)

    local fastAttackToggle = Tab:AddToggle("FastAttack", {
        Title = "Fast Attack",
        Description = "Ataque rápido automático",
        Default = Deps.Config.get("FastAttack"),
    })

    fastAttackToggle:OnChanged(function(value)
        Deps.Config.set("FastAttack", value)
        if value then
            Deps.Combat.fastAttack()
        else
            Deps.Combat.stopFastAttack()
        end
    end)

    local autoClickToggle = Tab:AddToggle("AutoClick", {
        Title = "Auto Click",
        Description = "Clique automático",
        Default = Deps.Config.get("AutoClick"),
    })

    autoClickToggle:OnChanged(function(value)
        Deps.Config.set("AutoClick", value)
        if value then
            Deps.Combat.autoClick()
        else
            Deps.Combat.stopAutoClick()
        end
    end)

    local noClipToggle = Tab:AddToggle("NoClip", {
        Title = "No Clip",
        Description = "Atravessar paredes",
        Default = Deps.Config.get("NoClip"),
    })

    noClipToggle:OnChanged(function(value)
        Deps.Config.set("NoClip", value)
    end)

    local antiAFKToggle = Tab:AddToggle("AntiAFK", {
        Title = "Anti AFK",
        Description = "Evita kick por inatividade",
        Default = Deps.Config.get("AntiAFK"),
    })

    antiAFKToggle:OnChanged(function(value)
        Deps.Config.set("AntiAFK", value)
    end)

    local busoToggle = Tab:AddToggle("AutoBusoHaki", {
        Title = "Auto Buso Haki",
        Description = "Mantém Buso Haki ativo",
        Default = Deps.Config.get("AutoBusoHaki"),
    })

    busoToggle:OnChanged(function(value)
        Deps.Config.set("AutoBusoHaki", value)
    end)
end

function UI.applySavedConfig()
    if Deps.Config.get("AutoEquip") and Deps.Weapon then
        Deps.Weapon.startAutoEquip()
    end
    if Deps.Config.get("FastAttack") and Deps.Combat then
        Deps.Combat.fastAttack()
    end
    if Deps.Config.get("AutoClick") and Deps.Combat then
        Deps.Combat.autoClick()
    end
    if Deps.Config.get("AutoBusoHaki") and Deps.Haki then
        Deps.Haki.startBuso()
    end
    if Deps.Config.get("AntiAFK") and Deps.AFK then
        Deps.AFK.start()
    end
    if Deps.Config.get("AutoFarmLevel") and Deps.FarmLevel then
        Deps.FarmLevel.start()
    end
end

return UI