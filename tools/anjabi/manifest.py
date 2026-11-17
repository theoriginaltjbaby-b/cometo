"""What is in the Anjabi source art and how each piece becomes a tile.

GROUNDS: (name, size of one art pixel in source pixels, palette size)
GROUND_SWATCHES, GROUND_PLACEHOLDERS: see below
SPRITES: (name, category, atlas, source box [x0, y0, x1, y1], options)

A sprite is every connected blob whose centre lies in its box, scaled by 0.5 (a
length a little over whole cells is shrunk to fit, never below 0.44), padded to whole
32 px cells, bottom-aligned and centred. Options:
  size=(w, h)   exact output pixels (may stretch a few percent to land on the grid)
  fit_w=n       scale evenly so the width is n cells
  flat=True     lies on the floor: walkable, drawn under people
  solid=(w, h)  solid cells, centred at the bottom (default: full width, 1 row)
  solid=None    stands in the scene but does not block (hanging things)
  cells=[...]   exact solid cells as (column, row up from the bottom)
  lamp=h        casts lamplight from h px above its foot
  hwrap=True    make the sprite repeat left-right (min-cut seam)
  inset=n       trim n source px off both sides before scaling
  flag="..."    needs manual cleanup; reported by the builder
"""

ATLASES = {
    "N": "atlas_nature_terrain.png",
    "E": "atlas_exterior_industrial.png",
    "I": "atlas_interior_props.png",
}

GROUNDS = [
    ("concrete", 8.8, 10),
    ("grass", 12.28, 10),
    ("red_dirt", 6.05, 14),
    ("metal", 5.9, 10),
]

# Ground cut from a small swatch on a sprite sheet instead of a full texture:
# (name, atlas, source box, scale, palette size). The swatch's frame is trimmed off.
GROUND_SWATCHES = [
    ("wood_deck", "I", [17, 717, 130, 835], 0.678, 14),
]

# Ground the art does not supply at all, drawn by prepare.py as a plain stand-in.
# (name, solid, note)
GROUND_PLACEHOLDERS = [
    ("water", True, "placeholder drawn in code: no water art was supplied"),
]

P2 = {"size": (64, 64), "flat": True}          # a 2 x 2 ground patch
F1 = {"size": (32, 32), "flat": True}          # a 1 x 1 floor panel
BUSH = {"size": (64, 64), "solid": (2, 2)}     # a 2 x 2 block of undergrowth
WALL = "prefab modules have their own end caps; they abut as separate units, not one continuous wall"
ISO = "drawn at a diagonal (isometric) angle that does not match the front-on buildings"

