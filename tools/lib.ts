import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";

export const ROOT = new URL("..", import.meta.url).pathname.replace(/\/$/, "");

export interface File {
  path: string;
  src: string;
  sha1: string;
  bytes: number;
}

export interface Manifest {
  version: string;
  files: File[];
}

function walk(dir: string, out: string[] = []): string[] {
  for (const name of readdirSync(dir).sort()) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) walk(full, out);
    else out.push(full);
  }
  return out;
}

function entry(src: string, path: string): File {
  const body = readFileSync(join(ROOT, src));
  return { path, src, sha1: createHash("sha1").update(body).digest("hex"), bytes: body.length };
}

// No timestamp field: the manifest has to be stable enough that a diff means
// the tree and the manifest actually disagree.
export function build(): Manifest {
  const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8"));
  // programs install to root so you can type `discover`, not `programs/discover`
  const files = walk(join(ROOT, "src")).map((full) => {
    const src = relative(ROOT, full).split(sep).join("/");
    const path = src.startsWith("src/programs/")
      ? src.slice("src/programs/".length)
      : src.slice("src/".length);
    return entry(src, path);
  });

  files.push(entry("installer.lua", "ccs/installer.lua"));
  files.sort((a, b) => a.path.localeCompare(b.path));
  return { version: pkg.version, files };
}

export function serialise(manifest: Manifest): string {
  return JSON.stringify(manifest, null, 2) + "\n";
}
