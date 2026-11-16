extends Node
## Windowed shots of the market quarter of the Steps and the arrival shot.
##   Godot --path . res://tests/screenshot_overhaul.tscn -- /some/folder

const O: Vector3 = preload("res://maps/anjabi/town_3d.gd").INSERT_AT


func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	WorldTime.minutes_per_second = 0.0
	await get_tree().create_timer(1.2).timeout
	var p: Player3D = main.get("player")
	# arrival shot at dusk, clear
	WorldTime.set_time(18, 50)
	Weather.set_weather("clear")
	_snap()
	p.global_position = O + Vector3(2, 0.05, 6)
	p.camera.play_intro(8.0)
	await get_tree().create_timer(1.5).timeout
	await _shot(dir, "ov_01_arrival")
	await get_tree().create_timer(3.4).timeout
	await _shot(dir, "ov_02_arrival_sweep")
	await get_tree().create_timer(3.5).timeout
	var spots := [["ov_03_plaza_dusk", Vector3(2, 0.05, 5), 18, 50, "clear"], ["ov_04_market_night", Vector3(-4, 0.05, -2), 21, 30, "clear"],
		["ov_05_plaza_day", Vector3(2, 0.05, 4), 11, 0, "clear"], ["ov_06_terrace_houses", Vector3(4, 3.05, -19), 19, 30, "clear"],
		["ov_07_garden", Vector3(-17, 3.05, -18), 17, 30, "clear"], ["ov_08_plaza_rain_night", Vector3(2, 0.05, 5), 22, 0, "rain"]]
	for s: Array in spots:
		WorldTime.set_time(s[2], s[3])
		Weather.set_weather(s[4])
		_snap()
		p.global_position = O + (s[1] as Vector3)
		p.velocity = Vector3.ZERO
		p.camera.reset_smoothing()
		await get_tree().create_timer(1.0).timeout
		await _shot(dir, s[0])
	get_tree().quit()


func _snap() -> void:
	for n in get_tree().get_nodes_in_group(&"environment_controller"):
		n.call(&"snap")


func _shot(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name + ".png"))
