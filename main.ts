// Golden Core Miner — the hand-in program for the make.fun roblox-game-01 entry.
//
// It gathers the finished game out of this repository and into the
// directory the grader reads: the place file, the play link, the Luau
// sources and the screenshots, plus a dossier the scorer rebuilds and
// compares byte for byte. It is deterministic on purpose — run it twice
// and both outputs match exactly.
//
// Run it from anywhere; it finds the repository from its own file, not
// from the working directory:
//
//   MAKEFUN_OUTPUT_DIR=out node main.ts

import { cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

// The repository is wherever this file lives, no matter where the
// command was started from. That is the whole point: the grader runs
// this program from its own sandbox directory, and a working-directory
// lookup would point at the wrong place entirely.
const repo = dirname(fileURLToPath(import.meta.url));

// The hand-in goes where MAKEFUN_OUTPUT_DIR points, or to /output,
// the directory the grader reads. A relative value is taken as-is,
// exactly like the kit starter does.
const handIn = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Never hand the repository into itself: an output directory equal to
// the repository root would copy the game over its own sources.
if (resolve(handIn) === repo) {
	fail("MAKEFUN_OUTPUT_DIR must not be the repository root itself");
}

// The dossier caps, copied from the kit starter: only the text cap
// shapes the bytes; the rest only refuse an oversized entry, so passing
// them keeps this program honest about what the scorer will accept.
const dossierCaps = {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
};

// The single files the entry hands in, and the source tree.
const looseFiles = ["game.rbxl", "PLAY.json"];
const trees = ["src"];

function fail(message: string): never {
	throw new Error(message);
}

mkdirSync(handIn, { recursive: true });

for (const name of looseFiles) {
	const from = join(repo, name);
	if (!existsSync(from)) {
		fail(`missing entry input: ${name}`);
	}
	cpSync(from, join(handIn, name));
}

for (const name of trees) {
	const from = join(repo, name);
	if (!existsSync(from)) {
		fail(`missing entry input: ${name}`);
	}
	cpSync(from, join(handIn, name), { recursive: true });
}

// Screenshots travel image by image. A stray note or any other file
// sitting beside the captures stays behind, because the dossier
// builder refuses a screenshots folder holding anything that is not a
// PNG or a JPEG.
const shotsFrom = join(repo, "screenshots");
const shotsTo = join(handIn, "screenshots");
mkdirSync(shotsTo, { recursive: true });
let shotCount = 0;
if (existsSync(shotsFrom)) {
	for (const name of readdirSync(shotsFrom)) {
		if (/\.(png|jpe?g)$/i.test(name)) {
			cpSync(join(shotsFrom, name), join(shotsTo, name));
			shotCount += 1;
		}
	}
}

// The dossier is built from the hand-in itself, so it always describes
// exactly what was handed in. Its bytes go to dossier.json verbatim.
const dossier = buildDossier(handIn, dossierCaps);
writeFileSync(join(handIn, "dossier.json"), dossier);

console.log(`Golden Core Miner handed in: dossier.json is ${dossier.length} bytes, ${shotCount} screenshots.`);
