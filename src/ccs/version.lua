--- The installed release, read back from the manifest the installer wrote.
--
-- Deliberately not a hardcoded string: the manifest is the only thing that
-- knows what actually landed on this computer.
local MANIFEST = "/ccs/manifest.json"

local unjson = textutils.unserialiseJSON or textutils.unserializeJSON

local version = { version = "unknown", files = 0 }

if fs.exists(MANIFEST) then
  local handle = fs.open(MANIFEST, "r")
  if handle then
    local parsed = unjson(handle.readAll())
    handle.close()
    if type(parsed) == "table" then
      version.version = tostring(parsed.version or "unknown")
      version.files = parsed.files and #parsed.files or 0
    end
  end
end

return version
