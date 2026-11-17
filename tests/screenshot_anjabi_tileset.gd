extends Node
## Windowed shots of the Anjabi tileset test yard: the whole map, then the game view
## at each area by day, dusk and night.
##   Godot --path . res://tests/screenshot_anjabi_tileset.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	WorldTime.minutes_per_second = 0.0
	WorldTime.set_time(13, 0)
	Weather.set_weather("clear")
	# the whole map at 1:1 in its own viewport
	var vp := SubViewport.new()
	vp.size = Vector2i(44 * 32, 30 * 32)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var whole: Node = (load("res://world2d/maps/Anjabi_Tileset_Test.tscn") as PackedScene).instantiate()
	vp.add_child(whole)
	await get_tree().create_timer(0.6).timeout
	for n in get_tree().get_nodes_in_group(&"environment_controller"):
		n.call(&"snap")
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(dir.path_join("at_00_overview.png"))
	vp.queue_free()
	await get_tree().process_frame

	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("start_map", "anjabi_tileset_test")
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var shots := [["at_01_plaza_day", [22, 17], 13, 0, "clear"], ["at_02_platform_day", [20, 9], 13, 0, "clear"],
		["at_03_clearing_day", [6, 18], 10, 0, "clear"], ["at_04_mine_dusk", [37, 16], 18, 50, "clear"],
		["at_05_road_rain", [30, 24], 16, 0, "rain"], ["at_06_plaza_night", [18, 16], 22, 0, "clear"],
		["at_07_station_night", [8, 11], 21, 0, "clear"], ["at_08_behind_building", [16, 11], 13, 0, "clear"]]
	for s: Array in shots:
		WorldTime.set_time(s[2], s[3])
		Weather.set_weather(s[4])
		for n in get_tree().get_nodes_in_group(&"environment_controller"):
			n.call(&"snap")
		var p: GridPlayer = main.get("player")
		p.place(Vector2i(s[1][0], s[1][1]), "down")
		await get_tree().create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(str(s[0]) + ".png"))
	get_tree().quit()
