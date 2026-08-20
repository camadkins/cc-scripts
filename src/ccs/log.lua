local log = {}

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
local COLOURS = {
  debug = colours.lightGrey,
  info = colours.white,
  warn = colours.yellow,
  error = colours.red,
}

log.level = "info"
log.file = nil

local function emit(level, message)
  if LEVELS[level] < LEVELS[log.level] then return end

  local line = ("[%s] %s  %s"):format(textutils.formatTime(os.time(), true), level:upper(), message)

  -- basic computers have no colour and setTextColour throws there
  if term.isColour and term.isColour() then
    local prev = term.getTextColour()
    term.setTextColour(COLOURS[level])
    print(line)
    term.setTextColour(prev)
  else
    print(line)
  end

  if log.file then
    local handle = fs.open(log.file, "a")
    if handle then
      handle.writeLine(line)
      handle.close()
    end
  end
end

function log.debug(message) emit("debug", message) end
function log.info(message) emit("info", message) end
function log.warn(message) emit("warn", message) end
function log.error(message) emit("error", message) end

return log
