# COMETOGRAPHIA: handoff for a new agent

Read this first. It tells you what the game is, where it stands, how the code is laid
out, how to run and test it, and the rules of working on it. Written 2026-11-15.

Then read, in this order:
1. `CLAUDE.md`: the project's standing instructions (short; binding).
2. `PROJECT_LOG.md`: the running log. Its file index, limitations and changelog
   (entries 1-23) are the full history.
3. `docs/2d_migration_assessment.md`: why the game is becoming 2D and how.
4. `docs/map_design.md`: the overworld and interiors model.
5. `handoff_screens/` (in the handoff zip): what it looks like now.

---

## 1. What it is

**Cometographia** (project name COMETO): a handheld science-fiction CRPG. Design
north star: *Knights of the Old Republic made as a Pokémon FireRed/HeartGold-style
handheld RPG*. That means:
- the narrative depth, player agency and simulation of a PC RPG
- the readability and exploration feel of the GBA/DS Pokémon games
- a mature tone; not a monster-collecting game

Specifics:
- **Engine:** Godot 4.7.2, GDScript only.
- **Platforms:** iPhone-first (landscape); also Mac and web.
- **Setting:** the town of Anjabi, a lived-in settlement in a twilight science-fantasy
  world beneath a giant ringed planet.
- **Look:** a warm, slightly melancholic palette: dusty rose, warm stone, ochre, muted
  teal, verdigris, indigo slate, aged brass, deep violet, warm amber light.
- **Lore comes only from the director (the user).** Never invent names, factions or
  plot. Placeholder text uses role names ("Tavern keeper", "Driller") and is marked
  `[PLACEHOLDER: ...]`.

## 2. Where it stands right now

- **Active branch: `2d`.** The game is being rebuilt as a native 2D, tile-based RPG.
  The first vertical slice is done and approved to build: the Steps plaza plus the shop
  interior.
- **The 3D version is preserved:** tag `3d-final`, branch `3d-conversion`. Its code is
  still present on `2d`, still runs and is still tested. **Do not delete or retire the
  3D code** until the director says so.
- **The director's instruction after the slice:** stop for review before converting
  more areas. Nothing beyond the slice has been requested yet.
- **Live web build:** https://theoriginaltjbaby-b.github.io/cometo-web/ serves the 2D
  slice. It comes from a separate public repo, `theoriginaltjbaby-b/cometo-web`, which
  holds only exported files, no source.

### What exists in the game
**Systems (engine-independent, `core/`):**
- `GameState`: flags plus a condition and effect language.
- `Dialogue`: branching, data-driven.
- `Journal`: quests, objectives, clues.
- `SaveManager`: slots, autosave, versioned JSON.
- `WorldTime` and `WorldCalendar`: 24 h clock, 7-day week, 4 seasons of 28 days,
  signals.
- `Weather`: six types, season-weighted, forecast, overrides.
- `Settings`: volumes, display.
- `Audio`: placeholder lookup and synthesised UI tones.
- `InputSetup`.

**Interface (`ui/`):**
- Title screen (shader planet, ship) with Continue, New Game, Load, Options and Quit.
- Character creation: name, hair, hair colour, skin, coat, coat length. Its preview is
  still the 3D figure.
- Pause menu, journal, HUD prompt chip, quest tracker, clock and weather HUD, compass,
  touch controls (drag to move, tap to interact, RUN toggle), and a calm blue sci-fi
  theme.

**2D slice (`world2d/`, `render2d/`, `data/maps2d/`):**
- FireRed-style grid movement: tap to turn, hold to walk 0.24 s per tile, run 0.13 s
  per tile, bump into walls.
- 16x32 adult sprites and 16 px tiles, with the world rendered at 240 px wide (about 15x8
  tiles) and integer-scaled.
- Depth sorting, overhead layer (arches, eaves).
- The tavern keeper NPC and his dialogue.
- A quest step: asking the way gives the `mine_directions` clue.
- The shop interior via a door warp.
- Day/night tint, lamps, night glow, rain, snow and mist, saves.

