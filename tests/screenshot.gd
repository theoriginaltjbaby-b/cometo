extends Node
## Windowed visual check: writes PNGs of a few moments to the folder given after "--".
##   Godot --path . res://tests/screenshot.tscn -- /some/folder

var main: Node
var dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		dir = args[0]
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	main = (load("res://game/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _wait(1.6)
	await _shot("01_spawn")
	main.get("player").global_position = Vector2(170, 270)
	await _wait(1.0)
	await _shot("01b_stair_foot")
	var player: Player = main.get("player")
	var ui: GameUi = main.get_node("UI")
	player.global_position = Vector2(516, 282)
	await _wait(1.0)
	player.try_interact()
	await _wait(1.2)
	Dialogue.advance()
	await _wait(1.2)
	await _shot("02_guard_dialogue")
	Dialogue.advance()
	await _wait(0.6)
	await _shot("03_choices")
	Dialogue.cancel()
	player.global_position = Vector2(300, 620)
	await _wait(1.0)
	await _shot("04_pods")
	player.global_position = Vector2(790, 470)
	await _wait(1.0)
	await _shot("05_spur")
	GameState.set_flag("anjabi.cart", "trench")
	main.call("restore_world", {"map": "anjabi_mine", "x": 500.0, "y": 150.0})
	await _wait(1.0)
	await _shot("06_yard")
	GameState.apply([{"clue": "closure_notice"}, {"clue": "early_recall"}, {"objective": "quiet_mine.notice"}, {"reveal": "quiet_mine.way_in"}])
	ui.toggle_journal()
	await _wait(0.4)
	await _shot("07_journal")
	ui.close_panels()
	ui.toggle_menu()
	await _wait(0.4)
	await _shot("08_menu")
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(shot_name + ".png"))
