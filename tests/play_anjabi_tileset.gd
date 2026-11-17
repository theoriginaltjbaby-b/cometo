extends Node
## Play a 2D map inside the full game (HUD, clock, weather, touch controls) without
## touching the saves. The tileset test yard by default, or any map id:
##   Godot --path . res://tests/play_anjabi_tileset.tscn
##   Godot --path . res://tests/play_anjabi_tileset.tscn -- anjabi_boardwalk
## ] advances the hour, \ cycles the weather (the game's debug keys).

func _ready() -> void:
	SaveManager.autosave_enabled = false
	SaveManager.boot_from_autosave = false
	var main: Node = (load("res://game/main.tscn") as PackedScene).instantiate()
	var args := OS.get_cmdline_user_args()
	main.set("start_map", args[0] if not args.is_empty() else "anjabi_tileset_test")
	add_child(main)
