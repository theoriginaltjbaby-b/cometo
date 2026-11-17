extends Node
## Windowed shots of any 2D map: the whole map at 1:1, then the game view at each of
## its spawns, by day and at dusk.
##   Godot --path . res://tests/screenshot_map2d.tscn -- /some/folder anjabi_boardwalk
## Extra arguments "x,y" add game-view shots at those tiles.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "user://"
	var id: String = args[1] if args.size() > 1 else "anjabi_boardwalk"
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	WorldTime.minutes_per_second = 0.0
	WorldTime.set_time(13, 0)
	Weather.set_weather("clear")
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	var path: String = main.get("MAPS")[id]
	# the whole map at 1:1 in its own viewport
	var whole: Node2D = (load(path) as PackedScene).instantiate()
	var vp := SubViewport.new()
	vp.size = Vector2i((whole.get("bounds") as Rect2).size)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	vp.add_child(whole)
	await get_tree().create_timer(0.6).timeout
	for n in get_tree().get_nodes_in_group(&"environment_controller"):
		n.call(&"snap")
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(dir.path_join(id + "_00_overview.png"))
	vp.queue_free()
	await get_tree().process_frame

	main.set("start_map", id)
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var map: TileWorld = main.get("map")
	var spots: Array = []
	for m in map.get_node("Spawns").get_children():
		spots.append([str(m.name), map.tile_of((m as Node2D).position)])
	for i in range(2, args.size()):
		var xy := args[i].split(",")
		spots.append(["at_%s_%s" % [xy[0], xy[1]], Vector2i(int(xy[0]), int(xy[1]))])
	var n := 1
	for when: Array in [["day", 13, 0], ["dusk", 19, 10]]:
		WorldTime.set_time(when[1], when[2])
		for c in get_tree().get_nodes_in_group(&"environment_controller"):
			c.call(&"snap")
		for s: Array in spots:
			(main.get("player") as GridPlayer).place(s[1], "down")
			await get_tree().create_timer(0.7).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(dir.path_join("%s_%02d_%s_%s.png" % [id, n, s[0], when[0]]))
			n += 1
	get_tree().quit()
