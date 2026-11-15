// Sky Tower Obby — the hand-in program for make.fun's roblox-game-01.
// It gathers the game (the place, its Luau, its screenshots and its
// play link) into the output directory and writes the dossier the
// scorer checks, using the kit's own library. Standard library only,
// no network, and the same bytes on every run.

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoRoot = dirname(fileURLToPath(import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

const IMAGE_SUFFIX = /\.(png|jpe?g)$/i;

function copyTree(from: string, to: string): void {
	mkdirSync(to, { recursive: true });
	cpSync(from, to, { recursive: true });
}

// Only the pictures travel: a note file in the folder is not a
// screenshot, and the dossier refuses any file that is not one.
function copyScreenshots(from: string, to: string): void {
	if (!existsSync(from)) {
		throw new Error(`screenshots folder is missing: ${from} — take the screenshots in Studio first (see screenshots/NOTE.md)`);
	}
	mkdirSync(to, { recursive: true });
	for (const entry of readdirSync(from, { withFileTypes: true })) {
		if (!entry.isFile() || !IMAGE_SUFFIX.test(entry.name)) {
			continue;
		}
		copyFileSync(join(from, entry.name), join(to, entry.name));
	}
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

copyFileSync(join(repoRoot, 'game.rbxl'), join(outDir, 'game.rbxl'));
copyTree(join(repoRoot, 'src'), join(outDir, 'src'));
copyScreenshots(join(repoRoot, 'screenshots'), join(outDir, 'screenshots'));
copyFileSync(join(repoRoot, 'PLAY.json'), join(outDir, 'PLAY.json'));

let dossier: Uint8Array;
try {
	dossier = buildDossier(outDir, { text_max_bytes: 65536 });
} catch (err) {
	throw new Error(`dossier build failed: ${(err as Error).message}`);
}
writeFileSync(join(outDir, 'dossier.json'), dossier);

console.log(`Sky Tower Obby handed in: dossier.json is ${dossier.length} bytes.`);
