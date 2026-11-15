extends Node
## Windowed render-cost probe. Prints draw calls, primitives, objects and frame time
## at representative spots. A desktop proxy only; it is not an iPhone measurement.
##   Godot --path . res://tests/perf_probe.tscn

const O := Vector3(101.52, 0, 45.72)


func _ready() -> void:
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	# fixed night rain so runs are comparable; pass "day" after -- to measure a low evening sun
	WorldTime.minutes_per_second = 0.0
	WorldTime.set_time(18 if "day" in OS.get_cmdline_user_args() else 21, 30)
	Weather.set_weather("rain")
	await get_tree().create_timer(1.0).timeout
	print("spot                 draws   prims(k)  objects  frame ms")
	var town_spots := {"steps": O + Vector3(2, 0.05, 5), "tavern terrace": O + Vector3(-6, 3.05, -11.5),
		"pods": Vector2(600, 150), "docks": Vector2(1170, 460), "beach": Vector2(650, 600), "estate": Vector2(240, 590)}
	for k: String in town_spots:
		await _measure(main, k, town_spots[k])
	main.call("load_map", "anjabi_mine", "default")
	await get_tree().create_timer(0.5).timeout
	for k: String in {"mine stairs": Vector3(8, 3.0, 7.5), "mine yard": Vector3(24, 0.05, 15.5), "mine spur": Vector3(39.5, 0.05, 21.5)}:
		await _measure(main, k, {"mine stairs": Vector3(8, 3.0, 7.5), "mine yard": Vector3(24, 0.05, 15.5), "mine spur": Vector3(39.5, 0.05, 21.5)}[k])
	get_tree().quit()


func _measure(main: Node, label: String, where: Variant) -> void:
	var p: Player3D = main.get("player")
	if where is Vector2:
		p.global_position = main.get("map").call("nearest_walk", where) + Vector3(0, 0.1, 0)
	else:
		p.global_position = where
	p.velocity = Vector3.ZERO
	p.camera.reset_smoothing()
	await get_tree().create_timer(1.0).timeout
	var t0 := Time.get_ticks_usec()
	var n := 60
	for i in n:
		await RenderingServer.frame_post_draw
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / n
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var objs := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("%-20s %6d   %7.1f   %6d   %6.2f" % [label, draws, prims / 1000.0, objs, ms])
