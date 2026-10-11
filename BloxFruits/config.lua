local Config = {}
Config.__index = Config

Config.data = {
    AutoFarmLevel = false,
    AutoQuest = false,
    
    SelectWeapon = "Melee",
    TeleportSpeed = 300,
    MobHeight = 20,
    
    AutoEquip = true,
    BringMob = true,
    FastAttack = true,
    AutoClick = true,
    NoClip = true,
    AntiAFK = true,
    AutoBusoHaki = true,
}

Config._listeners = {}

function Config.get(key)
    return Config.data[key]
end

function Config.set(key, value)
    Config.data[key] = value
    Config._emit(key, value)
end

function Config.onChange(key, callback)
    if not Config._listeners[key] then
        Config._listeners[key] = {}
    end
    table.insert(Config._listeners[key], callback)
end

function Config._emit(key, value)
    if Config._listeners[key] then
        for _, cb in ipairs(Config._listeners[key]) do
            pcall(cb, value)
        end
    end
end

function Config.save()
    if not writefile then return false end
    return pcall(function()
        local HttpService = game:GetService("HttpService")
        if makefolder and not isfolder("AutoFarmLevel") then
            makefolder("AutoFarmLevel")
        end
        writefile("AutoFarmLevel/config.json", HttpService:JSONEncode(Config.data))
    end)
end

function Config.load()
    if not (isfile and isfile("AutoFarmLevel/config.json")) then return false end
    local ok, result = pcall(function()
        local HttpService = game:GetService("HttpService")
        return HttpService:JSONDecode(readfile("AutoFarmLevel/config.json"))
    end)
    if ok and result then
        for k, v in pairs(result) do
            Config.data[k] = v
        end
        return true
    end
    return false
end

return Config