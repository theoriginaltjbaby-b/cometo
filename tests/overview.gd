extends Node
## Renders a top-down overview of the whole town for comparing with the concept map.
##   Godot --path . res://tests/overview.tscn -- /some/folder

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
	main.get_node("UI").visible = false
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 112.0
	cam.far = 400.0
	cam.position = Vector3(83, 150, 56)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	add_child(cam)
	cam.current = true
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("overview_town.png"))
	get_tree().quit()
