extends Node
## Windowed shots of the 2D prototype (the Steps baked to 2D) at several times and
## weathers, plus walking and running.  Godot --path . res://tests/screenshot_2d.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	main.set("boot", "proto2d")
	add_child(main)
	WorldTime.minutes_per_second = 0.0
	await get_tree().create_timer(1.0).timeout
	var p: Player2D = main.get("player")
	var S := 16.0
	var looks := [["p2d_01_steps_day", Vector2(2, 5), 13, "clear"], ["p2d_02_terrace_golden", Vector2(-6, -12), 18, "clear"],
		["p2d_03_steps_night_rain", Vector2(2, 5), 22, "rain"], ["p2d_04_pods_morning", Vector2(4, -34), 9, "cloudy"],
		["p2d_05_mine_fog", Vector2(-30, 2), 8, "fog"], ["p2d_06_steps_snow", Vector2(4, 2), 21, "snow"]]
	for l: Array in looks:
		WorldTime.set_time(l[2], 0)
		Weather.set_weather(l[3])
		for n in get_tree().get_nodes_in_group(&"environment_controller"):
			n.call(&"snap")
		p.position = main.get("map").call("nearest_standable", (l[1] as Vector2) * S)
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join(str(l[0]) + ".png"))
	WorldTime.set_time(16, 0)
	Weather.set_weather("clear")
	p.position = Vector2(-4, 6) * S
	await get_tree().create_timer(0.5).timeout
	Input.action_press(&"move_right")
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("p2d_07_walk.png"))
	Input.action_press(&"sprint")
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("p2d_08_run.png"))
	Input.action_release(&"move_right")
	Input.action_release(&"sprint")
	get_tree().quit()
