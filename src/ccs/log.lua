--- Leveled logging to the terminal, and optionally to a file.
--
-- Terminal colour is guarded because a basic (non-advanced) computer has no
-- colour support and setTextColour would throw there.
local log = {}

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }

log.level = "info"
log.file = nil

local COLOURS = {
  debug = colours.lightGrey,
  info  = colours.white,
  warn  = colours.yellow,
  error = colours.red,
}

local function stamp()
  return textutils.formatTime(os.time(), true)
end

local function emit(level, message)
  if LEVELS[level] < LEVELS[log.level] then return end

  local line = ("[%s] %s  %s"):format(stamp(), level:upper(), message)

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
function log.info(message)  emit("info", message) end
function log.warn(message)  emit("warn", message) end
function log.error(message) emit("error", message) end

--- Route log output to a file in addition to the terminal.
function log.toFile(path)
  log.file = path
end

return log
