# cc-scripts

Overnet is a modular monitoring, control, telemetry, and HMI framework for CC:Tweaked in
modded Minecraft. You install the platform, then only the integrations for the mods you
actually run.

CCS is the infrastructure underneath it: installer, updater, logging, generic helpers.
Overnet may use CCS. CCS never depends on Overnet.

ATM10 is the current test environment, not the target. Overnet should work in any pack,
including worlds with no Mekanism at all.

Nothing under `src/overnet/` exists yet. Devices, capabilities, and drivers get designed
from real peripheral data, not ahead of it.

## Install

On any computer:

```
wget run https://raw.githubusercontent.com/camadkins/cc-scripts/main/installer.lua
```

## Use

```
discover                            list peripherals
discover /out.json                  ... and dump JSON
inspect <peripheral>                types and methods for one
probe <peripheral> <method>         call one named method, show what returns

update                              pull latest
/ccs/installer.lua check            show what would change
/ccs/installer.lua version          installed version
/ccs/installer.lua uninstall        remove everything
/ccs/installer.lua update --branch=dev
```

## Layout

```
installer.lua      ->  /ccs/installer.lua
src/ccs/*.lua      ->  /ccs/*.lua          infrastructure
src/overnet/**     ->  /overnet/**         the platform (not built yet)
src/programs/*.lua ->  /*.lua              runnable, on the shell path
manifest.json      ->  /ccs/manifest.json  generated file list
```

## Dev

Needs [bun](https://bun.sh).

```
bun install
cp .ccsync.example.json .ccsync.json    # point it at your instance
```

Loop:

```
bun tools/sync.ts        copy into the world, then reboot the computer
bun tools/lint.ts        parse every .lua
bun tools/manifest.ts    rebuild manifest.json
git push
bun tools/raw.ts         check every url is live
```

Rebuild the manifest before pushing or `update` breaks for everyone. `bun tools/manifest.ts --check` catches it.

`sync.ts` copies, never deletes.

`discover` and `inspect` never call a peripheral method. `probe` calls exactly the one
you name and nothing else.

The installer resolves `main` to a commit sha through the GitHub API, then fetches every
file at that sha. Branch paths on raw.githubusercontent serve stale for about five
minutes and ignore both a cache-busting query string and a no-cache header; a sha is a
different URL every push. Costs one API call per update, against a 60/hour anonymous
limit. If the API is unreachable it falls back to the branch and says so.

## License

MIT
