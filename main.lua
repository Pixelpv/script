local BASE_URL = "https://raw.githubusercontent.com/Pixelpv/script/refs/heads/main"

local function httpGet(url)
    if game.HttpGet then
        local ok, res = pcall(game.HttpGet, game, url)
        if ok then return res end
    end
    if request then
        local ok, res = pcall(request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    if http_request then
        local ok, res = pcall(http_request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    return nil
end

local function loadModule(path)
    local url = BASE_URL .. "/" .. path
    local src = httpGet(url)
    if not src then
        error("[AutoFarmLevel] Falha ao baixar: " .. path)
    end
    local fn, err = loadstring(src)
    if not fn then
        error("[AutoFarmLevel] Erro ao compilar " .. path .. ": " .. tostring(err))
    end
    return fn()
end

if getgenv().AutoFarmLevel and getgenv().AutoFarmLevel.Loaded then
    if getgenv().AutoFarmLevel.UI and getgenv().AutoFarmLevel.UI.Window then
        pcall(function()
            getgenv().AutoFarmLevel.UI.Window:Destroy()
        end)
    end
end

local Config = loadModule("BloxFruits/config.lua")
local Quests = loadModule("BloxFruits/data/quests.lua")

Config.load()

local Quest = loadModule("BloxFruits/module/quest.lua")
local Detector = loadModule("BloxFruits/module/detector.lua")
local Teleporter = loadModule("BloxFruits/module/teleporter.lua")
local Combat = loadModule("BloxFruits/module/combat.lua")
local Weapon = loadModule("BloxFruits/module/weapon.lua")
local AFK = loadModule("BloxFruits/module/afk.lua")
local Haki = loadModule("BloxFruits/module/haki.lua")
local FarmLevel = loadModule("BloxFruits/module/farmlevel.lua")
local UI = loadModule("BloxFruits/ui.lua")

Quest.init({ Quests = Quests, Config = Config })
Detector.init({ Config = Config })
Teleporter.init({ Config = Config })
Combat.init({ Config = Config, Teleporter = Teleporter })
Weapon.init({ Config = Config })
AFK.init({ Config = Config })
Haki.init({ Config = Config })
FarmLevel.init({
    Config = Config,
    Quest = Quest,
    Detector = Detector,
    Teleporter = Teleporter,
    Combat = Combat,
    Weapon = Weapon,
})

UI.init({
    Config = Config,
    Quest = Quest,
    Detector = Detector,
    Teleporter = Teleporter,
    Combat = Combat,
    Weapon = Weapon,
    AFK = AFK,
    Haki = Haki,
    FarmLevel = FarmLevel,
})

UI.create()
UI.applySavedConfig()

task.spawn(function()
    local RunService = game:GetService("RunService")
    RunService.Stepped:Connect(function()
        if not Config.get("AutoFarmLevel") then return end
        if not Config.get("NoClip") then return end
        
        local plr = game:GetService("Players").LocalPlayer
        local char = plr.Character
        if not char then return end
        
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end)

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Config.get("AutoFarmLevel") and Config.get("AutoEquip") then
        Weapon.equip()
    end
    if Config.get("AutoFarmLevel") and Config.get("AutoBusoHaki") then
        Haki.activateBuso()
    end
end)

getgenv().AutoFarmLevel = {
    Loaded = true,
    Config = Config,
    Quests = Quests,
    Quest = Quest,
    Detector = Detector,
    Teleporter = Teleporter,
    Combat = Combat,
    Weapon = Weapon,
    AFK = AFK,
    Haki = Haki,
    FarmLevel = FarmLevel,
    UI = UI,
    Version = "1.0.0",
}

print("[AutoFarmLevel] v1.0.0 carregado com sucesso")