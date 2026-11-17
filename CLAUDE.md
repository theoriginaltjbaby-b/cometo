# COMETO

Branch `2d`: the native 2D tile-based rebuild (PROJECT_LOG entry 23 on). The 3D game is preserved at tag `3d-final` and on branch `3d-conversion`; its code is still present here and still tested. New 2D work goes in `world2d/` (maps and actors), `render2d/` (art provider) and `data/maps2d/` (map data). The Anjabi TileSet library (32 px tiles, PROJECT_LOG entry 25) is in `art/tilesets/anjabi/`, its untouched source art in `art/source/anjabi_v0.1/`; maps painted with it use `TilesetWorld` (`world2d/tileset_world.gd`). The first such map is `anjabi_boardwalk` (`world2d/maps/anjabi_boardwalk.tscn`, entry 27); its builder `tools/build_anjabi_boardwalk.gd` only lays out a first version and must not be re-run over hand edits.

`PROJECT_BIBLE.md` is the full reference: the look, every map, both tile kits, where every needed file is, pipelines, publishing. Keep it current.

Handheld sci-fi CRPG, now a native 2D tile game in the HeartGold style (16 px tiles, 480x270 view, chibi people). Godot 4.7, GDScript only, Mobile renderer, iPhone first (landscape).
The game boots into the title screen (`game/app.tscn`); NEW GAME starts in `coast_village` (`world2d/maps/coast_village.tscn`; set by `start_map` in `game/app.gd`). The description of the 3D game below is kept for the preserved 3D code: its town is `anjabi_town` (`maps/anjabi/town_3d.tscn`). The Steps and tavern terrace are a detailed insert inside the town (`maps/anjabi/district.tscn` with `insert = true`, placed at `INSERT_AT`); the mine yard is `anjabi_mine` (`maps/anjabi/mine_3d.tscn`). Every map is 3D. 3D maps extend `MapBuilder3D` (`maps/map_builder_3d.gd`).
Separate from the older 3D project in `~/cometographia-2`; nothing is shared.

## Run and test

```bash
GODOT=/Applications/Godot_mono-1.app/Contents/MacOS/Godot   # NOTE 2026-11-14: this app is missing; reinstall from ~/Downloads/Godot_v4.7.2-stable_mono_macos.universal.zip. 2026-11-16: a standard 4.7.2 build is at /private/tmp/claude-501/godot_std/Godot.app (temporary) and ~/Public/Godot.app
$GODOT --path .                                              # play
$GODOT --headless --path . --import                          # after adding scripts or assets
$GODOT --headless --path . res://tests/slice_test.tscn       # end-to-end test, exit code 0 = pass
$GODOT --headless --path . res://tests/slice2d_test.tscn     # the 2D vertical slice
$GODOT --path . res://tests/screenshot_slice2d.tscn -- /some/folder  # shots of the 2D slice
$GODOT --headless --path . res://tests/anjabi_tileset_test.tscn  # the Anjabi TileSet library and its test yard
$GODOT --path . res://tests/play_anjabi_tileset.tscn           # walk the tileset test yard (saves untouched)
$GODOT --path . res://tests/screenshot_anjabi_tileset.tscn -- /some/folder  # shots of the test yard
$GODOT --headless --path . res://tests/anjabi_boardwalk_test.tscn  # the Boardwalk and Tram / Subway Station map
$GODOT --path . res://tests/play_anjabi_tileset.tscn -- anjabi_boardwalk  # walk the Boardwalk (saves untouched)
$GODOT --path . res://tests/screenshot_map2d.tscn -- /some/folder anjabi_boardwalk  # shots of any 2D map
$GODOT --headless --path . res://tests/coast_look_test.tscn     # the 16 px coast kit and its look-test map
$GODOT --path . res://tests/play_anjabi_tileset.tscn -- coast_look_test  # walk the look test
python3 tools/coast/build_kit.py . && python3 tools/coast/make_chibi.py . && $GODOT --headless --path . --import && $GODOT --headless --path . -s tools/build_coast_kit.gd  # rebuild the coast kit
python3 tools/anjabi/prepare.py . && $GODOT --headless --path . --import && $GODOT --headless --path . -s tools/build_anjabi_tileset.gd  # rebuild the Anjabi tilesets from art/source (see tools/anjabi/README.md)
$GODOT --headless --path . res://tests/menu_test.tscn        # title, options, creation and title/game flow
$GODOT --path . res://tests/screenshot.tscn -- /some/folder  # windowed visual check, writes PNGs
$GODOT --path . res://tests/screenshot_3d.tscn -- /some/folder  # windowed shots of the 3D district
$GODOT --headless --path . -s tools/build_town_mask.gd       # rebuild the town walkable mask from the greybox
$GODOT --headless --path . -s tools/build_town_3d.gd         # then rebuild the 3D town grid (heights, types) from greybox + mask
sh tools/package_review.sh                                   # export/COMETO_review_<date>.zip
$GODOT --path . res://tests/screenshot_time.tscn -- /some/folder  # shots through the day and each weather
$GODOT --path . res://tools/bake_2d.tscn                       # rebake the 2D prototype art from the 3D district (windowed)
$GODOT --path . res://tests/screenshot_2d.tscn -- /some/folder  # shots of the 2D prototype
$GODOT --path . res://tests/screenshot_interior.tscn -- /some/folder  # shots of the interiors
$GODOT --path . res://tests/screenshot_overhaul.tscn -- /some/folder  # market quarter and arrival shot
$GODOT --path . res://tests/perf_probe.tscn                  # render cost per spot (desktop proxy)
$GODOT --headless --path . --export-debug "iOS" export/ios/COMETO.ipa  # needs iOS templates, Xcode, team id
```

