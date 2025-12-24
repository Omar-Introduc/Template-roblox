--[[
    📝 Logger - Centralized Logging Module
    Handles logging with levels, source tracing, and client performance reporting.
]]

local Logger = {}
Logger.Level = {
    INFO = "INFO",
    WARNING = "WARNING",
    ERROR = "ERROR",
    CRITICAL = "CRITICAL",
    PERF = "PERF"
}

-- Icons for log levels
local ICONS = {
    INFO = "🟢",
    WARNING = "🟠",
    ERROR = "🔴",
    CRITICAL = "☠️",
    PERF = "💎"
}

-- Internal function to get source
local function getSource()
    -- Stack level 3 usually points to the caller of the public Log function
    local s = debug.info(3, "s")
    local n = debug.info(3, "n")
    return (s or "Unknown") .. ":" .. (n or "Unknown")
end

function Logger.Log(level, message)
    local prefix = ICONS[level] or "⚪"
    local source = getSource()
    local timestamp = os.date("%X")
    local formattedMsg = string.format("[%s] %s [%s] (%s): %s", timestamp, prefix, level, source, message)

    if level == Logger.Level.ERROR or level == Logger.Level.CRITICAL then
        warn(formattedMsg)
        if level == Logger.Level.CRITICAL then
            -- Optional: Add extra alerting for critical errors
            print(debug.traceback())
        end
    else
        print(formattedMsg)
    end
end

-- Function to handle performance reports (called from Server scripts receiving client data)
function Logger.reportPerformance(player, data)
    local fps = data.FPS or 0
    local ping = data.Ping or 0
    local mem = data.Memory or 0

    local msg = string.format("Player: %s | FPS: %d | Ping: %dms | Memory: %dMB", player.Name, fps, ping, mem)
    print(string.format("[%s] %s [PERF] (%s): %s", os.date("%X"), ICONS.PERF, "ClientReport", msg))
end

-- Helpers
function Logger.Info(msg) Logger.Log(Logger.Level.INFO, msg) end
function Logger.Warn(msg) Logger.Log(Logger.Level.WARNING, msg) end
function Logger.Error(msg) Logger.Log(Logger.Level.ERROR, msg) end
function Logger.Critical(msg) Logger.Log(Logger.Level.CRITICAL, msg) end

return Logger
