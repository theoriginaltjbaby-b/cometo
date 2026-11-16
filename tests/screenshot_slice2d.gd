extends Node
## Windowed shots of the 2D vertical slice (the Steps and the shop).
##   Godot --path . res://tests/screenshot_slice2d.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("start_map", "anjabi_steps")
	add_child(main)
	WorldTime.minutes_per_second = 0.0
	await get_tree().create_timer(1.0).timeout
	var shots := [["s2_01_plaza_dusk", [19, 22], 18, 50, "clear"], ["s2_02_market_night", [6, 17], 21, 30, "clear"],
		["s2_03_terrace_day", [11, 8], 11, 0, "clear"], ["s2_04_shopfront_rain", [34, 19], 22, 0, "rain"],
		["s2_05_stairs_arch", [19, 11], 16, 30, "cloudy"], ["s2_06_plaza_morning", [14, 19], 8, 0, "fog"]]
	for s: Array in shots:
		WorldTime.set_time(s[2], s[3])
		Weather.set_weather(s[4])
		for n in get_tree().get_nodes_in_group(&"environment_controller"):
			n.call(&"snap")
		var p: GridPlayer = main.get("player")
		var map: TileWorld = main.get("map")
		p.place(Vector2i(s[1][0], s[1][1]), "down")
		await get_tree().create_timer(0.8).timeout
		await _shot(dir, s[0])
	WorldTime.set_time(13, 0)
	main.call("load_map", "anjabi_steps_shop", "default")
	await get_tree().create_timer(1.0).timeout
	await _shot(dir, "s2_07_shop")
	main.call("load_map", "anjabi_steps", "default")
	await get_tree().create_timer(0.6).timeout
	var pl: GridPlayer = main.get("player")
	Input.action_press(&"move_left")
	await get_tree().create_timer(0.35).timeout
	await _shot(dir, "s2_08_walk")
	Input.action_press(&"sprint")
	await get_tree().create_timer(0.3).timeout
	await _shot(dir, "s2_09_run")
	Input.action_release(&"sprint")
	Input.action_release(&"move_left")
	get_tree().quit()


func _shot(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name + ".png"))
