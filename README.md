# cc-scripts

ComputerCraft Lua, pulled from GitHub.

## Install

On any computer:

```
wget run https://raw.githubusercontent.com/camadkins/cc-scripts/main/installer.lua
```

## Use

```
update                              pull latest
/ccs/installer.lua check            show what would change
/ccs/installer.lua version          installed version
/ccs/installer.lua uninstall        remove everything
/ccs/installer.lua update --branch=dev
```

## Layout

```
installer.lua      ->  /ccs/installer.lua
src/ccs/*.lua      ->  /ccs/*.lua          shared lib
src/programs/*.lua ->  /programs/*.lua     runnable
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

## License

MIT
