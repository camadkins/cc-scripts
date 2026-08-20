#!/usr/bin/env bun
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import luaparse from "luaparse";
import { ROOT } from "./lib.ts";

const SKIP = new Set(["node_modules", ".git"]);

function walk(dir: string, out: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    if (SKIP.has(name)) continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) walk(full, out);
    else if (full.endsWith(".lua")) out.push(full);
  }
  return out;
}

const files = walk(ROOT).sort();
let failed = 0;

for (const file of files) {
  try {
    luaparse.parse(readFileSync(file, "utf8"), { luaVersion: "5.2", comments: false });
    console.log(`  ok    ${relative(ROOT, file)}`);
  } catch (error) {
    failed++;
    console.error(`  FAIL  ${relative(ROOT, file)}: ${(error as Error).message}`);
  }
}

console.log(`${files.length} lua, ${failed} failed`);
process.exit(failed === 0 && files.length > 0 ? 0 : 1);
