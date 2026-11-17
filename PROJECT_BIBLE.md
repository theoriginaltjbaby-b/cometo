# COMETOGRAPHIA — Project Bible

The single reference for what this project is, where everything lives, and how to work
on it. Written 2026-11-16 (after PROJECT_LOG entry 30). When this and the code
disagree, the code wins; fix this file.

Companion documents:
- `CLAUDE.md` — standing rules for AI contributors (short, binding).
- `HANDOFF.md` — a start-here briefing for a new agent.
- `PROJECT_LOG.md` — the running history: file index (section 3), limitations
  (section 8), and the dated changelog (entries 1–30).
- `docs/map_design.md` — overworld and interiors model.
- `docs/2d_migration_assessment.md` — why the game became 2D.

---

## 1. The game

**Cometographia** (project and repo name COMETO) is a handheld science-fiction CRPG.
North star: *Knights of the Old Republic made as a Pokémon HeartGold/SoulSilver-style
handheld RPG* — PC-RPG narrative depth and player agency, handheld readability and
exploration, a mature tone, no monster collecting.

- **Engine:** Godot 4.7.2, GDScript only, Mobile renderer.
- **Platforms:** iPhone first (landscape), also web and Mac.
- **Setting:** the town of Anjabi, a coastal settlement in a twilight science-fantasy
  world under a giant ringed planet.
- **Lore comes only from the director (the user).** Never invent names, factions or
  plot. Placeholder text uses role names ("Tavern keeper", "Driller") and is marked
  `[PLACEHOLDER: ...]`.

## 2. The look (current direction)

Set by the director on 2026-11-16 (PROJECT_LOG entries 26–29):

- **Target image:** `docs/reference/look_reference_2d_01.png` — a rainy coastal
  village at night, roofs seen from above, warm lamplight on wet stone, chibi people.
  It is now the explicit goal: build in this style until it reads almost 1:1, moving
  like HeartGold/SoulSilver.
- **Scale:** 16 px tiles, the full 480 × 270 view (30 × 17 tiles), people 16 px wide
  and about 25 px tall (~9% of screen height; the director asked for 8–10%).
- **Movement:** FireRed/HeartGold grid stepping — tap to turn, hold to walk (about 4
  tiles/s), hold run (about 8 tiles/s), bump into walls, doors on arrival.
- **Layout source for Anjabi:** `docs/reference/anjabi_concept_map.png` (painted map,
  the overhead design the 2D maps are made from) and
  `docs/reference/anjabi_greybox_01.png` (Greybox Study 01, canonical layout).
- Earlier looks, still in the repo: the 3D HeartGold-style town (tag `3d-final`),
  the 16 px code-drawn Steps slice (entry 23), and the 32 px Anjabi tileset from the
  director's v0.1 sprite sheets (entries 25, 27).

## 3. Where things stand

**Branch `2d`** is active. The 3D game is preserved at tag `3d-final` and on branch
`3d-conversion`; its code is still on `2d`, still runs and is still tested. Do not
delete it until the director says so.

**Source repo:** https://github.com/theoriginaltjbaby-b/cometo (private; remote
`origin`). It holds the `2d` branch (default) and the `3d-final` tag; the local
branches `3d-conversion` and `mine-yard-relayout` were not pushed.

**NEW GAME** starts in **`coast_village`** (title → character creation → village).

**Live web build:** https://theoriginaltjbaby-b.github.io/cometo-web/ — the coast
kit build (site repo `theoriginaltjbaby-b/cometo-web`, commit `1111cd9`; the Steps
slice build is the commit before it).

### Maps (`game/main.gd` → `MAPS`)

