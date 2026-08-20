#!/usr/bin/env bun
/**
 * Parse every .lua file in the repo as Lua 5.2 (CC:Tweaked's dialect).
 *
 * This is a syntax gate, not a test suite: there is no CC runtime here, so the
 * most it can prove is that nothing shipped with a typo that would fail to load
 * on a computer in game.
 */
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import luaparse from "luaparse";

const ROOT = new URL("..", import.meta.url).pathname.replace(/\/$/, "");
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
  const rel = relative(ROOT, file);
  try {
    luaparse.parse(readFileSync(file, "utf8"), { luaVersion: "5.2", comments: false });
    console.log(`  ok    ${rel}`);
  } catch (error) {
    failed += 1;
    console.error(`  FAIL  ${rel}: ${(error as Error).message}`);
  }
}

console.log(`${files.length} lua file(s), ${failed} failed`);
if (files.length === 0) {
  console.error("no lua files found - the linter is not looking where it should be");
  process.exit(1);
}
process.exit(failed === 0 ? 0 : 1);
