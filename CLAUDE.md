# COMETO

Handheld sci-fi CRPG, converting from 2D to fixed-camera 3D. Godot 4.7, GDScript only, Mobile renderer, iPhone first (landscape).
The game boots into the title screen (`game/app.tscn`); a new game starts in the 3D town (`anjabi_town`, `maps/anjabi/town_3d.tscn`) on the Steps. The Steps and tavern terrace are a detailed insert inside the town (`maps/anjabi/district.tscn` with `insert = true`, placed at `INSERT_AT`); the mine yard is `anjabi_mine` (`maps/anjabi/mine_3d.tscn`). Every map is 3D. 3D maps extend `MapBuilder3D` (`maps/map_builder_3d.gd`).
Separate from the older 3D project in `~/cometographia-2`; nothing is shared.

## Run and test

```bash
GODOT=/Applications/Godot_mono-1.app/Contents/MacOS/Godot   # NOTE 2026-11-14: this app is missing; reinstall from ~/Downloads/Godot_v4.7.2-stable_mono_macos.universal.zip
$GODOT --path .                                              # play
$GODOT --headless --path . --import                          # after adding scripts or assets
$GODOT --headless --path . res://tests/slice_test.tscn       # end-to-end test, exit code 0 = pass
$GODOT --headless --path . res://tests/menu_test.tscn        # title, options, creation and title/game flow
$GODOT --path . res://tests/screenshot.tscn -- /some/folder  # windowed visual check, writes PNGs
$GODOT --path . res://tests/screenshot_3d.tscn -- /some/folder  # windowed shots of the 3D district
$GODOT --headless --path . -s tools/build_town_mask.gd       # rebuild the town walkable mask from the greybox
$GODOT --headless --path . -s tools/build_town_3d.gd         # then rebuild the 3D town grid (heights, types) from greybox + mask
sh tools/package_review.sh                                   # export/COMETO_review_<date>.zip
$GODOT --path . res://tests/screenshot_time.tscn -- /some/folder  # shots through the day and each weather
$GODOT --path . res://tests/perf_probe.tscn                  # render cost per spot (desktop proxy)
$GODOT --headless --path . --export-debug "iOS" export/ios/COMETO.ipa  # needs iOS templates, Xcode, team id
```

## Layout

- `core/` autoloads: `GameState` (flags, conditions, effects), `Journal`, `Dialogue`, `SaveManager`, `WorldTime` (the only clock and calendar), `Weather`, `Settings`, `Audio` (all sound goes through it; see `audio/README.md` for placeholders). No drawing here.
- `game/` main scene, player, NPCs, `Interactable` component, puzzle pieces.
- `maps/<region>/` one scene per location, root script `GameMap` (2D) or `GameMap3D` (3D), with `Entities` and `Spawns`. 3D maps use `Player3D`, `Npc3D`, `Interactable3D`, `MapExit3D`, which keep the 2D classes' interfaces.
- `ui/` all screen-space controls, built in code from `UiTheme`.
- `data/` narrative content as JSON (dialogue, quests, clues). Formats are documented at the top of `core/dialogue.gd` and `core/game_state.gd`.
- `art_provisional/` everything drawn in code. All of it is placeholder and is meant to be replaced.
- `tests/` headless slice test and screenshot runner.

## Anjabi layout

`docs/reference/anjabi_greybox_01.png` (director's Greybox Study 01) is the canonical town layout; `anjabi_concept_map.png` is the look target. `maps/anjabi/town.tscn` shows the greybox at 2 world px per image px and walks on a mask derived from its colours (`tools/build_town_mask.gd`; check `docs/reference/town_walkable_debug.png` after rebuilding). `maps/anjabi/mine_3d.tscn` is the detailed 3D map of location 04 (stairs from the Estate, exit east to the airpad), built at 20 px = 1 m from the old 2D `mine.tscn`, which is kept for reference but no longer loaded.

## Rules

- Lore comes from the director. Do not invent names, factions or plot. Placeholder text in `data/` uses role names ("Driller", "Gate guard") on purpose.
- Anything that must survive save/load lives in `GameState.flags` or `Journal`; scenes rebuild themselves from that state in `_ready`.
- New interactive things use `Interactable` plus dialogue data, not bespoke UI.
- Base resolution is 480x270, `canvas_items` stretch, `expand` aspect. Lay out UI with anchors, never fixed screen positions.
- Anything time- or weather-dependent listens to `WorldTime` / `Weather` signals; never add another timer or calendar. Map lighting goes through `EnvironmentController`.
- Input actions are registered in `core/input_setup.gd`, not in project settings.
- Keep the slice test passing and extend it when adding a system.
- `PROJECT_LOG.md` is the running project log. After every change: add a dated Changelog entry, and update its file index and limitations so they stay true. New files get a row in the index.
- `sh tools/package_review.sh` builds the review zip in `export/`.