| Id | Scene | What it is | Scale |
|---|---|---|---|
| `coast_village` | `world2d/maps/coast_village.tscn` | **Start map.** 48 × 30 village built only from the coast kit's modular pieces: seven houses, four streets, pine forest, beach, pier. North lane → `coast_look_test`. | 16 px |
| `coast_look_test` | `world2d/maps/coast_look_test.tscn` | The look reference rebuilt from the coast kit, walkable (93.5% pixel match). North lane → `coast_village`. | 16 px |
| `anjabi_boardwalk` | `world2d/maps/anjabi_boardwalk.tscn` | Boardwalk and Tram / Subway Station from the concept map; exits are placeholder signs. Not reachable from the village. | 32 px |
| `anjabi_tileset_test` | `world2d/maps/Anjabi_Tileset_Test.tscn` | Test yard for the 32 px Anjabi TileSet library. | 32 px |
| `anjabi_steps`, `anjabi_steps_shop` | `world2d/maps/steps.tscn`, `shop.tscn` | The first 2D vertical slice (code-drawn art, JSON maps): Steps plaza, tavern keeper, shop interior, quest step. | 16 px, half view |
| `anjabi_town`, `anjabi_mine`, `anjabi_shop` | `maps/anjabi/*_3d.tscn`, `interiors/shop.tscn` | The preserved 3D game. | 3D |
| `anjabi_steps_2d` | `maps/anjabi/steps_2d.tscn` | Shelved baked-2D prototype. | — |

### What exists
- **Systems (`core/`):** flags/conditions/effects, branching dialogue, journal (quests,
  clues), saves (slots, autosave, versioned JSON), clock and calendar, weather (six
  types), settings, audio placeholders, input setup.
- **Interface (`ui/`):** title screen, character creation, pause menu, journal, HUD
  prompt chip, quest tracker, clock/weather HUD, compass, touch controls.
- **2D world (`world2d/`):** grid actors, player, NPCs and walkers, two world types
  (JSON-built `TileWorld`, TileMapLayer-painted `TilesetWorld`), depth sorting, doors
  and warps, signs, day/night tint, lamps, night glow, rain/snow/mist.

### What does not exist yet
Stats, skills, skill checks, progression, inventory, factions, reputation, companions,
NPC schedules, combat, swoop racing, cinematics, portraits, music and sound. Anjabi
itself in the target look (towers, pods, tram, cliffs, boardwalk levels). People other
than the player in the coast maps. Interiors in the coast style.

## 4. Running, testing, building

```bash
GODOT=/private/tmp/claude-501/godot_std/Godot.app/Contents/MacOS/Godot   # temporary standard 4.7.2 build
# also present: ~/Public/Godot.app; the zip is ~/Downloads/Godot_v4.7.2-stable_mono_macos.universal.zip
# export templates: ~/Library/Application Support/Godot/export_templates/4.7.2.stable (web, macOS)
```

| Task | Command |
|---|---|
| Play from the title | `$GODOT --path .` |
| Play one map, saves untouched | `$GODOT --path . res://tests/play_anjabi_tileset.tscn -- coast_village` (any map id) |
| Reimport after adding assets | `$GODOT --headless --path . --import` |
| Screenshots of any 2D map | `$GODOT --path . res://tests/screenshot_map2d.tscn -- /folder coast_village [x,y ...]` |
| Web export | `$GODOT --headless --path . --export-release "Web" export/web2d/index.html` |
| Serve the web export locally | `python3 -m http.server 8062 --directory export/web2d` (also `.claude/launch.json` → "web2d-build") |
| Review zip | `sh tools/package_review.sh` |
| Regenerate the source bundle | `python3 tools/bundle_source.py` |

### Tests (headless; exit code 0 = pass; run with a timeout, a hang means a script error)

| Suite | Checks | Covers |
|---|---|---|
| `tests/coast_look_test.tscn` | 38 | coast TileSets, chibi player size, stepping and running, reachability, collisions, modular pieces, village, camera follow, the warps between the two coast maps |
| `tests/anjabi_boardwalk_test.tscn` | 33 | Boardwalk map |
| `tests/anjabi_tileset_test.tscn` | 67 | 32 px Anjabi library and test yard |
| `tests/slice2d_test.tscn` | 34 | Steps slice. "a tap turns in place" fails about half the time headless (also on commit 6d77825) |
| `tests/slice_test.tscn` | 162 | 3D game |
| `tests/menu_test.tscn` | 42 | title, options, creation, title/game flow |