SPRITES = [
    # ---- terrain: patches, paths, water, cliffs, stairs, floors ----
    ("dirt_rocks_a", "terrain", "N", [24, 48, 176, 193], P2),
    ("dirt_rocks_b", "terrain", "N", [198, 47, 345, 194], P2),
    ("dirt_cracked", "terrain", "N", [366, 47, 513, 193], P2),
    ("mud_tracks", "terrain", "N", [532, 47, 679, 194], P2),
    ("puddle_large", "terrain", "N", [698, 47, 849, 194], P2),
    ("puddle_small", "terrain", "N", [867, 47, 1017, 194], P2),
    ("dirt_wet", "terrain", "N", [1037, 47, 1185, 194], P2),
    ("furrows", "terrain", "N", [1204, 47, 1352, 195], P2),
    ("paving_a", "terrain", "N", [26, 241, 175, 388], P2),
    ("paving_b", "terrain", "N", [199, 242, 346, 387], P2),
    ("paving_c", "terrain", "N", [365, 240, 512, 386], P2),
    ("grass_ledge", "terrain", "N", [532, 241, 681, 389], {"size": (64, 64), "solid": (2, 2)}),
    ("cliff_face", "terrain", "N", [698, 240, 853, 389], {"size": (64, 64), "solid": (2, 2), "hwrap": True, "inset": 14}),
    ("cliff_overhang_a", "terrain", "N", [872, 240, 1016, 389], {"size": (64, 64), "solid": (2, 2), "flag": "irregular overhang shape; does not join the cliff face"}),
    ("cliff_overhang_b", "terrain", "N", [1040, 241, 1183, 389], {"size": (64, 64), "solid": (2, 2), "flag": "irregular overhang shape; does not join the cliff face"}),
    ("stairs_stone", "terrain", "N", [1204, 240, 1353, 389], P2),
    ("stairs_diagonal", "terrain", "N", [1371, 240, 1518, 387], {"size": (64, 64), "flat": True, "flag": ISO}),
    ("leaf_litter", "terrain", "N", [24, 433, 177, 578], P2),
    ("roots", "terrain", "N", [198, 433, 346, 579], P2),
    ("plank_bridge_a", "terrain", "N", [1197, 636, 1357, 767], {"flat": True}),
    ("plank_bridge_b", "terrain", "N", [1371, 624, 1519, 767], {"flat": True, "flag": ISO}),
    ("concrete_steps", "terrain", "E", [940, 885, 1114, 993], {"flat": True}),
    ("rope_bridge", "terrain", "E", [1135, 881, 1407, 1002], {"flat": True}),
    ("floor_plate", "terrain", "I", [847, 36, 922, 114], F1),
    ("floor_grate", "terrain", "I", [930, 36, 1003, 114], F1),
    ("floor_planks", "terrain", "I", [1011, 36, 1086, 114], F1),
    ("floor_plate_wet", "terrain", "I", [847, 123, 922, 204], F1),
    ("floor_dirt", "terrain", "I", [930, 123, 1003, 204], F1),
    ("floor_moss", "terrain", "I", [1011, 123, 1085, 204], F1),
    ("planks_wet", "terrain", "I", [17, 717, 130, 835], P2),
    ("planks_mossy", "terrain", "I", [138, 716, 246, 835], P2),
    ("planks_worn", "terrain", "I", [254, 717, 368, 835], P2),

    # ---- nature: trees, undergrowth, glowing plants ----
    ("crop_rows", "nature", "N", [1370, 47, 1515, 194], P2),
    ("undergrowth_glow", "nature", "N", [366, 435, 512, 578], BUSH),
    ("broadleaf", "nature", "N", [529, 434, 682, 577], BUSH),
    ("fern", "nature", "N", [697, 437, 851, 576], BUSH),
    ("heliconia", "nature", "N", [868, 436, 1019, 578], BUSH),
    ("mushroom_grotto", "nature", "N", [1038, 436, 1186, 577], BUSH),
    ("lily_bush", "nature", "N", [1206, 435, 1350, 578], BUSH),
    ("ginger_red", "nature", "N", [1369, 433, 1517, 577], BUSH),
    ("tree_vines_a", "nature", "N", [15, 795, 217, 983], {"solid": (2, 1)}),
    ("tree_canopy", "nature", "N", [225, 797, 422, 989], {"solid": (2, 1)}),
    ("tree_vines_b", "nature", "N", [442, 797, 640, 989], {"solid": (2, 1)}),
    ("giant_tree_base", "nature", "N", [640, 797, 886, 989], {"solid": (4, 2), "flag": "the trunk is cut off flat at the top; it needs a crown or to stand at the map edge"}),
    ("glowplant_teal", "nature", "N", [905, 850, 1045, 989], {"size": (64, 64), "lamp": 24}),
    ("mushrooms_blue", "nature", "N", [1063, 854, 1210, 984], {"fit_w": 2, "lamp": 20}),

    # ---- architecture: prefab modules, roofs, station buildings, interiors ----
    ("wall_window_wide", "architecture", "E", [15, 41, 232, 215], {"size": (96, 84), "solid": (3, 2), "flag": WALL}),
    ("wall_plain", "architecture", "E", [244, 48, 366, 212], {"size": (64, 84), "solid": (2, 2)}),
    ("wall_pipes", "architecture", "E", [380, 47, 511, 215], {"size": (64, 84), "solid": (2, 2)}),
    ("wall_door", "architecture", "E", [526, 47, 661, 215], {"size": (64, 84), "solid": (2, 2)}),
    ("wall_window_small", "architecture", "E", [674, 49, 769, 213], {"size": (48, 84), "solid": (2, 2), "flag": "1.5 cells wide: leaves a gap when chained with other modules"}),
    ("wall_end_a", "architecture", "E", [787, 48, 837, 214], {"size": (25, 84), "solid": (1, 2)}),
    ("wall_end_b", "architecture", "E", [857, 47, 899, 216], {"size": (21, 84), "solid": (1, 2)}),
    ("wall_end_c", "architecture", "E", [919, 48, 985, 220], {"size": (32, 84), "solid": (1, 2)}),
    ("roof_slab_ac", "architecture", "E", [1001, 18, 1225, 211], {"solid": (4, 2), "flag": ISO}),
    ("roof_ac_unit", "architecture", "E", [1236, 58, 1376, 169], {"solid": (2, 1), "flag": ISO}),
    ("roof_corner", "architecture", "E", [1392, 60, 1521, 213], {"solid": (2, 2), "flag": ISO}),
    ("station_building", "architecture", "E", [14, 252, 511, 449], {"fit_w": 8, "solid": (8, 3)}),
    ("ticket_booth", "architecture", "E", [640, 269, 812, 444], {"solid": (3, 2)}),
    ("platform_canopy", "architecture", "E", [828, 262, 1121, 444], {"solid": (5, 2), "flag": "one sprite, so people cannot walk under the roof; needs splitting into posts and an overhead layer"}),
    ("stairwell_down", "architecture", "E", [1310, 291, 1524, 442], {"solid": (4, 2), "flag": ISO}),
    ("awning_rust", "architecture", "E", [750, 892, 920, 990], {"solid": None}),
    ("drain_pipe", "architecture", "E", [661, 888, 723, 1006], {"solid": None}),
    ("vent_grille", "architecture", "E", [259, 917, 314, 967], {"solid": None}),
    ("iwall_lamp", "architecture", "I", [13, 22, 170, 211], {"size": (64, 96), "solid": (2, 2)}),
    ("iwall_vent", "architecture", "I", [185, 22, 316, 211], {"size": (64, 96), "solid": (2, 2)}),
    ("iwall_pipes", "architecture", "I", [334, 25, 455, 211], {"size": (64, 96), "solid": (2, 2)}),
    ("idoor_bulkhead", "architecture", "I", [469, 35, 640, 211], {"size": (96, 96), "solid": (3, 2)}),
    ("idoor_open", "architecture", "I", [658, 35, 828, 211], {"size": (96, 96), "cells": [(0, 0), (2, 0), (0, 1), (2, 1)]}),
    ("window_jungle", "architecture", "I", [1271, 17, 1527, 213], {"size": (128, 96), "solid": (4, 2)}),

    # ---- industrial: railway, mine, machinery, walkways ----
    ("guideway_long", "industrial", "E", [11, 514, 342, 635], {"fit_w": 5, "solid": (5, 1)}),
    ("guideway_short", "industrial", "E", [358, 528, 544, 635], {"fit_w": 3, "solid": (3, 1)}),
    ("guideway_curve", "industrial", "E", [557, 496, 725, 655], {"solid": (3, 2), "flag": ISO}),
    ("guideway_stub", "industrial", "E", [735, 526, 843, 633], {"fit_w": 2, "solid": (2, 1)}),
    ("pillar_large", "industrial", "E", [853, 474, 980, 652], {"solid": (2, 1)}),
    ("pillar_slim", "industrial", "E", [1001, 502, 1070, 650], {"fit_w": 1, "solid": (1, 1)}),
    ("pillar_bracket", "industrial", "E", [1099, 495, 1178, 650], {"solid": (2, 1)}),
    ("train", "industrial", "E", [1193, 481, 1517, 650], {"fit_w": 5, "solid": (5, 2), "flag": "three-quarter view; the track pieces are side-on, so it does not sit on them convincingly"}),
    ("mine_entrance", "industrial", "E", [11, 663, 342, 861], {"fit_w": 5, "solid": (5, 2)}),
    ("pipes_valve", "industrial", "E", [353, 704, 563, 833], {"fit_w": 3, "solid": (3, 1)}),
    ("duct_elbow", "industrial", "E", [577, 708, 705, 837], {"solid": (2, 1)}),
    ("tanks", "industrial", "E", [898, 707, 1004, 833], {"solid": (2, 1)}),
    ("fence_panel", "industrial", "E", [1142, 724, 1264, 832], {"fit_w": 2, "solid": (2, 1)}),
    ("fence_gate", "industrial", "E", [1274, 724, 1370, 832], {"size": (64, 57), "solid": (2, 1), "flag": "stretched a third wider to match the fence panel"}),
    ("ac_unit", "industrial", "E", [27, 894, 125, 995], {"solid": (2, 1)}),
    ("vent_box", "industrial", "E", [156, 897, 232, 990], {"solid": (1, 1)}),
    ("junction_box", "industrial", "E", [342, 908, 430, 990], {"solid": (2, 1)}),
    ("rope_fence", "industrial", "E", [464, 889, 640, 980], {"solid": (3, 1)}),
    ("utility_pole", "industrial", "N", [1244, 788, 1352, 986], {"solid": (1, 1)}),
    ("walkway_lamps", "industrial", "N", [19, 638, 159, 746], {"fit_w": 2, "flat": True}),
    ("walkway_plain", "industrial", "N", [178, 654, 309, 737], {"fit_w": 2, "flat": True}),
    ("walkway_corner", "industrial", "N", [333, 630, 447, 754], {"flat": True, "flag": "walkway pieces are different widths and do not join on the grid"}),
    ("walkway_tee", "industrial", "N", [472, 635, 617, 757], {"flat": True}),
    ("walkway_cross", "industrial", "N", [637, 604, 797, 765], {"flat": True}),
    ("walkway_trestle", "industrial", "N", [817, 625, 987, 766], {"solid": (3, 1)}),
    ("walkway_viaduct", "industrial", "N", [1007, 620, 1176, 765], {"solid": (3, 1)}),
    ("conduit_corner_a", "industrial", "I", [1103, 31, 1169, 101], F1),
    ("conduit_corner_b", "industrial", "I", [1184, 33, 1251, 102], F1),
    ("conduit_cross", "industrial", "I", [1103, 121, 1172, 202], F1),
    ("conduit_tee", "industrial", "I", [1184, 129, 1256, 203], F1),
    ("wall_fan_unit", "industrial", "I", [1094, 871, 1187, 1008], {"solid": (2, 1)}),
    ("control_panel", "industrial", "I", [1227, 894, 1273, 985], {"solid": None}),
    ("switch_panel", "industrial", "I", [1289, 903, 1328, 974], {"solid": None}),
    ("tool_board", "industrial", "I", [1359, 875, 1510, 1010], {"solid": (3, 1)}),
    ("turnstiles", "industrial", "I", [342, 523, 551, 656], {"solid": (4, 1), "flag": "gates are solid; passing through needs the sprite split and a gate script"}),

    # ---- props: lamps, crates, terminals, signs, furniture ----
    ("flood_lamp", "props", "N", [1397, 817, 1492, 986], {"solid": (1, 1), "lamp": 72}),
    ("street_lamp", "props", "E", [1383, 672, 1460, 832], {"solid": (1, 1), "lamp": 66}),
    ("bollard_lamp", "props", "E", [1462, 745, 1504, 832], {"solid": (1, 1), "lamp": 28}),
    ("lamp_teal", "props", "E", [1431, 877, 1499, 991], {"solid": (1, 1), "lamp": 36}),
    ("floor_lamp", "props", "I", [795, 861, 864, 1019], {"solid": (1, 1), "lamp": 62}),
    ("lantern_paper_a", "props", "I", [1310, 692, 1368, 851], {"solid": None, "lamp": 44}),
    ("lantern_paper_b", "props", "I", [1387, 692, 1446, 830], {"solid": None, "lamp": 40}),
    ("lantern_paper_c", "props", "I", [1467, 692, 1521, 833], {"solid": None, "lamp": 40}),
    ("crate_stack", "props", "E", [722, 719, 878, 842], {"solid": (3, 1)}),
    ("jerrycan_crate", "props", "E", [1025, 757, 1120, 832], {"solid": (2, 1)}),
    ("cargo_cases", "props", "I", [885, 900, 1056, 1012], {"solid": (3, 1)}),
    ("luggage_cart", "props", "I", [1176, 510, 1334, 657], {"solid": (3, 1)}),
    ("terminal_kiosk", "props", "E", [521, 304, 626, 442], {"solid": (2, 1)}),
    ("sign_gantry", "props", "E", [1128, 262, 1304, 443], {"solid": (3, 1)}),
    ("route_board", "props", "I", [587, 474, 879, 666], {"solid": (5, 1)}),
    ("vending_machine", "props", "I", [1365, 469, 1500, 659], {"solid": (2, 1)}),
    ("bench_seats", "props", "I", [906, 535, 1131, 650], {"solid": (4, 1)}),
    ("service_counter", "props", "I", [17, 471, 314, 667], {"solid": (5, 2)}),
    ("bunk_alcove", "props", "I", [21, 241, 333, 445], {"size": (160, 96), "solid": (5, 2)}),
    ("bed", "props", "I", [358, 316, 592, 447], {"solid": (4, 2)}),
    ("coat_rack", "props", "I", [623, 264, 703, 438], {"solid": (2, 1)}),
    ("desk_holo", "props", "I", [744, 247, 1029, 446], {"solid": (5, 2)}),
    ("office_chair", "props", "I", [1088, 287, 1186, 446], {"solid": (2, 1)}),
    ("shelf_wall", "props", "I", [1238, 261, 1518, 434], {"solid": (5, 1)}),
    ("bar_counter", "props", "I", [383, 699, 588, 843], {"solid": (3, 1)}),
    ("bar_corner", "props", "I", [612, 706, 753, 844], {"solid": (2, 1)}),
    ("stool", "props", "I", [769, 733, 823, 835], {"solid": (1, 1)}),
    ("round_table", "props", "I", [843, 716, 962, 847], {"solid": (2, 1)}),
    ("guitar", "props", "I", [975, 697, 1038, 847], {"solid": (1, 1)}),
    ("rope_post", "props", "I", [1068, 689, 1103, 845], {"solid": (1, 1)}),
    ("timber_bracket", "props", "I", [1121, 691, 1288, 845], {"solid": (3, 1)}),
    ("papers_books", "props", "I", [17, 905, 228, 1000], {"flat": True}),
    ("plant_broadleaf", "props", "I", [247, 865, 372, 1006], {"solid": (2, 1)}),
    ("plant_bush", "props", "I", [388, 900, 472, 1006], {"solid": (2, 1)}),
    ("plant_fern", "props", "I", [480, 900, 569, 1006], {"solid": (2, 1)}),
    ("plant_hanging", "props", "I", [578, 861, 645, 1011], {"solid": None}),
    ("lockers", "props", "I", [674, 863, 772, 1016], {"solid": (2, 1)}),
]
