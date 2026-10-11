local Weapon = {}

local Deps = {}

local autoEquipRunning = false
local autoEquipThread = nil

function Weapon.init(deps)
    Deps = deps or {}
end

local function getPlayer()
    return game:GetService("Players").LocalPlayer
end

local function getChar()
    return getPlayer().Character
end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Weapon.hasWeapon(weaponType)
    local plr = getPlayer()
    if not plr then return false end
    
    local backpack = plr:FindFirstChild("Backpack")
    local char = getChar()
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == weaponType then
                return true
            end
        end
    end
    
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == weaponType then
                return true
            end
        end
    end
    
    return false
end

function Weapon.getFirstOfType(weaponType)
    local plr = getPlayer()
    if not plr then return nil end
    
    local backpack = plr:FindFirstChild("Backpack")
    if not backpack then return nil end
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == weaponType then
            return tool
        end
    end
    
    return nil
end

function Weapon.getEquipped()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

function Weapon.equip(weaponType)
    weaponType = weaponType or Deps.Config.get("SelectWeapon")
    if not weaponType then return false end
    
    local plr = getPlayer()
    local hum = getHum()
    if not plr or not hum then return false end
    
    local char = getChar()
    local equipped = char and char:FindFirstChildOfClass("Tool")
    
    if equipped and equipped.ToolTip == weaponType then
        return true
    end
    
    local tool = Weapon.getFirstOfType(weaponType)
    if not tool then return false end
    
    local ok = pcall(function()
        hum:EquipTool(tool)
    end)
    
    return ok
end

function Weapon.startAutoEquip()
    if autoEquipRunning then return end
    autoEquipRunning = true
    
    autoEquipThread = task.spawn(function()
        while autoEquipRunning do
            local farmOn = Deps.Config.get("AutoFarmLevel")
            local equipOn = Deps.Config.get("AutoEquip")
            
            if farmOn and equipOn then
                local weaponType = Deps.Config.get("SelectWeapon")
                if weaponType then
                    local equipped = Weapon.getEquipped()
                    if not equipped or equipped.ToolTip ~= weaponType then
                        Weapon.equip(weaponType)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

function Weapon.stopAutoEquip()
    autoEquipRunning = false
    if autoEquipThread then
        pcall(function() task.cancel(autoEquipThread) end)
        autoEquipThread = nil
    end
end

function Weapon.getCurrentType()
    local equipped = Weapon.getEquipped()
    if not equipped then return nil end
    return equipped.ToolTip
end

function Weapon.getAll()
    local plr = getPlayer()
    if not plr then return {} end
    
    local result = {}
    local backpack = plr:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(result, tool)
            end
        end
    end
    
    return result
end

return Weapon