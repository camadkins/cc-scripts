-- Tab completion for the cc-scripts programs.
--
-- Lives in /startup/ rather than /startup.lua so it never clobbers yours; the
-- shell runs every file in that directory.
if not shell then return end

local function suffixes(options, typed)
  local out = {}
  for _, option in ipairs(options or {}) do
    if #option > #typed and option:sub(1, #typed) == typed then
      out[#out + 1] = option:sub(#typed + 1)
    end
  end
  table.sort(out)
  return out
end

local function peripherals(typed)
  return suffixes(peripheral.getNames(), typed)
end

local function methods(name, typed)
  if not name or not peripheral.isPresent(name) then return {} end
  return suffixes(peripheral.getMethods(name), typed)
end

shell.setCompletionFunction("inspect.lua", function(_, index, argument)
  if index == 1 then return peripherals(argument) end
end)

shell.setCompletionFunction("stock.lua", function(_, index, argument)
  if index == 1 then return peripherals(argument) end
end)

-- previous[1] is the program name, so the peripheral is previous[2]
shell.setCompletionFunction("probe.lua", function(_, index, argument, previous)
  if index == 1 then return peripherals(argument) end
  if index == 2 then return methods(previous[2], argument) end
end)
