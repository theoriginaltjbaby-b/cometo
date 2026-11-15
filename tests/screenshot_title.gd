extends Node
## Windowed shots of the title screen, its panels and character creation.
##   Godot --path . res://tests/screenshot_title.tscn -- /some/folder

func _ready() -> void:
	var dir := "user://"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	var app: Node = (load("res://game/app.tscn") as PackedScene).instantiate()
	app.set("fade_time", 0.0)
	add_child(app)
	var title: TitleScreen = app.get("title")
	await _shot(dir, "title_01_menu", 6.0)
	await _shot(dir, "title_02_later", 8.0)
	title.show_options()
	await _shot(dir, "title_03_options", 0.6)
	title.show_load()
	await _shot(dir, "title_04_load", 0.6)
	title.show_menu()
	title.choose("NEW GAME")
	await _shot(dir, "title_05_character", 1.5)
	get_tree().quit()


func _shot(dir: String, name: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name + ".png"))
