-- inspect <peripheral>  -- read-only. Never calls a peripheral method.
local name = ({ ... })[1]

if not name then
  print("usage: inspect <peripheral>")
  return
end

if not peripheral.isPresent(name) then
  print("no peripheral named " .. name)
  local names = peripheral.getNames()
  table.sort(names)
  print("attached: " .. (#names > 0 and table.concat(names, ", ") or "none"))
  return
end

-- getType returns varargs; keep all of them
local got = { pcall(peripheral.getType, name) }
local SIDES = { top = true, bottom = true, left = true, right = true, front = true, back = true }
local lines = { name .. "  (" .. (SIDES[name] and "direct" or "network") .. ")", "", "Types:" }

if not got[1] then
  lines[#lines + 1] = "  !! " .. tostring(got[2])
elseif #got < 2 then
  lines[#lines + 1] = "  (none reported)"
else
  for i = 2, #got do
    if got[i] ~= nil then lines[#lines + 1] = "  " .. tostring(got[i]) end
  end
end

lines[#lines + 1] = ""
lines[#lines + 1] = "Methods:"

local ok, list = pcall(peripheral.getMethods, name)
if not ok then
  lines[#lines + 1] = "  !! " .. tostring(list)
else
  local methods = {}
  for _, method in ipairs(list or {}) do methods[#methods + 1] = tostring(method) end
  table.sort(methods)
  if #methods == 0 then
    lines[#lines + 1] = "  (none reported)"
  else
    for _, method in ipairs(methods) do lines[#lines + 1] = "  " .. method end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = #methods .. " methods"
end

textutils.pagedPrint(table.concat(lines, "\n"))
