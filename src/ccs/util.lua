--- Small helpers shared by cc-scripts programs.
local util = {}

--- Read a whole file, or nil when it does not exist.
function util.readFile(path)
  if not fs.exists(path) then return nil end
  local handle = fs.open(path, "r")
  if not handle then return nil end
  local body = handle.readAll()
  handle.close()
  return body
end

--- Write a file, creating parent directories as needed.
function util.writeFile(path, content)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
  local handle = fs.open(path, "w")
  if not handle then error("cannot write " .. path) end
  handle.write(content)
  handle.close()
end

--- Find the first attached peripheral of a type, or nil.
function util.findPeripheral(kind)
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == kind then
      return peripheral.wrap(name), name
    end
  end
  return nil
end

--- Format a number of ticks/seconds as a short human duration.
function util.duration(seconds)
  seconds = math.floor(seconds)
  if seconds < 60 then return seconds .. "s" end
  if seconds < 3600 then return ("%dm%02ds"):format(seconds / 60, seconds % 60) end
  return ("%dh%02dm"):format(seconds / 3600, (seconds % 3600) / 60)
end

return util