**3D game (preserved):**
- The whole town, the mine yard with its cart-and-switch puzzle, and a shop interior.
- HeartGold-style low-res rendering, a cosmic sky with an arrival shot, the settlement
  art kit and a colour grade.

### What does NOT exist yet (in either version)
Stats/attributes, skills and skill checks, progression, equipment and inventory,
factions, reputation, relationships, companions/party, NPC schedules, combat (three
directions were proposed in PROJECT_LOG section 7; none chosen), swoop racing (required;
planned as its own pseudo-3D mode), cinematics and portraits, music and sound assets.
All of these belong in `core/` (simulation) plus `data/`, independent of rendering.

## 3. How to run and test

The Godot binary on the original machine (macOS 13.7.8, no Xcode) is unusual:
```bash
GODOT=/private/tmp/claude-501/godot_std/Godot.app/Contents/MacOS/Godot   # standard 4.7.2 build (temporary location; from ~/Downloads zip)
# templates installed: ~/Library/Application Support/Godot/export_templates/4.7.2.stable (web, macOS)
$GODOT --path .                                          # play (boots to the title; NEW GAME = 2D slice)
$GODOT --headless --path . --import                      # after adding scripts or assets
$GODOT --headless --path . res://tests/slice2d_test.tscn # 2D slice test (34 checks)
$GODOT --headless --path . res://tests/slice_test.tscn   # 3D game test (162 checks)
$GODOT --headless --path . res://tests/menu_test.tscn    # title/menu/creation/flow (42 checks)
$GODOT --path . res://tests/screenshot_slice2d.tscn -- /some/folder   # windowed PNGs of the 2D slice
$GODOT --path . res://tests/perf_probe.tscn              # 3D render cost (vsync off)
$GODOT --headless --path . --export-release "Web" export/web2d/index.html
$GODOT --headless --path . --export-release "macOS" export/mac/COMETO.zip
sh tools/package_review.sh                               # full review zip in export/
python3 tools/bundle_source.py                           # regenerates docs/ALL_SOURCE.txt
```
- Tests print `PASS`/`FAIL` lines and `N checks, M failed`; the exit code is 0 when all
  pass. Run them with a timeout; a hang means a script error.
- **All three suites must pass before you commit.**
- **Publishing the web build:** clone `theoriginaltjbaby-b/cometo-web`, replace its
  contents with `export/web2d/.`, add `.nojekyll`, commit, then
  `git config http.postBuffer 524288000` (the .wasm is about 40 MB) and push. GitHub
  Pages rebuilds in about a minute. The Web preset has threads off, so no special headers
  are needed. **Ask the director before publishing**; it's public.
- **iPhone:** not buildable on that Mac (no Xcode or signing). Phones use the web build.

## 4. Architecture

```
core/            engine-independent autoloads (GameState, Dialogue, Journal, SaveManager,
                 WorldTime, WorldCalendar, Weather, Settings, Audio, InputSetup, Data, ArtStyle)
data/            dialogue/anjabi/*.json, journal/quests.json + clues.json,
                 maps2d/*.json (2D maps + tiles.json catalogue), npcs2d.json
game/            app.gd (root scene: title <-> game), main.gd (owns the map and player,
                 travel, save capture/restore), 3D player/NPC/camera/interactables,
                 the old 2D Interactable (still used by 2D), environment_controller.gd (3D light)
world2d/         2D rebuild: tile_world.gd (TileWorld), grid_actor.gd, grid_player.gd,
                 grid_npc.gd, maps/steps.tscn + shop.tscn
render2d/        pixel_art.gd (PixelArt): the ONLY place names become pictures
maps/            3D maps (town_3d, district insert, mine_3d, interiors/shop), MapBuilder3D,
                 SettlementKit (3D art kit), InteriorMap3D; maps/proto2d/ (shelved baked-2D
                 prototype; its EnvironmentController2D is REUSED by the 2D slice)
ui/              all screen-space UI, built in code from UiTheme; ui/title/ (title, creation)
art/             models (glb, 3D only), shaders (3D + title + grade), baked2d (shelved)
art_provisional/ code-drawn 3D figure, rain (3D and 2D), fog shader
audio/           README.md: placeholder file names (no audio assets yet)
tests/           slice2d_test, slice_test (3D), menu_test, screenshot runners, perf probe
tools/           town grid builders (3D), bake_2d (shelved), bundle_source.py, package_review.sh
docs/            assessment, map design, reference images (greybox = canonical layout,
                 concept map, concept render), ALL_SOURCE.txt
```

