extends Node
## Windowed visual check of the 3D district. Usage as tests/screenshot.gd:
##   Godot --path . res://tests/screenshot_3d.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var shots := {
		"3d_01_steps": Vector3(2, 0.05, 5),
		"3d_02_tavern": Vector3(-6, 3.05, -11.5),
		"3d_03_bridge": Vector3(8.5, 6.05, -31),
		"3d_04_b17": Vector3(5, 6.05, -36),
		"3d_05_mine_approach": Vector3(-33, -2.95, 3),
		"3d_06_west_stairs": Vector3(-14, -1.5, 2),
	}
	for k: String in shots:
		var player: Player3D = main.get("player")
		player.global_position = shots[k]
		player.velocity = Vector3.ZERO
		player.camera.reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(k + ".png"))
	# walking pose and a conversation
	var p: Player3D = main.get("player")
	p.global_position = Vector3(-5.6, 3.05, -10.9)
	p.camera.reset_smoothing()
	Input.action_press(&"move_left")
	await get_tree().create_timer(0.3).timeout
	Input.action_release(&"move_left")
	await get_tree().create_timer(0.5).timeout
	p.try_interact()
	await get_tree().create_timer(1.2).timeout
	Dialogue.advance()
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("3d_07_dialogue.png"))
	Dialogue.cancel()
	# the mine yard
	main.call("load_map", "anjabi_mine", "default")
	await get_tree().create_timer(0.5).timeout
	var mine := {
		"3d_10_mine_stairs": Vector3(8, 3.0, 7.5),
		"3d_11_mine_gate": Vector3(24, 0.05, 15.5),
		"3d_12_mine_washhouse": Vector3(16, 0.05, 31.5),
		"3d_13_mine_spur": Vector3(39.5, 0.05, 21.5),
		"3d_14_mine_door": Vector3(24, 0.05, 8.5),
	}
	for k: String in mine:
		var mp: Player3D = main.get("player")
		mp.global_position = mine[k]
		mp.velocity = Vector3.ZERO
		mp.camera.reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(k + ".png"))
	GameState.set_flag("anjabi.cart", "trench")
	main.call("restore_world", {"map": "anjabi_mine", "dim": 3, "x": 40.0, "y": 0.05, "z": 18.6, "fx": 0.0, "fz": -1.0})
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("3d_15_mine_bridge.png"))
	get_tree().quit()
