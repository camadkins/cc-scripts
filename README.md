# cc-scripts

ComputerCraft (CC:Tweaked) Lua, developed on a real computer and distributed from GitHub.
Any in-game computer installs with one line and updates with one word — the same shape
[cc-mek-scada](https://github.com/MikaylaFischler/cc-mek-scada) uses.

## Install on a ComputerCraft computer

```
wget run https://raw.githubusercontent.com/camadkins/cc-scripts/main/installer.lua
```

That fetches `manifest.json`, downloads every file it lists, and leaves an `update`
command behind.

## Update

```
update
```

Only files whose hash changed are re-downloaded. Output is a short diff:

```
  + programs/reactor.lua
  ~ ccs/log.lua
  - programs/old.lua
```

Other commands:

| command | what it does |
|---|---|
| `update` | pull whatever `main` currently has |
| `/ccs/installer.lua check` | show what would change, download nothing |
| `/ccs/installer.lua version` | print the installed release |
| `/ccs/installer.lua uninstall` | remove everything this repo installed |
| `/ccs/installer.lua update --branch=dev` | track a different branch |

## Layout

| repo | installs to | what it is |
|---|---|---|
| `installer.lua` | `/ccs/installer.lua` | self-contained installer and updater |
| `src/ccs/*.lua` | `/ccs/*.lua` | shared library |
| `src/programs/*.lua` | `/programs/*.lua` | runnable programs |
| `manifest.json` | `/ccs/manifest.json` | generated file list; the install contract |

Anything you drop under `src/` becomes installable the moment the manifest is rebuilt.
There is no build step for the Lua — what is in `src/` is what runs.

## Developing

Requires [bun](https://bun.sh). One-time setup:

```
bun install
cp .ccsync.example.json .ccsync.json   # then edit it to point at your instance
```

`.ccsync.json` holds machine-specific paths and is gitignored, because this repo is
public and must never carry a home directory or a world name.

The loop:

```
# edit src/programs/hello.lua
bun tools/sync-world.ts        # copy into the running world, install layout
# reboot the computer in game, run it
```

Then ship it:

```
bun tools/lint-lua.ts          # parse every .lua as Lua 5.2
bun tools/build-manifest.ts    # regenerate manifest.json
git commit -am "..." && git push
bun tools/check-raw.ts         # every manifest path returns 200 from raw.githubusercontent
```

`bun tools/build-manifest.ts --check` fails when the manifest and the tree disagree —
worth running before every push, since a stale manifest is the one way to ship a broken
`update` to everyone at once.

`sync-world.ts` copies; it never deletes. If you rename or remove a file, delete the old
one from the in-game computer yourself, or run `update` against a pushed manifest.

## Notes

- The installer downloads every changed file into memory before writing any of them, so a
  failed fetch mid-update leaves the previous version intact rather than a mix of two.
- Every raw URL carries a cache-busting `cb=` parameter. GitHub's CDN caches raw content
  for around five minutes, which is otherwise long enough to make a fresh push look like a
  no-op.
- No tokens, ever. The repo is public precisely so `http.get` needs no credentials.

## License

MIT
