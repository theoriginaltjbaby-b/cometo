extends SceneTree
## Lays out the first version of the Boardwalk and Tram / Subway Station map
## (`anjabi_boardwalk`) from the director's concept map and Greybox Study 01, with the
## Anjabi TileSet library.
##   Godot --headless --path . -s tools/build_anjabi_boardwalk.gd -- --force
## Writes world2d/maps/anjabi_boardwalk.tscn. The scene is a normal Godot scene; once
## it has been edited by hand, do not run this again (it refuses without --force).
##
## Layout, in 32 px cells (52 x 34), north at the top, as on the greybox:
##   north        forest on a low cliff
##   west         the walkway in from the Steps, on the shore
##   centre       the boardwalk deck with its dockside units, kiosk and market
##   east         three piers, and the walkway out to the Rainforest Approach
##   south-west   the Tram / Subway Station on its own platform, with a jetty
##   x = 28       the tram line, north to south (pylons only: see PROJECT_LOG)

const SCENE := "res://world2d/maps/anjabi_boardwalk.tscn"


func _initialize() -> void:
	if FileAccess.file_exists(SCENE) and not "--force" in OS.get_cmdline_user_args():
		print("%s exists; pass -- --force to overwrite it" % SCENE)
		quit(1)
		return
	var p := AnjabiPainter.new("anjabi_boardwalk", "Boardwalk", Vector2i(52, 34), 20261117)

	p.fill("water", Rect2i(0, 0, 52, 34))
	p.fill("grass", Rect2i(0, 0, 38, 8))           # the forest shelf above the cliff
	p.fill("grass", Rect2i(0, 8, 14, 9))           # the shore the walkway crosses
	p.fill("concrete", Rect2i(0, 11, 14, 3))       # walkway from the Steps
	p.fill("wood_deck", Rect2i(14, 8, 24, 13))     # the boardwalk
	p.fill("wood_deck", Rect2i(38, 8, 14, 2))      # walkway to the Rainforest Approach
	p.fill("wood_deck", Rect2i(38, 12, 10, 2))     # north pier
	p.fill("wood_deck", Rect2i(46, 10, 2, 4))      #   and its landing
	p.fill("wood_deck", Rect2i(38, 16, 6, 2))      # middle pier
	p.fill("wood_deck", Rect2i(38, 19, 9, 2))      # south pier
	p.fill("concrete", Rect2i(9, 14, 5, 8))        # ramp down to the station
	p.fill("metal", Rect2i(7, 21, 18, 8))          # station platform
	p.fill("water", Rect2i(14, 21, 8, 1))          # open water behind the station roof
	p.fill("wood_deck", Rect2i(19, 29, 3, 3))      # jetty
	p.edges()

	# the cliff under the forest, along the whole north side
	for x in range(0, 38, 2):
		p.put("terrain", "cliff_face", x, 7)

	for o: Array in [
		# tram line: pylons north to south through the deck
		["industrial", "pillar_large", 28, 3], ["industrial", "pillar_large", 28, 8], ["industrial", "pillar_large", 28, 20],
		["industrial", "pillar_large", 28, 25], ["industrial", "pillar_large", 28, 30],
		# dockside units against the cliff, a kiosk, a terminal
		["architecture", "wall_window_wide", 15, 9], ["architecture", "wall_door", 18, 9], ["architecture", "wall_plain", 20, 9],
		["props", "vending_machine", 22, 8], ["props", "terminal_kiosk", 25, 8], ["architecture", "ticket_booth", 31, 9],
		["industrial", "ac_unit", 34, 8],
		# market corner: a stall under an awning, tables, lanterns
		["props", "bar_counter", 32, 14], ["architecture", "awning_rust", 32, 13], ["props", "lantern_paper_a", 31, 13],
		["props", "lantern_paper_b", 35, 13], ["props", "round_table", 24, 15], ["props", "stool", 23, 15],
		["props", "stool", 26, 15], ["props", "round_table", 33, 17], ["props", "stool", 35, 17],
		# cargo and seats along the south edge, lamps at the corners
		["props", "crate_stack", 15, 20], ["props", "cargo_cases", 19, 19], ["props", "bench_seats", 24, 20],
		["industrial", "rope_fence", 31, 20], ["props", "luggage_cart", 34, 20], ["props", "street_lamp", 14, 16],
		["props", "street_lamp", 37, 11], ["props", "street_lamp", 37, 15], ["props", "street_lamp", 22, 12],
		["props", "plant_fern", 14, 9],
		# pier ends
		["props", "bollard_lamp", 47, 10], ["props", "bollard_lamp", 47, 13], ["props", "bollard_lamp", 43, 16],
		["props", "bollard_lamp", 46, 19], ["props", "cargo_cases", 41, 13], ["industrial", "rope_fence", 41, 17],
		# the station: hall, stairs down, platform furniture, jetty
		["architecture", "station_building", 14, 24], ["architecture", "stairwell_down", 7, 24], ["props", "route_board", 8, 28],
		["props", "bench_seats", 15, 26], ["props", "lamp_teal", 8, 21], ["props", "lamp_teal", 13, 28],
		["props", "lamp_teal", 24, 22], ["props", "cargo_cases", 22, 28], ["props", "bollard_lamp", 21, 31],
		# the shore: lamps along the walkway, planting
		["props", "street_lamp", 5, 10], ["props", "street_lamp", 10, 10], ["nature", "tree_vines_a", 0, 10],
		["nature", "glowplant_teal", 7, 10], ["nature", "mushrooms_blue", 11, 9], ["terrain", "leaf_litter", 4, 9],
		["nature", "tree_canopy", 0, 16], ["terrain", "roots", 5, 16],
	]:
		p.put(o[0], o[1], o[2], o[3])

	# forest above the cliff; undergrowth along the south shore
	var bushes := ["broadleaf", "fern", "heliconia", "lily_bush", "ginger_red", "undergrowth_glow", "mushroom_grotto", "fern", "broadleaf"]
	p.scatter(bushes, Rect2i(0, 0, 38, 6))
	p.scatter(bushes, Rect2i(4, 15, 4, 2))
	var trees := ["tree_vines_a", "tree_canopy", "tree_vines_b"]
	for at: Vector2i in [Vector2i(2, 4), Vector2i(9, 3), Vector2i(15, 5), Vector2i(21, 3), Vector2i(33, 4), Vector2i(36, 2)]:
		(p.layers["nature"] as TileMapLayer).set_cell(at, 0, p.index["nature"][trees[p.rng.randi() % trees.size()]]["at"])

	# ways out are signs until the neighbouring maps exist (as on the Steps slice)
	for y in [11, 12, 13]:
		p.sign(Vector2i(0, y), "Read", "Way to the Steps", "anjabi/boardwalk_to_steps")
	for y in [8, 9]:
		p.sign(Vector2i(51, y), "Read", "Rainforest Approach", "anjabi/boardwalk_to_rainforest")
	for x in [8, 9]:
		p.sign(Vector2i(x, 24), "Look", "Tram / Subway Station", "anjabi/tram_station_stairs")
	for x in [15, 16]:
		p.sign(Vector2i(x, 24), "Look", "Tram / Subway Station", "anjabi/tram_station_door")

	p.spawn("default", Vector2i(18, 13), "down")
	p.spawn("steps", Vector2i(1, 12), "right")
	p.spawn("rainforest", Vector2i(50, 8), "left")
	p.spawn("station", Vector2i(12, 25), "down")
	p.save(SCENE)
	print("built ", SCENE)
	quit()