### The boot flow
1. `project.godot` sets the main scene to `game/app.tscn`, which shows `TitleScreen`.
2. NEW GAME goes to `CharacterCreation`, then `app._start("new", profile)`. That creates
   `main.tscn` with `start_map = "anjabi_steps"` and calls `main.new_game()`.
3. `new_game()` resets state, calls `load_map()` and starts the `quiet_mine` quest.
4. LOAD and CONTINUE call `main` with `boot = "load:<slot>"`, which runs
   `SaveManager.load_game` and then `main.restore_world`.
5. The pause menu's "Title screen" autosaves and sets the game aside out of the tree;
   CONTINUE puts it back.

### How main hosts maps (`game/main.gd`)
- `MAPS` maps an id to a scene. 2D ids: `anjabi_steps`, `anjabi_steps_shop`.
- `_enter_map` checks the map type:
  - `TileWorld` goes into `view2d` (a SubViewport at native pixel size, `stretch_shrink 2`,
    pixel snapping) with a `GridPlayer`.
  - `GameMap3D` goes into `view3d` (low-res SubViewport plus colour grade) with a
    `Player3D`.
  - `Map2D` is the shelved prototype.
- Travel: anything emits `GameState.travel_requested(map_id, spawn)`, and main loads it.
- Save world data: 2D maps store `{map, x, y, fx, fy}` in pixels; 3D maps store
  `{map, dim:3, x, y, z, fx, fz}`.

### The player interface every player class honours
`target` (an Interactable or null), `facing`, `try_interact()`, `setup(touch, map)`,
`camera`, `sprinting`, `touch`. The HUD reads only these.

### 2D world model (`world2d/tile_world.gd`)
- **Layers** (TileMapLayer, built from the map JSON):
  - `ground` and `build`: solid if the tile name is `solid` in `data/maps2d/tiles.json`.
  - `detail`: windows, doors, vines, awnings; never solid.
  - `over`: drawn above people (eaves, arches).
  - `Glow`: lit windows added again additively at night.
- **Objects** (in the map JSON):
  - `prop`: a sprite with a footprint `size`, solid by default, optional `light`; goes in
    the y-sorted `Entities`.
  - `decor`: a flat sprite, `layer` `under` or `over`.
  - `npc`: an id from `data/npcs2d.json` (name, dialogue, look).
  - `walker`: a look plus a wander `area` (a 1x1 area means it stands still).
  - `warp`: `to` map and `spawn`, triggered by stepping on the tile; an optional `label`
    adds an Enter prompt.
  - `sign`: prompt, label and dialogue, used by facing the tile.
  - `light`.
