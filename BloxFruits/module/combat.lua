local Combat = {}

local Deps = {}

local autoClickRunning = false
local autoClickThread = nil
local fastAttackThread = nil
local fastAttackRunning = false

function Combat.init(deps)
    Deps = deps or {}
end

local function getPlayer()
    return game:GetService("Players").LocalPlayer
end

local function getHRP()
    local plr = getPlayer()
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNet()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if not modules then return nil end
    return modules:FindFirstChild("Net")
end

local function getAttackRemotes()
    local net = getNet()
    if not net then return nil, nil end
    return net:FindFirstChild("RE/RegisterAttack"), net:FindFirstChild("RE/RegisterHit")
end

local function getEquippedTool()
    local char = getPlayer().Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function collectEnemiesInRange(range)
    local hrp = getHRP()
    if not hrp then return {}, nil end
    
    local enemies = {}
    local basePart = nil
    
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return {}, nil end
    
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local head = enemy:FindFirstChild("Head")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if head and hum and hum.Health > 0 then
            local dist = (head.Position - hrp.Position).Magnitude
            if dist <= range then
                table.insert(enemies, { enemy, head })
                if not basePart then basePart = head end
            end
        end
    end
    
    return enemies, basePart
end

function Combat.fastAttack()
    if fastAttackRunning then return end
    fastAttackRunning = true
    
    fastAttackThread = task.spawn(function()
        local attackRemote, hitRemote = getAttackRemotes()
        if not attackRemote or not hitRemote then
            fastAttackRunning = false
            return
        end
        
        while fastAttackRunning do
            if not Deps.Config.get("AutoFarmLevel") then
                task.wait(0.5)
                continue
            end
            if not Deps.Config.get("FastAttack") then
                task.wait(0.5)
                continue
            end
            
            local char = getPlayer().Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local tool = getEquippedTool()
                    if tool and tool.ToolTip ~= "Gun" then
                        local enemies, basePart = collectEnemiesInRange(100)
                        if #enemies > 0 and basePart then
                            pcall(function()
                                attackRemote:FireServer(0)
                                hitRemote:FireServer(basePart, enemies)
                            end)
                        end
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end

function Combat.stopFastAttack()
    fastAttackRunning = false
    if fastAttackThread then
        pcall(function() task.cancel(fastAttackThread) end)
        fastAttackThread = nil
    end
end

function Combat.autoClick()
    if autoClickRunning then return end
    autoClickRunning = true
    
    autoClickThread = task.spawn(function()
        while autoClickRunning do
            if not Deps.Config.get("AutoFarmLevel") then
                task.wait(0.5)
                continue
            end
            if not Deps.Config.get("AutoClick") then
                task.wait(0.5)
                continue
            end
            
            local char = getPlayer().Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and char:FindFirstChildOfClass("Tool") then
                    local vu = game:GetService("VirtualUser")
                    pcall(function()
                        vu:CaptureController()
                        vu:Button1Down(Vector2.new(1280, 672))
                    end)
                end
            end
            task.wait(0.1)
        end
    end)
end

function Combat.stopAutoClick()
    autoClickRunning = false
    if autoClickThread then
        pcall(function() task.cancel(autoClickThread) end)
        autoClickThread = nil
    end
end

function Combat.attackMob(mob)
    if not mob or not mob.Parent then return end
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not mobHRP then return end
    
    local height = Deps.Config.get("MobHeight") or 20
    Deps.Teleporter.toMob(mob, height)
end

function Combat.enableAll()
    if Deps.Config.get("FastAttack") then
        Combat.fastAttack()
    end
    if Deps.Config.get("AutoClick") then
        Combat.autoClick()
    end
end

function Combat.disableAll()
    Combat.stopFastAttack()
    Combat.stopAutoClick()
end

return Combat