All suites must pass before a commit (allowing the known flaky check).

### Publishing the web build (public: ask the director first)
1. Export to `export/web2d/` and check it in a browser.
2. Clone `theoriginaltjbaby-b/cometo-web`, replace its files with `export/web2d/*`,
   keep `.nojekyll`.
3. Commit with the repo's existing author identity, `git config http.postBuffer
   524288000` (the .wasm is ~40 MB), push.
4. GitHub Pages rebuilds in about a minute; check
   `gh api repos/theoriginaltjbaby-b/cometo-web/pages/builds/latest` and compare the
   live `index.pck` size with the export.

## 5. Architecture

```
game/app.gd         title <-> game; NEW GAME start map is `start_map` ("coast_village")
game/main.gd        owns the current map and player; MAPS; travel; save capture/restore
                    2D maps go into `view2d` (a SubViewport, integer-scaled, pixel-snapped)
core/               engine-independent autoloads (no drawing)
world2d/            2D world: TileWorld, TilesetWorld, GridActor/Player/Npc, maps/
render2d/pixel_art.gd   names -> pictures for the code-drawn art; PNG overrides
ui/                 all screen-space UI, built in code from UiTheme
data/               dialogue, journal, 2D JSON maps, npcs2d.json
art/                tilesets, pixel overrides, source art, 3D models and shaders
tools/              art pipelines and map builders (not exported)
tests/              test suites, screenshot runners, launchers (not exported)
docs/               references, screenshots, design notes (ignored by Godot)
```

### Two kinds of 2D world
- **`TileWorld`** (`world2d/tile_world.gd`): built at run time from a JSON map in
  `data/maps2d/` with art from `PixelArt`. Used by the Steps slice. 16 px tiles in a
  240 px view (`stretch_shrink 2`).
- **`TilesetWorld`** (`world2d/tileset_world.gd`, extends `TileWorld`): a normal Godot
  scene of TileMapLayers painted with TileSets. Used by every map since entry 25.
  - Cell size comes from the Ground layer's TileSet (16 or 32); people are scaled 1× or
    2× to match; the view is the full 480 × 270.
  - Collision and lamps come from tile **custom data**: `solid_cells` (Array of
    Vector2i, x right and y **up** from the tile's own cell) and `lamp` (px above the
    foot). Also `name`, `flat`, `flag`. Each TileSet has a matching physics layer.
  - A multi-cell object is one atlas tile **placed by the bottom-left cell** of its
    picture; its y-sort origin is its foot line.
  - Layers: `Ground`, then flat layers (`Edges`, `Terrain`, `Piers`…), then `Entities`
    (y-sorted) holding the object layers and the people.
  - `Signs` node: one child per usable tile — an `Interactable`, or a `Marker2D` with
    meta `prompt`, `label`, `dialogue`, and/or `to` + `spawn` (stepping on it travels).
  - `Spawns`: `Marker2D` per spawn at the tile foot, meta `facing`.
  - `player_sheet` export: the character sheet the player wears on that map.
  - Run the scene alone (F6) and it brings its own player.

### Shared conventions
- Travel: anything emits `GameState.travel_requested(map_id, spawn)`; main loads it.
- Character sheets: 9 columns (idle, walk 1–4, run 1–4) × 4 rows (down, up, left,
  right) of 16 × 32 frames, feet on the bottom row. Any PNG at
  `art/pixel/chars/<id>.png` overrides `PixelArt.character(look, id)`.
- Lighting: `EnvironmentController2D` (`maps/proto2d/`) — CanvasModulate tint, lamps,
  the `night_glow` group, precipitation and fog groups, `indoor` mode. Driven only by
  `WorldTime` and `Weather` signals.
- Saves store 2D position in pixels `{map, x, y, fx, fy}`.

## 6. The tile kits

### Coast kit — the current look (16 px)
- **Where:** `art/tilesets/coast/`
  - `Coast_Ground.tres` (forest floor, road, sand, dock, water; 4 variants each;
    forest floor and water are solid)
  - `Coast_Edges.tres` (kerbs, surf), `Coast_Terrain.tres` (sea pieces, pier,
    puddles, glints), `Coast_Nature.tres` (pines ×3, rocks, rose bed, pine stands,
    driftwood), `Coast_Buildings.tres` (nine-piece red and slate roofs, walls, the
    look test's whole houses and shop), `Coast_Details.tres` (porches, windows,
    planters, roof units), `Coast_Props.tres` (lamp posts, fences, sea wall,
    generator, machines)
  - `coast_*.png` atlases, `coast_tiles.json` (catalogue), `coast_maps.json` (both
    maps), `<map>_glow.png` (night glow per map)
- **Source:** the look reference itself, resampled to one sample per art pixel (it is
  517 × 285 art pixels), so every tile is true pixel art at the picture's resolution.
  Pines and edge tiles are drawn in code in colours sampled from it.
- **Pipeline:**
  ```bash
  python3 tools/coast/build_kit.py . [preview_folder]   # ground, cut objects, modules, maps, glow
  python3 tools/coast/make_chibi.py .                   # the player sheet
  $GODOT --headless --path . --import
  $GODOT --headless --path . -s tools/build_coast_kit.gd   # TileSets + both scenes (overwrites)
  ```
  - `tools/coast/logical.py` — resample a generated "pixel art" image to its grid.
  - `tools/coast/build_kit.py` — the look test's objects (boxes and masks), decals,
    the village layout (`village()`), rendering previews, the glow images.
  - `tools/coast/modules.py` — the modular pieces.
  - `tools/coast/make_chibi.py` — `art/pixel/chars/chibi_raincoat.png`.
- **Building a house** from modules (see `village()` in `build_kit.py`): roof rows of
  `roof_<red|slate>_<tl t tr / l c0–c3 r / bl b br>`, then one row of `wall_end_l`,
  `wall_plain`…, `wall_end_r` (two cells tall), then `porch_<roof>` centred over the
  wall, windows and planters on plain cells. Odd widths keep the porch centred.
- **Limits:** one house style, rectangular roofs only, grid-stepped shoreline, no
  cliffs, stairs, bridges or interiors.

### Anjabi library — v0.1 (32 px)
- **Where:** `art/tilesets/anjabi/` — six TileSets (`Anjabi_Ground`, `_Terrain`,
  `_Nature`, `_Architecture`, `_Industrial`, `_Props`), 200 tiles. 17 tiles carry a
  cleanup `flag` (listed in PROJECT_LOG entry 25).
- **Source (never edited):** `art/source/anjabi_v0.1/` — the director's four ground
  textures and three sprite sheets.
- **Pipeline:** `tools/anjabi/` (`manifest.py` lists every sprite; `prepare.py`;
  `components.py` finds sprite boxes) → `tools/build_anjabi_tileset.gd`. Maps are
  painted with `tools/anjabi_painter.gd` (`AnjabiPainter`); the Boardwalk's builder is
  `tools/build_anjabi_boardwalk.gd` (refuses to overwrite without `-- --force`).
  See `tools/anjabi/README.md`.
- Different scale and drawing style from the coast kit; not used by the start map.

### Code-drawn art (16 px, Steps slice)
`render2d/pixel_art.gd` draws tiles, props and character sheets. Drop a PNG at
`art/pixel/tiles/<name>.png`, `art/pixel/props/<name>.png` or
`art/pixel/chars/<id>.png` to replace any of them.

## 7. File locations, by need

| I need… | It is in |
|---|---|
| The look target | `docs/reference/look_reference_2d_01.png` |
| The town layout | `docs/reference/anjabi_greybox_01.png` (canonical), `anjabi_concept_map.png` |
| Screenshots of each pass | `docs/screens/<pass>/` (e.g. `coast_village_v1/`, `coast_look_v1/`) |
| Where NEW GAME starts | `game/app.gd` → `start_map` |
| The list of maps | `game/main.gd` → `MAPS` |
| The player sheet | `art/pixel/chars/chibi_raincoat.png` (drawn by `tools/coast/make_chibi.py`) |
| The coast maps' layout | `tools/coast/build_kit.py` (`OBJECTS`, `GROUND_RECTS`, `village()`) → `art/tilesets/coast/coast_maps.json` |
| Dialogue | `data/dialogue/anjabi/*.json` (format: top of `core/dialogue.gd`) |
| Quests and clues | `data/journal/quests.json`, `clues.json` (effects: top of `core/game_state.gd`) |
| NPCs (2D) | `data/npcs2d.json` |
| Input actions | `core/input_setup.gd` |
| UI colours and fonts | `ui/ui_theme.gd` |
| Day/night and weather | `core/world_time_manager.gd`, `core/weather_manager.gd`, `maps/proto2d/environment_controller_2d.gd` |
| Export settings | `export_presets.cfg` (Web: threads off; `tools/`, `tests/`, `docs/`, `art/source/` excluded) |
| Builds | `export/` (git-ignored): `web2d/`, `web/`, zips |
| The source on GitHub | https://github.com/theoriginaltjbaby-b/cometo (private, branch `2d`) |
| Every file and its purpose | `PROJECT_LOG.md` section 3 |
| All source in one file | `docs/ALL_SOURCE.txt` (`python3 tools/bundle_source.py`) |

## 8. Rules of work

- Lore only from the director. Placeholders use role names.
- State that must survive save/load lives in `GameState.flags` or `Journal`; scenes
  rebuild from it in `_ready`.
- New interactive things: `Interactable` plus dialogue data, not bespoke UI.
- UI uses anchors; base 480 × 270, `canvas_items` stretch, `expand` aspect, integer
  scale.
- Anything time- or weather-dependent listens to `WorldTime` / `Weather`. No other
  clocks.
- Input actions only in `core/input_setup.gd`.
- Keep tests passing; extend them with every system.
- After every change: a dated `PROJECT_LOG.md` entry, file index rows for new files,
  limitations kept true. Keep this bible current.
- Ask before public or hard-to-undo actions (publishing, pushing). The director asks
  for commits, builds and zips explicitly.
- Reference images: go by the director's latest words about each one. The coastal look
  reference is the target; the concept map and greybox are layout sources.
- Working style: act, report concisely (what changed, what was verified, what was not),
  show screenshots of visual work, be plain about failures.

## 9. Known limits

- The coast kit holds one village style; Anjabi in that style needs its own pieces.
- The journal opens "The Closed Mine" on a new game, though the village has nothing of
  it.
- Character creation previews the 3D figure; its choices do not change the chibi.
- The Steps slice, tileset yard and Boardwalk are in the build but not reachable from
  the village. The 16 px slice, the 32 px Anjabi maps and the coast maps are three
  separate scales and styles.
- No other people in the coast maps; no interiors in the coast style.
- No audio assets. Nothing measured on a real iPhone. No iOS build on this Mac (no
  Xcode, no signing).
- The Godot binary in use lives in a temporary folder.

## 10. Likely next steps (await the director's go-ahead)

1. Anjabi's own pieces in the coast style: the settlement's buildings (towers, pods,
   tavern, shop, station), cliffs and stairs, the boardwalk and tram — then remake the
   Boardwalk and Steps from the concept map at 16 px.
2. More village variety: gables and L-shaped roofs, more doors, windows and wall
   colours, interiors.
3. People: chibi townsfolk sheets and NPCs placed in the coast maps; the creation
   screen showing the chibi and changing its colours.
4. Retire or relink the older 2D maps once the new scale replaces them.
5. CRPG systems in `core/` + `data/`: stats and skill checks, inventory, factions,
   schedules, cutscenes, portraits.
