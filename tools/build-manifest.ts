#!/usr/bin/env bun
/**
 * Regenerate manifest.json from the working tree.
 *
 *   bun tools/build-manifest.ts            write it
 *   bun tools/build-manifest.ts --check    exit 1 if it is out of date
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildManifest, REPO_ROOT, serialise } from "./manifest-lib.ts";

const target = join(REPO_ROOT, "manifest.json");
const next = serialise(buildManifest());

if (process.argv.includes("--check")) {
  let current = "";
  try {
    current = readFileSync(target, "utf8");
  } catch {
    console.error("manifest.json is missing; run: bun tools/build-manifest.ts");
    process.exit(1);
  }
  if (current !== next) {
    console.error("manifest.json is out of date; run: bun tools/build-manifest.ts");
    process.exit(1);
  }
  console.log("manifest.json is up to date.");
  process.exit(0);
}

writeFileSync(target, next);
const { files, version } = JSON.parse(next);
console.log(`manifest.json: version ${version}, ${files.length} files`);
for (const file of files) console.log(`  ${file.sha1.slice(0, 8)}  ${file.path}`);
