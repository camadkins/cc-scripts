#!/usr/bin/env bun
/**
 * Confirm every file in manifest.json is actually fetchable over the same raw
 * URL the in-game installer will use. Catches a manifest that was committed
 * before the files it lists were pushed.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { REPO_ROOT, type Manifest } from "./manifest-lib.ts";

const OWNER = process.env.CCS_OWNER ?? "camadkins";
const REPO = process.env.CCS_REPO ?? "cc-scripts";
const BRANCH = process.env.CCS_BRANCH ?? "main";

const manifest: Manifest = JSON.parse(readFileSync(join(REPO_ROOT, "manifest.json"), "utf8"));
const targets = ["manifest.json", ...manifest.files.map((file) => file.src)];

let failed = 0;

for (const target of targets) {
  const url = `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${target}?cb=${Date.now()}`;
  const response = await fetch(url, { method: "GET", headers: { "Cache-Control": "no-cache" } });
  const status = response.status;
  await response.arrayBuffer();
  if (status === 200) {
    console.log(`  200  ${target}`);
  } else {
    failed += 1;
    console.error(`  ${status}  ${target}`);
  }
}

console.log(`${targets.length} url(s), ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
