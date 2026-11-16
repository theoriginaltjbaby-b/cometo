# Anjabi map design: overworld and interiors

Working proposal (2026-11-15). Layout and landmark names come from the director's Greybox
Study 01 (`docs/reference/anjabi_greybox_01.png`); what is inside each building, and who
is there, is for the director. Nothing here adds lore.

## The model: one overworld, many small interiors (Pokemon HeartGold / SoulSilver)

- **Overworld**: the town of Anjabi is one continuous outdoor map (`anjabi_town`) under
  the fixed camera. It holds the paths, levels, landmarks and outdoor people.
- **Interiors**: every enterable building is its own small map, built on
  `InteriorMap3D` (`maps/interior_map_3d.gd`): a cut-away room on black, entered by a
  door on the overworld and left by a mat at its front edge. The first one exists:
  **12 Shop** (`anjabi_shop`).
- **Dungeons**: larger self-contained maps reached from the overworld, like the existing
  mine yard (`anjabi_mine`).
- Interiors are **not to scale** with their exteriors. A small pod can hold a
  comfortable room; a tower can be several floors. That is the convention, and it keeps
  rooms readable at handheld resolution (about 10 x 7 m per room fits one screen).

Door rules (to keep consistent):
1. A door is a `MapExit3D` on the overworld, `prompt = "Enter"`, label = landmark name,
   placed at the threshold. Its spawn in the interior is `default`, just inside.
2. The interior's mat leads to a named spawn on the overworld just outside that door
   (the shop's is `shop`), so the player steps out where they went in.
3. Locked or not-yet-written doors stay `Interactable3D` with a line of narration
   (as Pod B-17 does now) until their interior exists.

## Interiors, by landmark

Proposed breakdown, largest first. "Rooms" are separate screens joined by doors or
stairs inside the interior map. Status: built / door only / proposal.

| Greybox landmark | Interior map | Rooms (proposal) | Status |
|---|---|---|---|
| 08 Main Tavern | `anjabi_tavern` | Ground floor bar and tables; upstairs rooms (2-3 small) | proposal. Note: the keeper's current line says it is full inside; the interior's state is the director's call |
| 12 Shop | `anjabi_shop` | One room, counter at the back | **built** (dressing provisional) |
| Worker Pods (5 pods) | `anjabi_pod` template + `anjabi_pod_b17` | One room each; one shared template for unremarkable pods, a unique B-17 | door only (B-17 knocks) |
| Estate | `anjabi_estate` | Entrance hall; two wings; one upper room. The largest interior in town | proposal |
| Estate Gardens | outdoor (overworld) | - | overworld |
| Tion Tower | `anjabi_tion_tower` | Lobby; lift or stair to 2-3 floors; top floor | proposal |
| Guard Tower | `anjabi_guard_tower` | Guard room; stair; lookout | proposal |
| Tram Station | `anjabi_tram_station` | Hall with platform; the way to other regions (Pokemon-style travel point) | proposal |
| Docks and Boardwalk | `anjabi_dock_store` | One warehouse or harbour office room | proposal |
| Quonset huts / sheds | `anjabi_shed` template | One room each, mostly storage | proposal |
| Private Airpad | outdoor + `anjabi_airpad_office` | Small office | proposal |
| Collapsed Mine | `anjabi_mine` (dungeon) | Yard (built), then mine levels I-IV as dungeon floors | yard built |
| Rainforest Approach / Forest | routes (outdoor) | Paths out of town to other regions | proposal |

Suggested build order: Tavern (story already points there), Pod B-17 (already a door),
Estate, Tion Tower, Tram Station.

## Overworld: spacing and walk paths

What the town needs for HeartGold-style movement: paths at least 3 m wide (3 tiles), a
clear loop through the districts instead of dead ends, open plazas at junctions, and
nothing (props, signs, lamps) standing in a path's line.

What I tried (2026-11-15): scaling the whole town 25% larger from the greybox (0.12 ->
0.15 m per pixel). The generated parts widened as wanted, but the hand-built Steps
plaza and terrace (the detailed insert) stay their own size, so their joins to the
walkways narrowed to about 1 m and the tavern landing became unreachable. Fixing that
means rebuilding the insert's edges, which is the major change we chose to avoid; it
was reverted.

Proposed path to a properly spaced overworld, in order:
1. **Decide the scale** together with the insert: either rebuild the Steps insert at
   the new scale, or retire it and let the generated grid draw the Steps too (simpler,
   one system). Then set PX to about 0.15 and rebuild (`tools/build_town_3d.gd`).
2. **Widen paths in the greybox mask** where they are under 3 m, and open the dead ends
   into loops: the Steps <-> Tion Tower walk, the pods' ravine, the beach stairs.
3. **Keep junctions clear**: dressing (`_dressing()` in `town_3d.gd`) already avoids
   paths for trees; extend the same rule to clutter, flowers and townsfolk routes.
4. **Doors on the overworld**: one per landmark from the table above, each with its
   return spawn, even before its interior exists (narration placeholder).

Main routes once spaced (from the greybox):
- **The Steps (hub)** -> Shop (east), Tavern terrace (north stairs), Tram Station (east,
  down), Docks (east, down), Beach (south, down).
- **Steps -> Tion Tower walk -> Estate** (west, rising), Estate Gardens north of it.
- **Steps -> Pods** (north-west, up the ravine walkway) -> Guard Tower (north-east) and
  the Forest (north-west).
- **Estate -> Mine** (south-west, down the stairs) -> Private Airpad (south).
- **Docks -> Rainforest Approach** (east): the way out of town.
