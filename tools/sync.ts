#!/usr/bin/env bun
// Copies the tree into a live world's computer dir, install layout.
// Machine paths live in .ccsync.json, untracked because this repo is public.
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { build, ROOT, serialise } from "./lib.ts";

function die(message: string): never {
  console.error(message);
  process.exit(1);
}

function flag(name: string) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? undefined : process.argv[i + 1];
}

const configPath = join(ROOT, ".ccsync.json");
if (!existsSync(configPath)) die("missing .ccsync.json, copy .ccsync.example.json");

const config = JSON.parse(readFileSync(configPath, "utf8"));
const world = flag("world") ?? config.world;
const id = flag("id") ?? config.computerId ?? 0;
const dry = process.argv.includes("--dry");

if (!existsSync(config.instanceDir)) die(`no such instanceDir: ${config.instanceDir}`);

const saves = join(config.instanceDir, "saves");
const worldDir = join(saves, world);
if (!existsSync(worldDir)) die(`no such world: ${world}\nhave: ${readdirSync(saves).join(", ")}`);

const cc = join(worldDir, "computercraft");
if (!existsSync(cc)) die(`${world} has no computercraft dir, load it once with CC installed`);

const target = join(cc, "computer", String(id));
const manifest = build();

console.log(`${world} / computer ${id}`);

if (dry) {
  for (const file of manifest.files) console.log(`  would write ${file.path}`);
  process.exit(0);
}

for (const file of manifest.files) {
  const dest = join(target, file.path);
  mkdirSync(join(dest, ".."), { recursive: true });
  copyFileSync(join(ROOT, file.src), dest);
  console.log(`  ${file.path}`);
}

// match what the installer leaves behind
writeFileSync(join(target, "ccs", "manifest.json"), serialise(manifest));
writeFileSync(
  join(target, "update.lua"),
  'local args = { ... }\nshell.run("/ccs/installer.lua", "update", table.unpack(args))\n',
);

console.log(`${manifest.files.length + 2} files, reboot the computer`);
