#!/usr/bin/env bun
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { build, ROOT, serialise } from "./lib.ts";

const target = join(ROOT, "manifest.json");
const next = serialise(build());

if (process.argv.includes("--check")) {
  const current = readFileSync(target, "utf8");
  if (current !== next) {
    console.error("manifest.json out of date, run: bun tools/manifest.ts");
    process.exit(1);
  }
  console.log("manifest.json up to date");
  process.exit(0);
}

writeFileSync(target, next);
const manifest = JSON.parse(next);
console.log(`${manifest.version}, ${manifest.files.length} files`);
for (const file of manifest.files) console.log(`  ${file.sha1.slice(0, 8)}  ${file.path}`);
