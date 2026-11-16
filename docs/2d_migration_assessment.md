# Cometographia: 2D migration assessment

Prepared 2026-11-15 for review before any conversion work. Nothing has been changed.

## 1. What the project is today

Godot 4.7.2, GDScript only, about 11,600 lines across 81 scripts, 33 commits on the
branch `3d-conversion` (plus `mine-yard-relayout`). The first commit, `38ff398`, is the
original 2D game before the 3D conversion.

| Area | Scripts / lines | What it is |
|---|---|---|
| `core/` | 12 / 1,364 | Autoloads: `GameState` (flags, conditions, effects), `Dialogue`, `Journal`, `SaveManager`, `WorldTime` + `WorldCalendar`, `Weather`, `Settings`, `Audio`, `InputSetup`, `Data`, `ArtStyle` |
| `ui/` | 15 / 1,782 | Title screen, menus, options, character creation, HUD, dialogue box, journal, quest tracker, clock, compass, touch controls, theme |
| `game/` | 17 / 1,811 | App flow (`app.gd`, `main.gd`), 3D player, NPCs, interactables, camera, lighting controller, mine puzzle; and the old 2D versions of player, NPC, interactable, exit and puzzle |
| `maps/` | 16 / 3,326 | 3D town, Steps insert, mine yard, shop interior, the 3D builder and settlement kit; the old 2D map and walk-mask classes; the shelved 2D prototype (`maps/proto2d/`) |
| `art_provisional/` | 6 / 1,040 | Code-drawn figures (3D), rain, 2D character sprite, fog |
| `tests/` | 12 / 1,458 | Slice test (161 checks), menu test (43), screenshot and performance runners |
| `tools/` | 3 / 821 | Town mask and 3D grid builders, the 2D bake tool |
| `data/` | 17 JSON | 15 dialogues, quests, clues |
| `art/` | 15 MB | 24 Blender models (glb), shaders |

## 2. What survives the conversion

### Survives unchanged: the engine-independent core
None of these refer to 3D; they run on data and signals.

- **GameState**: flags, the condition language (`flag`, `eq`, `clue`, `not`, `all`,
  `any`) and effects (`set`, `clue`, `quest`, `reveal`, `objective`, `complete`,
  `notify`, travel requests). This is the foundation for consequences, skill checks
  and reputation.
- **Dialogue**: data-driven branching conversations with conditions and effects, plus
  all 15 dialogue files.
- **Journal**: quests, objectives and clues, plus their data.
- **SaveManager**: slots, autosave, versioning and the save list; the world provides
  `capture_world()` / `restore_world()`.
- **WorldTime, WorldCalendar, Weather**: the clock, seasons, forecast and their signals.
  This is the backbone for NPC schedules and timed events.
- **Settings, Audio** (placeholders), **InputSetup**.

### Survives with small changes: interface and app flow
- Title screen with the planet. It is already 2D, drawn with a shader.
- Main menu, load list, options, pause menu, journal, HUD, quest tracker, clock,
  touch controls and theme. The HUD only asks the player for `target` and
  `try_interact()`, so it doesn't care what renders the world.
- Dialogue box: works as is. Portraits and expressions would be an addition.
- `app.gd` / `main.gd`: boot, new game, load, continue, travel between maps, return
  to title. `main.gd` already switches between 2D and 3D maps.
- Character creation: everything except the 3D preview, which would need to show a
  sprite.

### Reusable as a starting point: existing 2D code
- The original 2D game classes (`Player`, `Npc`, `Interactable`, `MapExit`, `GameMap`,
  `WalkMask`, `CharSprite`, the 2D ore cart and track switch). They are simple but
  share the interfaces the core and UI expect.
- From the shelved prototype:
  - `EnvironmentController2D`: day and night as a tint, lamps as 2D lights, glowing
    windows after dark, and rain, snow and mist. This is directly reusable.
  - `Person2D`: animation from an 8-direction sprite sheet.
  - Rules for walking between heights (cliffs, terraces, stairs).
- **What failed in that prototype was the art** (3D renders shrunk into sprites), not
  the code.

### Design material that carries over
- The director's greybox, which is the canonical town layout.
- The concept map, the concept render and the settlement palette.
- `docs/map_design.md`: the overworld plus interiors model, door rules, and a room plan
  for every landmark. This is written for exactly this kind of game.

### Does not survive: 3D presentation
To be replaced:
- 3D player, NPCs, townsfolk, figures, camera, interactables, exits and puzzle pieces.
- The 3D maps, `MapBuilder3D`, `SettlementKit`.
- The 3D lighting controller, all 3D shaders (ground, sea, sky, stone, inlay, colour
  grade), the 24 Blender models, and the 3D town grid tool.

These stay intact on the 3D branch.

### Doesn't exist yet, in either version
The brief lists these under "preserve". None of them exist in code; only flags,
journal and dialogue conditions do:
- attributes, skills, progression, equipment and inventory
- factions, reputation and relationships
- companions and party interactions
- NPC schedules
- combat (three directions were proposed; none chosen)
- swoop racing
- cinematics and portraits

The conversion doesn't threaten any of them. They are new work in either renderer, and
they belong in the engine-independent core.

