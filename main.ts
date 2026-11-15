// Golden Sky Tower — the hand-in program for the make.fun roblox-game-01 entry.
//
// Run it from the repository root:
//
//   MAKEFUN_OUTPUT_DIR=out node main.ts
//
// It gathers the game into the output directory and writes the dossier
// there, so the scorer can check the entry without ever opening the
// repository itself. Everything it writes is deterministic: run it twice
// and the output directory holds the same bytes both times.

import { cpSync, existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { buildDossier } from './vendor/makefun-roblox.ts';

// The dossier's text is capped at 64 KiB: the scorer's buildDossier
// call uses this same cap, so our dossier.json must match it byte for
// byte. The other caps only refuse an oversized place; they never
// change the bytes, so they are left to the scorer.
const DOSSIER_TEXT_CAP = 65536;

// The single files the entry hands in, and the source tree.
const LOOSE_FILES = ['game.rbxl', 'PLAY.json'] as const;
const TREES = ['src'] as const;

// The screenshots folder is copied image by image: a local note or
// any other non-image file sitting beside the captures must never ride
// into the entry, because the dossier builder refuses a screenshots
// folder holding anything that is not a PNG or a JPEG.
const SCREENSHOT_DIR = 'screenshots';
const IMAGE_NAME = /\.(png|jpe?g)$/i;

// Where the game lives (the directory this program is run from) and
// where the hand-in goes (MAKEFUN_OUTPUT_DIR, or "out" beside it).
const repoRoot = resolve(process.cwd());
const handInDir = resolve(repoRoot, process.env.MAKEFUN_OUTPUT_DIR ?? 'out');

if (handInDir === repoRoot) {
  throw new Error('MAKEFUN_OUTPUT_DIR must not be the repository root itself');
}

// Check every input exists before touching the hand-in directory, so
// a missing file fails fast instead of failing after the previous
// output has already been wiped.
for (const name of [...LOOSE_FILES, ...TREES, SCREENSHOT_DIR]) {
  if (!existsSync(join(repoRoot, name))) {
    throw new Error(`missing entry input: ${name}`);
  }
}

// Start from an empty hand-in directory, so a file left over from an
// earlier run can never sneak into this entry.
rmSync(handInDir, { recursive: true, force: true });
mkdirSync(handInDir, { recursive: true });

// Copy each loose file.
for (const name of LOOSE_FILES) {
  cpSync(join(repoRoot, name), join(handInDir, name));
}

// Copy each tree whole, preserving its layout.
for (const name of TREES) {
  cpSync(join(repoRoot, name), join(handInDir, name), { recursive: true });
}

// Copy the screenshots one by one, taking only real captures. Anything
// else in the folder — a local note, a stray file — is left behind, so
// the hand-in holds exactly the images the dossier is built from.
mkdirSync(join(handInDir, SCREENSHOT_DIR), { recursive: true });
for (const name of readdirSync(join(repoRoot, SCREENSHOT_DIR))) {
  if (!IMAGE_NAME.test(name)) {
    continue;
  }
  cpSync(join(repoRoot, SCREENSHOT_DIR, name), join(handInDir, SCREENSHOT_DIR, name));
}

// The dossier is built from the hand-in directory itself, so it always
// describes exactly what was handed in. Its bytes go to dossier.json
// verbatim: no reformatting, no extra fields.
const dossier = buildDossier(handInDir, { text_max_bytes: DOSSIER_TEXT_CAP });
writeFileSync(join(handInDir, 'dossier.json'), dossier);

console.log(`Golden Sky Tower handed in: dossier.json is ${dossier.length} bytes.`);
