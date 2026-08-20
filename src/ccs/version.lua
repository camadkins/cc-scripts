local unjson = textutils.unserialiseJSON or textutils.unserializeJSON
local out = { version = "unknown", files = 0 }

local handle = fs.exists("/ccs/manifest.json") and fs.open("/ccs/manifest.json", "r")
if handle then
  local parsed = unjson(handle.readAll())
  handle.close()
  if type(parsed) == "table" then
    out.version = tostring(parsed.version or "unknown")
    out.files = parsed.files and #parsed.files or 0
  end
end

return out