## Layout

- `core/` autoloads: `GameState` (flags, conditions, effects), `Journal`, `Dialogue`, `SaveManager`, `WorldTime` (the only clock and calendar), `Weather`, `Settings`, `Audio` (all sound goes through it; see `audio/README.md` for placeholders). No drawing here.
- `game/` main scene, player, NPCs, `Interactable` component, puzzle pieces.
- `maps/<region>/` one scene per location (interiors in `maps/<region>/interiors/`, on `InteriorMap3D`; plan in `docs/map_design.md`), root script `GameMap` (2D) or `GameMap3D` (3D), with `Entities` and `Spawns`. 3D maps use `Player3D`, `Npc3D`, `Interactable3D`, `MapExit3D`, which keep the 2D classes' interfaces.
- `ui/` all screen-space controls, built in code from `UiTheme`.
- `data/` narrative content as JSON (dialogue, quests, clues). Formats are documented at the top of `core/dialogue.gd` and `core/game_state.gd`.
- `maps/settlement_kit.gd` is the art direction (materials and reusable architecture); build new areas from it.
- `art_provisional/` everything drawn in code. All of it is placeholder and is meant to be replaced.
- `tests/` headless slice test and screenshot runner.

## Anjabi layout

`docs/reference/anjabi_greybox_01.png` (director's Greybox Study 01) is the canonical town layout; `anjabi_concept_map.png` is the look target. For the 2D game the concept map is also the overhead design the first set of maps is made from, and `docs/reference/look_reference_2d_01.png` was first an influence only (entry 26) and since entry 28 is the target look: 16 px tiles, the full 480x270 view, chibi people about 9% of the screen height. The kit cut from it is `art/tilesets/coast/`, its walkable rebuild `coast_look_test`. `coast_village` is a larger map built only from the kit's modular pieces (entry 29; `tools/coast/modules.py`). `maps/anjabi/town.tscn` shows the greybox at 2 world px per image px and walks on a mask derived from its colours (`tools/build_town_mask.gd`; check `docs/reference/town_walkable_debug.png` after rebuilding). `maps/anjabi/mine_3d.tscn` is the detailed 3D map of location 04 (stairs from the Estate, exit east to the airpad), built at 20 px = 1 m from the old 2D `mine.tscn`, which is kept for reference but no longer loaded.

## Rules

- Lore comes from the director. Do not invent names, factions or plot. Placeholder text in `data/` uses role names ("Driller", "Gate guard") on purpose.
- Anything that must survive save/load lives in `GameState.flags` or `Journal`; scenes rebuild themselves from that state in `_ready`.
- New interactive things use `Interactable` plus dialogue data, not bespoke UI.
- Base resolution is 480x270, `canvas_items` stretch, `expand` aspect. Lay out UI with anchors, never fixed screen positions.
- Anything time- or weather-dependent listens to `WorldTime` / `Weather` signals; never add another timer or calendar. Map lighting goes through `EnvironmentController`.
- Input actions are registered in `core/input_setup.gd`, not in project settings.
- Keep the slice test passing and extend it when adding a system.
- `PROJECT_LOG.md` is the running project log. After every change: add a dated Changelog entry, and update its file index and limitations so they stay true. New files get a row in the index. Update `PROJECT_BIBLE.md` when what it describes changes.
- `sh tools/package_review.sh` builds the review zip in `export/`.
