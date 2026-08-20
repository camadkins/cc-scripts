import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";

export const REPO_ROOT = new URL("..", import.meta.url).pathname.replace(/\/$/, "");

export interface ManifestEntry {
  /** Where the file lands on the ComputerCraft computer. */
  path: string;
  /** Where the file lives in this repo. */
  src: string;
  sha1: string;
  bytes: number;
}

export interface Manifest {
  version: string;
  files: ManifestEntry[];
}

/** installer.lua sits at the repo root but installs into /ccs/ so it can update itself. */
const EXTRA: Array<{ src: string; path: string }> = [
  { src: "installer.lua", path: "ccs/installer.lua" },
];

function walk(dir: string, out: string[] = []): string[] {
  for (const name of readdirSync(dir).sort()) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) walk(full, out);
    else out.push(full);
  }
  return out;
}

/**
 * Build the manifest from the working tree.
 *
 * No timestamp field by design: a generated_at would make every rebuild a diff,
 * and the manifest has to be stable enough that `git diff --exit-code` means
 * "the tree and the manifest agree".
 */
export function buildManifest(root = REPO_ROOT): Manifest {
  const pkg = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
  const files: ManifestEntry[] = [];

  const toPosix = (p: string) => p.split(sep).join("/");

  for (const full of walk(join(root, "src"))) {
    const repoPath = toPosix(relative(root, full));
    files.push(entry(root, repoPath, repoPath.replace(/^src\//, "")));
  }
  for (const { src, path } of EXTRA) files.push(entry(root, src, path));

  files.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));
  return { version: pkg.version, files };
}

function entry(root: string, repoPath: string, installPath: string): ManifestEntry {
  const body = readFileSync(join(root, repoPath));
  return {
    path: installPath,
    src: repoPath,
    sha1: createHash("sha1").update(body).digest("hex"),
    bytes: body.length,
  };
}

export function serialise(manifest: Manifest): string {
  return JSON.stringify(manifest, null, 2) + "\n";
}
