local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local CombatManager = {}
CombatManager._auraRunning = false
CombatManager._lastEquip = 0

-- ============================================================
-- MAPEAMENTO DE TIPO DE ARMA
-- ============================================================
local WEAPON_TYPE_MAP = {
    Sword        = "Sword",
    Melee        = "Melee",
    Gun          = "Gun",
    ["Blox Fruit"] = "Blox Fruit",
}

-- ============================================================
-- DETECTA O TIPO DE UMA TOOL
-- ============================================================
local function getToolType(tool)
    if not tool or not tool:IsA("Tool") then return nil end

    -- Método 1: Attribute "WeaponType"
    local attr = tool:GetAttribute("WeaponType")
    if attr then return attr end

    -- Método 2: ToolTip
    local tip = tool:FindFirstChild("ToolTip")
    if tip then return tip.Value end

    -- Método 3: Nome da tool
    local nome = tool.Name:lower()
    if nome:find("sword") or nome:find("katana") 
    or nome:find("blade") or nome:find("saber")
    or nome:find("cutlass") or nome:find("bisento")
    or nome:find("trident") or nome:find("dagger")
    or nome:find("scythe") or nome:find("scythe")
    or nome:find("wando") or nome:find("yama")
    or nome:find("tushita") or nome:find("shisui")
    or nome:find("rengoku") or nome:find("koko")
    or nome:find("kabucha") then
        return "Sword"
    end

    if nome:find("gun") or nome:find("pistol") 
    or nome:find("rifle") or nome:find("musket")
    or nome:find("cannon") or nome:find("slingshot")
    or nome:find("flintlock") or nome:find("bow") then
        return "Gun"
    end

    if nome:find("fruit") then
        return "Blox Fruit"
    end

    return "Melee"
end

CombatManager.getToolType = getToolType

-- ============================================================
-- EQUIPAR ARMA DO TIPO SELECIONADO
-- ============================================================
function CombatManager.equipWeaponType(tipoDesejado)
    if not tipoDesejado then return end
    -- Cooldown de 2 segundos para não floodar
    if tick() - CombatManager._lastEquip < 2 then return end

    local char = player.Character
    if not char then return end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    -- Já tem a tool certa equipada?
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and getToolType(tool) == tipoDesejado then
            CombatManager._lastEquip = tick()
            return
        end
    end

    -- Procura no backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and getToolType(tool) == tipoDesejado then
            tool.Parent = char
            CombatManager._lastEquip = tick()
            NS.Logger.log("Equipado:", tool.Name, "(", tipoDesejado, ")")
            return
        end
    end

    CombatManager._lastEquip = tick()
end

-- ============================================================
-- ATAQUE
-- ============================================================
function CombatManager.attack()
    if NS.Config.autoEquip and NS.Config.selectWeapon then
        CombatManager.equipWeaponType(NS.Config.selectWeapon)
    end

    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0, 0))

    -- Fast Attack: clicks extras
    if NS.Config.fastAttack then
        VirtualUser:ClickButton1(Vector2.new(0, 0))
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end
end

-- ============================================================
-- SKILLS
-- ============================================================
function CombatManager.useSkill(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

function CombatManager.useAllSkills()
    for _, key in ipairs({"Z", "X", "C", "V"}) do
        CombatManager.useSkill(key)
    end
end

-- ============================================================
-- KILL AURA
-- ============================================================
function CombatManager.startKillAura()
    if CombatManager._auraRunning then return end
    CombatManager._auraRunning = true

    task.spawn(function()
        while CombatManager._auraRunning do
            task.wait(NS.Config.attackDelay)
            if not NS.Config.killAura then continue end

            local targets = NS.TargetManager.getTargetsInRange(NS.Config.farmRange)
            for _, mob in ipairs(targets) do
                if NS.Config.autoEquip then
                    CombatManager.equipWeaponType(NS.Config.selectWeapon)
                end
                if NS.Config.bringMob then
                    NS.MovementManager.bringMob(mob)
                end
                NS.MovementManager.hoverAbove(
                    mob.HumanoidRootPart,
                    NS.Config.farmHeight
                )
                CombatManager.attack()
            end
        end
    end)
end

function CombatManager.stopKillAura()
    CombatManager._auraRunning = false
end

-- ============================================================
-- AUTO SKILL LOOP (se ativado)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(NS.Config.skillDelay or 0.8)
        if not NS.Config.autoSkill then continue end
        local enemy = NS.TargetManager.findNearest(60)
        if enemy then
            CombatManager.useAllSkills()
        end
    end
end)

return CombatManager
