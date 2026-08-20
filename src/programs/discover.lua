-- Read-only peripheral discovery. Never calls a peripheral method.
--   discover              print
--   discover out.json     print and dump JSON
package.path = "/?.lua;/?/init.lua;" .. package.path

local util = require("ccs.util")
local out = ({ ... })[1]

-- getType returns varargs, not one string. A chest is both minecraft:chest and
-- inventory, and the generic traits are the useful half.
local function typesOf(name)
  local got = { pcall(peripheral.getType, name) }
  if not got[1] then return nil, tostring(got[2]) end

  local types = {}
  for i = 2, #got do
    if got[i] ~= nil then types[#types + 1] = tostring(got[i]) end
  end
  return types
end

local function methodsOf(name)
  local ok, list = pcall(peripheral.getMethods, name)
  if not ok then return nil, tostring(list) end

  local methods = {}
  for _, method in ipairs(list or {}) do methods[#methods + 1] = tostring(method) end
  table.sort(methods)
  return methods
end

local SIDES = { top = true, bottom = true, left = true, right = true, front = true, back = true }

local function scan(name)
  local types, typeErr = typesOf(name)
  local methods, methodErr = methodsOf(name)
  return {
    name = name,
    -- a side name means the block is touching the computer; anything else came
    -- over a wired network. The same block can show up as both.
    attachment = SIDES[name] and "direct" or "network",
    types = types or {},
    methods = methods or {},
    errors = { types = typeErr, methods = methodErr },
  }
end

local names = peripheral.getNames()
table.sort(names)

local found = {}
for _, name in ipairs(names) do found[#found + 1] = scan(name) end

local lines = {
  "OVERNET DISCOVERY",
  "",
  "Computer: " .. os.getComputerID(),
  "Host: " .. tostring(_HOST),
  "",
}

for _, device in ipairs(found) do
  lines[#lines + 1] = device.name .. "  (" .. device.attachment .. ")"
  lines[#lines + 1] = ""

  lines[#lines + 1] = "Types:"
  if #device.types == 0 then
    lines[#lines + 1] = "  (none reported)"
  else
    for _, kind in ipairs(device.types) do lines[#lines + 1] = "  " .. kind end
  end
  lines[#lines + 1] = ""

  lines[#lines + 1] = "Methods:"
  if #device.methods == 0 then
    lines[#lines + 1] = "  (none reported)"
  else
    for _, method in ipairs(device.methods) do lines[#lines + 1] = "  " .. method end
  end

  if device.errors.types then lines[#lines + 1] = "  !! types: " .. device.errors.types end
  if device.errors.methods then lines[#lines + 1] = "  !! methods: " .. device.errors.methods end
  lines[#lines + 1] = ""
end

lines[#lines + 1] = #found .. " peripherals"

if out then
  -- dumping to a file: one line per device, the detail is in the file
  for _, device in ipairs(found) do
    print(("%s (%s)  [%s]  %d methods"):format(
      device.name, device.attachment, table.concat(device.types, ", "), #device.methods))
  end
  print(#found .. " peripherals")

  util.write(out, textutils.serialiseJSON({
    computer = os.getComputerID(),
    host = tostring(_HOST),
    time = os.date("%Y-%m-%dT%H:%M:%S"),
    peripherals = found,
  }))
  print("wrote " .. out)
else
  print(table.concat(lines, "\n"))
end
