#!/usr/bin/env bun
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { ROOT, type Manifest } from "./lib.ts";

const OWNER = process.env.CCS_OWNER ?? "camadkins";
const REPO = process.env.CCS_REPO ?? "cc-scripts";
const BRANCH = process.env.CCS_BRANCH ?? "main";

const manifest: Manifest = JSON.parse(readFileSync(join(ROOT, "manifest.json"), "utf8"));
const targets = ["manifest.json", ...manifest.files.map((file) => file.src)];
let failed = 0;

for (const target of targets) {
  const url = `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${target}?cb=${Date.now()}`;
  const response = await fetch(url, { headers: { "Cache-Control": "no-cache" } });
  await response.arrayBuffer();
  if (response.status !== 200) failed++;
  console.log(`  ${response.status}  ${target}`);
}

console.log(`${targets.length} urls, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