### Tests
- **Menu test:** ports almost as is.
- **Slice test:** about a third ports: the dialogue, journal, save/load, time, weather
  and title-flow checks. The rest checks 3D movement and geometry and would be
  rewritten for the 2D maps.

## 3. Proposed 2D architecture

```
core/        engine-independent simulation (exists; grows: stats, skills, inventory,
             factions, reputation, party, schedules)        - no nodes in the world
data/        dialogue, quests, clues (exists) + npcs, items, factions, maps  - JSON
world2d/     tile maps and the things in them:
             TileMapLayers: Ground, Detail, Architecture (solid), Props (y-sorted),
             Overhead (drawn above the player); Entities (y-sorted actors);
             Triggers and Warps (doors); Map2D base class
actors/      Player2D (grid movement), Npc2D (data-driven, schedule hooks),
             Interactable2D, Warp
render2d/    sprite sheets and animation, portraits, lighting (day/night, lamps),
             weather overlays, camera (follow, pan, zoom, shake)
cinematic/   a cutscene runner: data-driven beats (move, face, emote, say, camera pan
             or zoom, fade, light change, full-screen illustration, wait)
modes/       separate scenes with their own rendering and controls:
             overworld, interior, cinematic, swoop racing (pseudo-3D road)
ui/          as now
```

Defaults I'd propose, open to change:
- **Grid:** 16 px tiles.
- **View:** the world drawn at 240x135 and scaled up 2x inside the existing 480x270
  interface. That is roughly 15 by 8 tiles, close to a GBA screen.
- **Characters:** 16x32 px sprites (two tiles tall, adult proportions, not chibi), in
  4 directions with walk and run.
- **Movement:** tile by tile like Pokémon (hold to keep walking, Shift or RUN to run),
  4 directions, with touch drag mapped to the same steps.
- **Collision** from the Architecture layer and a "solid" flag on tiles; doors and
  triggers as tile positions.
- **Depth sorting** by each object's base row, with an Overhead layer for roofs and
  arches the player walks under.
- **Lighting:** the existing 2D controller (tint, lamps, glow, weather), already
  driven by the clock.
- **Maps** authored as Godot scenes in the TileMap editor. Placement of NPCs, doors and
  triggers is data, so quests and NPCs don't depend on art.
- **Swoop racing:** its own scene and renderer (a "Mode 7"-style ground plane shader
  with scaled sprites). It shares only the core (GameState, Journal, saves), so the
  tile system never constrains it.

## 4. Risks and what needs replacing

1. **Art is the critical path.** The last 2D attempt failed on art, not code. Tilesets
   and sprites need a source:
   - tiles I draw in code (fast, rough)
   - a licensed pixel pack (a decent placeholder)
   - an artist (final quality)
   This decision matters more than any technical one.
2. **Authoring.** Long-term, maps should be painted in Godot's TileMap editor rather
   than generated in code. Someone will need the editor; I can build the slice in code
   or from the greybox.
3. **The CRPG systems are new work.** The pivot doesn't remove anything here, but the
   size of that work shouldn't be mistaken for conversion effort.
4. **Saves:** 3D saves store 3D positions. The save version goes up; old saves start a
   new game, or fall back to the start map as they do today.
5. **Tests:** most of the slice test is rewritten for 2D movement and maps.
6. **Lore rule unchanged:** placeholder text keeps using role names.
7. **Phones and web get easier:** 2D is much cheaper to draw than the current 3D.

## 5. Simplest safe migration path

0. **Baseline.** Tag the current state (`3d-final`). Create a new branch, `2d`, from it.
   The `3d-conversion` branch stays untouched and buildable.
1. **Slice first, nothing removed.** In the `2d` branch, add `world2d/`, `actors/` and
   `render2d/` alongside the 3D code. The new map plugs into the existing `main.gd`
   map switch, so the title, menus, saves and HUD work from day one.
2. **Vertical slice: the Steps.** The plaza and one interior (the shop), at the
   greybox's layout:
   - tile-by-tile movement and running
   - collision and depth sorting, with an overhead arch to walk under
   - the tavern keeper (NPC) with the existing dialogue
   - the shop as an enterable interior, entered through a door warp
   - one quest interaction, using the existing quest: reading the notice or talking to
     the keeper updates the journal
   - day/night lighting and weather overlays from the existing controller
   - save/load in 2D
   - a new 2D slice test
3. **Review together.** Then decide on art, more areas, and which CRPG system to build
   first.
4. **Retire the 3D code from the `2d` branch** only after the 2D game covers what it
   did. It stays recoverable on `3d-conversion` and the tag.

## 6. Decisions needed before the slice

1. **Art for the slice:**
   - (a) tiles and sprites I draw in code, in the settlement palette
   - (b) a licensed or CC0 sci-fi pixel pack, which needs your approval to download
   - (c) art you provide
2. **Movement:** strict tile-by-tile (Pokémon), or free movement over tile collision?
3. **Scale:** 16 px tiles, 16x32 characters, a 240x135 view at 2x. OK?
4. **Branching:** a tag plus a `2d` branch, or a separate project folder copy?
