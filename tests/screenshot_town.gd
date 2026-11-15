extends Node
## Windowed visual check of the town greybox. Usage as tests/screenshot.gd.

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	main.call("load_map", "anjabi_town", "default")
	var shots := {"town_steps": Vector2(1760, 830), "town_tion": Vector2(1030, 930), "town_mine": Vector2(424, 1364), "town_docks": Vector2(2340, 900)}
	for k: String in shots:
		var player: Player = main.get("player")
		player.global_position = shots[k]
		player.camera.reset_smoothing()
		await get_tree().create_timer(1.6).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(k + ".png"))
	get_tree().quit()
