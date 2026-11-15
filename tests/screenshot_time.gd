extends Node
## Windowed shots of the same spots through the day and in each weather, plus the
## run pose. Usage:  Godot --path . res://tests/screenshot_time.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	WorldTime.minutes_per_second = 0.0
	await get_tree().create_timer(1.0).timeout
	var o := Vector3(101.52, 0, 45.72)
	var p: Player3D = main.get("player")
	var looks := [
		["t_01_dawn_clear", 5, 50, "clear"], ["t_02_morning_clear", 9, 0, "clear"], ["t_03_midday_clear", 13, 0, "clear"],
		["t_04_golden_clear", 18, 40, "clear"], ["t_05_dusk_clear", 19, 45, "clear"], ["t_06_night_clear", 23, 0, "clear"],
		["t_07_midday_cloudy", 13, 0, "cloudy"], ["t_08_midday_rain", 13, 0, "rain"], ["t_09_evening_heavy", 18, 40, "heavy_rain"],
		["t_10_morning_fog", 8, 0, "fog"], ["t_11_midday_snow", 13, 0, "snow"], ["t_12_night_snow", 22, 0, "snow"],
	]
	for l: Array in looks:
		WorldTime.set_time(l[1], l[2])
		Weather.set_weather(l[3])
		for n in get_tree().get_nodes_in_group(&"environment_controller"):
			n.call(&"snap")
		p.global_position = o + Vector3(2, 0.05, 5)
		p.velocity = Vector3.ZERO
		p.camera.reset_smoothing()
		await get_tree().create_timer(0.9).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(str(l[0]) + ".png"))
	# other places at midday and golden hour
	for l: Array in [["t_20_docks_midday", Vector2(1170, 460), 13, 0], ["t_21_pods_golden", Vector2(600, 150), 18, 30], ["t_22_beach_dawn", Vector2(650, 600), 6, 10]]:
		WorldTime.set_time(l[2], l[3])
		Weather.set_weather("clear")
		for n in get_tree().get_nodes_in_group(&"environment_controller"):
			n.call(&"snap")
		p.global_position = main.get("map").call("nearest_walk", l[1]) + Vector3(0, 0.1, 0)
		p.velocity = Vector3.ZERO
		p.camera.reset_smoothing()
		await get_tree().create_timer(0.9).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(str(l[0]) + ".png"))
	# walk and run poses
	WorldTime.set_time(16, 30)
	Weather.set_weather("clear")
	for l: Array in [["t_30_walk", false], ["t_31_run", true]]:
		p.global_position = o + Vector3(-8, 0.05, 6)
		p.camera.reset_smoothing()
		Input.action_press(&"move_right")
		if l[1]:
			Input.action_press(&"sprint")
		await get_tree().create_timer(0.62).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(str(l[0]) + ".png"))
		Input.action_release(&"move_right")
		Input.action_release(&"sprint")
		await get_tree().create_timer(0.4).timeout
	get_tree().quit()
