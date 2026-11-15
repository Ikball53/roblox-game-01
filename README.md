# Golden Sky Tower — make.fun roblox-game-01 entry

A 3D obby tower climb. Twelve stages spiral around a central column:
jump the platforms, ride the moving ones from stage 4, dodge the red
kill bars from stage 6, touch green to save a checkpoint, and reach the
gold pad on top to win. A timer, stage and death counter stay on
screen, and the win screen shows your climb time with a Play Again
button that restarts the climb.

## Layout

- `default.project.json` — the Rojo project: baseplate, spawn pad,
  central column, four neon pillars, lighting, and the service mounts.
- `src/shared/TowerLayout.luau` — the tower as data: 12 stages, the
  spiral positions, the palette, the win and return pads.
- `src/shared/GameConfig.luau` — every tuning number in one place.
- `src/server/TowerBuilder.luau` — turns the plan into parts.
- `src/server/PlayerState.luau` — each climber's progress, server-side.
- `src/server/Main.server.luau` — builds the tower and wires every touch.
- `src/client/Hud.client.luau` — the title, stage, timer, deaths, and
  the win screen.
- `game.rbxl` — the place, built with `rojo build`.
- `main.ts` — hands the entry in: copies the game, sources, screenshots
  and PLAY.json to `/output` and writes `/output/dossier.json`.

## Build

```
rojo build default.project.json --output game.rbxl
MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Still missing before submit

1. **Publish the experience.** PLAY.json still holds placeholder zeros.
   The owner must publish this place on Roblox as a Public experience
   (Studio, Windows or macOS), then fill in the real `place_id` and
   `universe_id` here. Never invent ids.
2. **Screenshots.** `screenshots/` holds no images yet. They must be
   taken while the game runs in Studio (start, play, end), 3 or 4 of
   them, each at most 256 KiB. See `screenshots/NOTE.md`.
