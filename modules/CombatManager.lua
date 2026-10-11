local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local CombatManager = {}
CombatManager._auraRunning = false
CombatManager._lastEquip = 0
CombatManager._lastAttackLog = 0

-- ============================================================
-- REMOTES
-- ============================================================
local function getAttackRemotes()
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    if not Modules then return nil, nil end
    local Net = Modules:FindFirstChild("Net")
    if not Net then return nil, nil end
    return Net:FindFirstChild("RE/RegisterAttack"),
           Net:FindFirstChild("RE/RegisterHit")
end

-- ============================================================
-- TIPO DE ARMA
-- ============================================================
local function getToolType(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local tip = tool:FindFirstChild("ToolTip")
    if tip then return tip.Value end
    local attr = tool:GetAttribute("WeaponType")
    if attr then return attr end

    local nome = tool.Name:lower()
    if nome:find("sword") or nome:find("katana") or nome:find("blade")
    or nome:find("saber") or nome:find("cutlass") or nome:find("bisento")
    or nome:find("trident") or nome:find("dagger") or nome:find("scythe")
    or nome:find("wando") or nome:find("yama") or nome:find("tushita")
    or nome:find("shisui") or nome:find("rengoku") or nome:find("koko")
    or nome:find("kabucha") or nome:find("dark blade") then
        return "Sword"
    end
    if nome:find("gun") or nome:find("pistol") or nome:find("rifle")
    or nome:find("musket") or nome:find("cannon") or nome:find("slingshot")
    or nome:find("flintlock") or nome:find("bow") then
        return "Gun"
    end
    if nome:find("fruit") then return "Blox Fruit" end
    return "Melee"
end
CombatManager.getToolType = getToolType

-- ============================================================
-- EQUIP
-- ============================================================
function CombatManager.equipWeaponType(tipoDesejado)
    if not tipoDesejado then return false end
    if tick() - CombatManager._lastEquip < 1.5 then return false end

    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false end

    -- Já equipada?
    local equipada = char:FindFirstChildOfClass("Tool")
    if equipada and getToolType(equipada) == tipoDesejado then
        CombatManager._lastEquip = tick()
        return true
    end

    -- Procura no backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and getToolType(tool) == tipoDesejado then
            hum:EquipTool(tool)
            CombatManager._lastEquip = tick()
            NS.Logger.log("Equipado:", tool.Name, "(", tipoDesejado, ")")
            return true
        end
    end

    CombatManager._lastEquip = tick()
    return false
end

-- ============================================================
-- ATTACK VIA REMOTE
-- ============================================================
function CombatManager.attackRemote(range)
    range = range or 50
    local hrp = NS.HealthManager.getHRP()
    if not hrp then return false end

    local RegisterAttack, RegisterHit = getAttackRemotes()
    if not RegisterAttack or not RegisterHit then return false end

    local enemies = {}
    local basePart = nil

    for _, mob in ipairs(workspace.Enemies:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local head = mob:FindFirstChild("Head")
        if hum and head and hum.Health > 0 then
            local dist = (head.Position - hrp.Position).Magnitude
            if dist < range then
                table.insert(enemies, { mob, head })
                basePart = head
            end
        end
    end

    if basePart and #enemies > 0 then
        local ok = pcall(function()
            RegisterAttack:FireServer(0)
            RegisterHit:FireServer(basePart, enemies)
        end)
        return ok
    end
    return false
end

-- ============================================================
-- ATTACK VIRTUAL (fallback)
-- ============================================================
function CombatManager.attackVirtual()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0, 0))
end

-- ============================================================
-- ATTACK PRINCIPAL
-- ============================================================
function CombatManager.attack()
    local sucesso = CombatManager.attackRemote(NS.Config.farmRange or 60)
    if not sucesso then
        CombatManager.attackVirtual()
    end

    -- Log a cada 5s pra saber se tá batendo
    if tick() - CombatManager._lastAttackLog > 5 then
        CombatManager._lastAttackLog = tick()
        NS.Logger.log("Attack: remote=", tostring(sucesso))
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
            local targets = NS.TargetManager.getTargetsInRange(NS.Config.farmRange or 60)
            for _, mob in ipairs(targets) do
                CombatManager.attack()
            end
        end
    end)
end

function CombatManager.stopKillAura()
    CombatManager._auraRunning = false
end

-- ============================================================
-- AUTO SKILL
-- ============================================================
task.spawn(function()
    while true do
        task.wait(NS.Config.skillDelay or 0.8)
        if not NS.Config.autoSkill then continue end
        local enemy = NS.TargetManager.findNearest()
        if enemy then CombatManager.useAllSkills() end
    end
end)

return CombatManager
