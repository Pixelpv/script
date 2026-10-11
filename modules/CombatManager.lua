local NS = getgenv().AutoFarmBF
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local CombatManager = {}
CombatManager._auraRunning = false
CombatManager._lastEquip = 0

local function getCommF()
    local R = ReplicatedStorage:FindFirstChild("Remotes")
    return R and R:FindFirstChild("CommF_")
end

local function getToolType(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local tip = tool:FindFirstChild("ToolTip")
    if tip then return tip.Value end
    local attr = tool:GetAttribute("WeaponType")
    if attr then return attr end

    local n = tool.Name:lower()
    if n:find("sword") or n:find("katana") or n:find("blade")
    or n:find("saber") or n:find("cutlass") or n:find("bisento")
    or n:find("trident") or n:find("dagger") or n:find("scythe")
    or n:find("wando") or n:find("yama") or n:find("tushita")
    or n:find("shisui") or n:find("rengoku") or n:find("koko")
    or n:find("kabucha") or n:find("dark blade") then
        return "Sword"
    end
    if n:find("gun") or n:find("pistol") or n:find("rifle")
    or n:find("musket") or n:find("cannon") or n:find("slingshot")
    or n:find("flintlock") or n:find("bow") then
        return "Gun"
    end
    if n:find("fruit") then return "Blox Fruit" end
    return "Melee"
end
CombatManager.getToolType = getToolType

function CombatManager.equipWeaponType(tipoDesejado)
    if not tipoDesejado then return false end
    if tick() - CombatManager._lastEquip < 1.5 then return false end

    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false end

    local equipada = char:FindFirstChildOfClass("Tool")
    if equipada and getToolType(equipada) == tipoDesejado then
        CombatManager._lastEquip = tick()
        return true
    end

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

function CombatManager.attack()
    local CommF = getCommF()
    if not CommF then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
        return
    end
    pcall(function() CommF:InvokeServer("Attack") end)

    if NS.Config.fastAttack then
        for i = 1, 2 do
            task.wait(0.02)
            pcall(function() CommF:InvokeServer("Attack") end)
        end
    end
end

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

function CombatManager.startKillAura()
    if CombatManager._auraRunning then return end
    CombatManager._auraRunning = true
    task.spawn(function()
        while CombatManager._auraRunning do
            task.wait(NS.Config.attackDelay)
            if not NS.Config.killAura then continue end
            local targets = NS.TargetManager.getTargetsInRange(NS.Config.bringRange or 60)
            for _, mob in ipairs(targets) do
                CombatManager.attack()
            end
        end
    end)
end

function CombatManager.stopKillAura()
    CombatManager._auraRunning = false
end

task.spawn(function()
    while true do
        task.wait(NS.Config.skillDelay or 0.8)
        if not NS.Config.autoSkill then continue end
        local enemy = NS.TargetManager.findNearest()
        if enemy then CombatManager.useAllSkills() end
    end
end)

return CombatManager
