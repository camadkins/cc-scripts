--- Demo program: proves the library loaded and the install is intact.
--
-- The package.path line is how every program in this repo reaches the shared
-- library; installed files live under / so a leading-slash search path works.
package.path = "/?.lua;/?/init.lua;" .. package.path

local log     = require("ccs.log")
local util    = require("ccs.util")
local version = require("ccs.version")

log.info(("cc-scripts %s (%d files installed)"):format(version.version, version.files))

local monitor, name = util.findPeripheral("monitor")
if monitor then
  log.info("Found a monitor on " .. name)
  monitor.setTextScale(1)
  monitor.clear()
  monitor.setCursorPos(1, 1)
  monitor.write("cc-scripts " .. version.version)
else
  log.info("No monitor attached; terminal only.")
end

log.info("Uptime " .. util.duration(os.clock()))
log.info("Hello from a GitHub-backed computer.")
