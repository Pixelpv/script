local NS = getgenv().AutoFarmBF

local Logger = {}

function Logger.log(...)
    if NS.Config and NS.Config.debug then
        print("[AutoFarm]", ...)
    end
end

function Logger.warn(...)
    warn("[AutoFarm]", ...)
end

function Logger.error(...)
    error("[AutoFarm] " .. table.concat({...}, " "))
end

return Logger
