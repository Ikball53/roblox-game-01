# Golden Core Miner

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/Ikball53/roblox-game-01/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/Ikball53/roblox-game-01/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

A 2D arcade mining game for the [make.fun roblox-game-01 bounty](https://make.fun/bounty/roblox-game-01). Dig through three zones, dodge falling rocks, spend gems in the Workshop, and break the Golden Core.

Play it here: https://www.roblox.com/games/95165377962088/Tempat-CPO1953

## How to play

Tap an ore to walk over and mine it. Every ore takes a few hits and visibly cracks before it breaks into gems. Earn enough gems to unlock the next zone, deeper and richer than the last. Reach the Core zone and break the **Golden Core** to win the run.

Rocks fall without warning. A red ring marks the spot a moment before impact — if the rock lands on your miner, you lose a heart. You have three hearts. Press **DASH** (or double-tap the field) for a brief dodge.

## Controls

- **Tap / click an ore** — walk over and mine it
- **DASH button** — dodge for one second (short cooldown)
- **Double-tap the field** — dash, without reaching for the button
- **WORKSHOP button** — open the upgrade shop

## Zones

- **Surface — Copper Vein.** Copper and tin, 2 hits, 1 gem each. Free.
- **Deep — Sapphire Vein.** Sapphire and emerald, 3–4 hits, 3–5 gems. Unlocks at 25 gems.
- **Core — Golden Core.** Gold and ruby, 4–5 hits, 6–8 gems, plus the Golden Core itself (15 hits). Unlocks at 60 gems.

## Workshop

Spend gems on three upgrade tracks, three levels each:

- **Pickaxe** — +1 damage on every hit.
- **Swift Boots** — dash recharges faster.
- **Lucky Magnet** — +1 bonus gem on every break.

## Finish

Breaking the Golden Core ends the run with a win screen: run time, gems earned, ores mined, and pickaxe level. Losing all three hearts ends the run too. **PLAY AGAIN** starts a fresh run.

## Design notes

The whole game is GUI: the field, the ores, the miner and the shop are all drawn in Luau, so the game reads at a glance in a screenshot and plays with one thumb on a phone. The 3D stage is only a backdrop — a mine mouth with crystals and boulders — so the place is a real world, not an empty room. A run lasts two to three minutes: short enough to finish, long enough to need the Workshop.

## Build

Rojo 7.7 project. Build the place, then hand it in:

```sh
rojo build default.project.json --output game.rbxl
MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` copies `game.rbxl`, `PLAY.json`, `src/` and the screenshots into the output directory and writes `dossier.json` there with the kit's `buildDossier`.

## Layout

- `src/shared/GameData.luau` — zones, ores, upgrades, tuning.
- `src/server/Stage.server.luau` — the mine-mouth stage (baseplate, entrance, crystals, spawn).
- `src/client/Miner.client.luau` — the game: screens, run flow, rocks, dash, workshop.
- `src/client/OreField.luau` — the ore grid, the Golden Core banner, rock warnings.
- `src/client/GuiKit.luau` — small GUI building helpers.
- `main.ts` — the hand-in program.
- `vendor/makefun-roblox.ts` — the kit's dossier library, unchanged.
