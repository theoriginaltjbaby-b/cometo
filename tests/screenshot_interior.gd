extends Node
## Windowed shots of the interiors.  Godot --path . res://tests/screenshot_interior.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	WorldTime.minutes_per_second = 0.0
	await get_tree().create_timer(1.0).timeout
	for t: Array in [["int_01_shop_day", 13], ["int_02_shop_night", 22]]:
		WorldTime.set_time(t[1], 0)
		main.call("load_map", "anjabi_shop", "default")
		await get_tree().create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(str(t[0]) + ".png"))
	WorldTime.set_time(13, 0)
	main.call("load_map", "anjabi_town", "shop")
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("int_03_shop_door.png"))
	get_tree().quit()
