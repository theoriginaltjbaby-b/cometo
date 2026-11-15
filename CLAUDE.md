# COMETO

2D handheld sci-fi RPG. Godot 4.7, GDScript only, Mobile renderer, iPhone first (landscape).
Separate from the older 3D project in `~/cometographia-2`; nothing is shared.

## Run and test

```bash
GODOT=/Applications/Godot_mono-1.app/Contents/MacOS/Godot
$GODOT --path .                                              # play
$GODOT --headless --path . --import                          # after adding scripts or assets
$GODOT --headless --path . res://tests/slice_test.tscn       # end-to-end test, exit code 0 = pass
$GODOT --path . res://tests/screenshot.tscn -- /some/folder  # windowed visual check, writes PNGs
$GODOT --headless --path . -s tools/build_town_mask.gd       # rebuild the town walkable mask from the greybox
sh tools/package_review.sh                                   # export/COMETO_review_<date>.zip
```

## Layout

- `core/` autoloads: `GameState` (flags, conditions, effects), `Journal`, `Dialogue`, `SaveManager`. No drawing here.
- `game/` main scene, player, NPCs, `Interactable` component, puzzle pieces.
- `maps/<region>/` one scene per location, root script `GameMap`, with `Entities` (y-sorted) and `Spawns`.
- `ui/` all screen-space controls, built in code from `UiTheme`.
- `data/` narrative content as JSON (dialogue, quests, clues). Formats are documented at the top of `core/dialogue.gd` and `core/game_state.gd`.
- `art_provisional/` everything drawn in code. All of it is placeholder and is meant to be replaced.
- `tests/` headless slice test and screenshot runner.

## Anjabi layout

`docs/reference/anjabi_greybox_01.png` (director's Greybox Study 01) is the canonical town layout; `anjabi_concept_map.png` is the look target. `maps/anjabi/town.tscn` shows the greybox at 2 world px per image px and walks on a mask derived from its colours (`tools/build_town_mask.gd`; check `docs/reference/town_walkable_debug.png` after rebuilding). `maps/anjabi/mine.tscn` is the detailed map of location 04 (stairs from the Estate, exit east to the airpad).

## Rules

- Lore comes from the director. Do not invent names, factions or plot. Placeholder text in `data/` uses role names ("Driller", "Gate guard") on purpose.
- Anything that must survive save/load lives in `GameState.flags` or `Journal`; scenes rebuild themselves from that state in `_ready`.
- New interactive things use `Interactable` plus dialogue data, not bespoke UI.
- Base resolution is 480x270, `canvas_items` stretch, `expand` aspect. Lay out UI with anchors, never fixed screen positions.
- Input actions are registered in `core/input_setup.gd`, not in project settings.
- Keep the slice test passing and extend it when adding a system.
- `PROJECT_LOG.md` is the running project log. After every change: add a dated Changelog entry, and update its file index and limitations so they stay true. New files get a row in the index.
- `sh tools/package_review.sh` builds the review zip in `export/`.