- **Queries:** `can_enter(tile)`, `is_solid`, `interactable_at`, `warp_at`,
  `claim`/`release` (occupancy), `foot(tile)` (the tile's bottom-centre pixel),
  `tile_of(px)`, `spawn_position`/`spawn_facing`.
- **Movement** (`GridActor`): steps glide between tile feet. Animation frames:
  - sheet columns: idle, walk 1-4, run 1-4
  - rows: down, up, left, right
  - two frames per step, alternating feet
- **Lighting:** `maps/proto2d/environment_controller_2d.gd` extends the 3D
  `EnvironmentController`, so it uses the same gradients and clock. It provides:
  - a CanvasModulate tint
  - PointLight2D lamps
  - a `night_glow` group
  - rain, snow and mist via groups `precipitation` and `fog_overlay`
  - an `indoor` mode

### Art pipeline (2D)
`PixelArt` provides:
- `tile(name)`: a 16x16 image.
- `prop(name)`: a texture standing on its bottom centre.
- `character(look, id)`: a 16x32 sheet with 9 columns and 4 rows.

All of it is generated placeholder art. **To replace any piece, drop a PNG at**
`art/pixel/tiles/<name>.png`, `art/pixel/props/<name>.png` or `art/pixel/chars/<id>.png`.
No code changes are needed. Glow is extracted from bright warm or cyan pixels
automatically.

### Data formats
- Dialogue: documented at the top of `core/dialogue.gd`. Conditions and effects are
  documented at the top of `core/game_state.gd`.
- Quests: `data/journal/quests.json` (objectives, optionally hidden).
- Clues: `data/journal/clues.json`.

## 5. How to do common things (2D)
- **New map:**
  1. Write `data/maps2d/<name>.json`: legend, the 4 layers as equal-length rows,
     objects, spawns, and `indoor`.
  2. Add `world2d/maps/<name>.tscn`: root `TileWorld` with `map_id` and `map_file`, plus
     an `Entities` child with y-sort on.
  3. Register it in `main.gd` `MAPS`.
  4. Connect it with `warp` objects and spawns.
- **New tile or prop name:**
  1. Add a case in `PixelArt._draw_tile` or `_draw_prop` (placeholder), or add a PNG.
  2. If it is solid, add it to `tiles.json`.
- **New NPC:**
  1. Add an entry to `data/npcs2d.json`.
  2. Add a dialogue file in `data/dialogue/`.
  3. Place it with `{"type":"npc","id":...,"at":[x,y],"facing":...}`.
- **Quest progress:** effects in dialogue (`{"objective": "quest.id"}`,
  `{"clue": "id"}`, `{"reveal": ...}`, `{"complete": ...}`).
- **Time and weather hooks:** connect to `WorldTime` and `Weather` signals. Never add
  another clock.

## 6. Rules (from CLAUDE.md, plus how the director works)
- Lore only from the director; placeholders use role names.
- Anything that must survive save/load lives in `GameState.flags` or `Journal`; scenes
  rebuild from that state.
- New interactive things use the Interactable plus dialogue data, not bespoke UI.
- Lay out UI with anchors. The base resolution is 480x270; stretch is `canvas_items`,
  `expand`, with integer scale.
- Input actions are registered in `core/input_setup.gd`.
- Keep tests passing and extend them with every system.
- **After every change, update `PROJECT_LOG.md`:** a dated changelog entry, the file
  index row for each new file, and limitations kept true. Commit with a clear message.
- Don't commit or push unless that is part of the request; the director asks for
  builds, publishing and zips explicitly.
- **Working style the director expects:**
  - Act, don't loop. Don't re-read files you already have.
  - Work in phases and report concisely: what changed, what was verified, what wasn't.
  - Show screenshots of visual work.
  - Be honest about failures; for example, the earlier baked-2D prototype was judged
    "horrible" and shelved.
  - The director makes the big calls (art direction, pivots). Ask before large or
    public actions.

## 7. Known limits and open threads
- All 2D art is placeholder. The final identity should come from real pixel art. The
  director: "avoid allowing placeholder aesthetics to dictate the final visual identity."
- The character-creation preview is still 3D; the 2D sprite does use the chosen colours
  and hair.
- In the 2D slice, the west and east roads end at placeholder signs. The rest of Anjabi
  exists only in 3D, and the 3D maps are not linked from 2D.
- 2D maps are JSON grids for now; Godot TileMap editor authoring is a later step.
- With integer scaling, odd window sizes show dark margins.
- No audio assets yet (see `audio/README.md` for placeholder names).
- Nothing has been measured on an actual iPhone.

## 8. Likely next steps (await the director's go-ahead)
1. Review the slice. Then convert more of Anjabi to 2D from the greybox
   (`docs/reference/anjabi_greybox_01.png`, canonical) and `docs/map_design.md`.
2. Replace the 2D creation preview with the sprite.
3. Start a CRPG core system in `core/` + `data/`: stats and skill checks in dialogue
   conditions, then inventory, factions and reputation, NPC schedules on WorldTime, a
   cutscene runner, and portraits in the dialogue box.
4. Swoop racing as a separate mode scene (pseudo-3D), sharing only core state.
5. Retire the 3D code from `2d` only when the director says so.
