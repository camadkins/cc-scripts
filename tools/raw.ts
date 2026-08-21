#!/usr/bin/env bun
// Checks every manifest path over the same URL shape the installer uses:
// a commit sha, not the branch, because branch paths serve stale for ~5 min.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { ROOT, type Manifest } from "./lib.ts";

const OWNER = process.env.CCS_OWNER ?? "camadkins";
const REPO = process.env.CCS_REPO ?? "cc-scripts";
const BRANCH = process.env.CCS_BRANCH ?? "main";

const head = await fetch(`https://api.github.com/repos/${OWNER}/${REPO}/commits/${BRANCH}`, {
  headers: { Accept: "application/vnd.github.sha" },
});
if (!head.ok) {
  console.error(`cannot resolve ${BRANCH}: ${head.status}`);
  process.exit(1);
}
const ref = (await head.text()).trim();
console.log(`${BRANCH} = ${ref.slice(0, 8)}`);

const manifest: Manifest = JSON.parse(readFileSync(join(ROOT, "manifest.json"), "utf8"));
const targets = ["manifest.json", ...manifest.files.map((file) => file.src)];
let failed = 0;

for (const target of targets) {
  const response = await fetch(`https://raw.githubusercontent.com/${OWNER}/${REPO}/${ref}/${target}`);
  const body = await response.text();
  if (response.status !== 200) failed++;
  console.log(`  ${response.status}  ${target}`);

  // the point of pinning: served bytes must equal committed bytes
  if (target === "manifest.json" && body.trim() !== JSON.stringify(manifest, null, 2).trim()) {
    failed++;
    console.error("  !! served manifest does not match local manifest");
  }
}

console.log(`${targets.length} urls, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
