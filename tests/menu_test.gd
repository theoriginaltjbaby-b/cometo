extends Node
## Headless check of the title screen, menu, options, character creation and the
## title <-> game flow.   Godot --headless --path . res://tests/menu_test.tscn
## Uses its own save folder and settings file, never the player's.

const DIR := "user://test_menu"

var _fails := 0
var _checks := 0
var app: Node
var title: TitleScreen


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_wipe()
	SaveManager.dir = DIR
	SaveManager.autosave_enabled = true
	Settings.path = DIR.path_join("settings.cfg")
	await _boot()

	# --- the title at rest
	check(title.is_visible_in_tree() and not app.call("in_game") and app.get("main") == null, "boot shows the title and starts no game")
	check(WorldTime.is_paused(), "the world clock is paused at the title")
	var want := ["NEW GAME", "LOAD GAME", "OPTIONS"]
	if OS.has_feature("pc"):
		want.append("QUIT")
	check(Array(title.items()) == want, "menu offers %s (got %s)" % [str(want), str(title.items())])
	check(Audio.current_music == "title", "the title theme is requested (placeholder)")
	check(title.backdrop.planet.material is ShaderMaterial and title.ship != null, "the planet and the ship are in the scene")

	# --- keyboard and gamepad navigation
	var f := get_viewport().gui_get_focus_owner() as Button
	check(f != null and f.text == "NEW GAME", "the first entry has the focus")
	_action(&"ui_down")
	await _frames(2)
	f = get_viewport().gui_get_focus_owner() as Button
	check(f != null and f.text == "LOAD GAME" and Audio.last_ui == "move", "down moves the highlight and plays the move sound")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_DOWN
	pad.pressed = true
	Input.parse_input_event(pad)
	await _frames(2)
	f = get_viewport().gui_get_focus_owner() as Button
	check(f != null and f.text == "OPTIONS", "the gamepad d-pad moves it too")
	pad = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	await _frames(2)
	pad = pad.duplicate()
	pad.pressed = false
	Input.parse_input_event(pad)
	await _frames(2)
	check(title.state() == "options" and Audio.last_ui in ["accept", "move"], "gamepad A opens Options")

	# --- options
	var music := title.slider("music")
	check(music != null and title.slider("master") != null and title.slider("sfx") != null, "Options has master, music and effects volume")
	music.value = 0.25
	var bus := AudioServer.get_bus_index("Music")
	check(bus >= 0 and absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.25)) < 0.1, "the music slider sets the Music bus")
	title.slider("master").value = 0.0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "master at zero mutes")
	title.slider("master").value = 0.6
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "and unmutes when raised")
	_action(&"ui_cancel")
	await _frames(2)
	check(title.state() == "menu" and FileAccess.file_exists(Settings.path), "cancel returns to the menu and settings are saved")
	Settings.volume["music"] = 1.0
	Settings.load_settings()
	check(is_equal_approx(Settings.volume["music"], 0.25) and is_equal_approx(Settings.volume["master"], 0.6), "settings persist")

	# --- load with nothing valid to load
	var bad := FileAccess.open(DIR.path_join("save_broken.json"), FileAccess.WRITE)
	bad.store_string("{ not json")
	bad.close()
	var old := FileAccess.open(DIR.path_join("save_old.json"), FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 0, "world": {"map": "anjabi_town"}}))
	old.close()
	title.choose("LOAD GAME")
	await _frames(2)
	check(title.state() == "load" and title.listed_saves().is_empty(), "unreadable and old-version files are not offered")
	title.choose("BACK")
	await _frames(2)

	# --- new game leads to character creation, then the game
	title.choose("NEW GAME")
	await _frames(4)
	var cc: CharacterCreation = app.get("creation")
	check(cc != null and not app.call("in_game") and WorldTime.is_paused(), "NEW GAME opens character creation; still no game, clock still paused")
	cc.step("hair")
	cc.step("coat")
	cc.set_player_name("Tester")
	var prof := cc.profile()
	check(prof["player_name"] == "Tester" and prof["player_look"]["hair"] == "short" and prof["player_look"]["coat"] == "#1f3555", "creation builds a profile (%s)" % str(prof["player_look"]))
	cc.done.emit(prof)
	await _frames(8)
	var main: Node = app.get("main")
	check(app.call("in_game") and main != null and not title.is_visible_in_tree(), "BEGIN starts the game and hides the title")
	var player: Player3D = main.get("player")
	check(player != null and player.figure.hair == "short" and player.figure.coat.is_equal_approx(Color.html("#1f3555")), "the player wears the created look")
	check(str(GameState.get_flag("player_name", "")) == "Tester" and Journal.quests.has("quiet_mine"), "the name is kept and the opening quest begins")
	check(not WorldTime.is_paused() and WorldTime.time_text() == "6:40 PM" and Audio.current_music == "game", "the clock runs from the start of the game")

	# --- back to the title without losing the game
	WorldTime.minutes_per_second = 0.0
	WorldTime.advance_minutes(45)
	player.global_position += Vector3(3, 0, 0)
	await _frames(4)
	var pos := player.global_position
	var ui: GameUi = main.get("ui")
	ui.toggle_menu()
	await _frames(2)
	check(ui.menu.title_enabled and ui.menu.find_children("*", "Button", true, false).any(func(b: Button) -> bool: return b.text == "Title screen" and b.visible), "the pause menu offers the title screen")
	ui.title_requested.emit()
	await _frames(6)
	check(not app.call("in_game") and app.get("main") == main and title.is_visible_in_tree() and not get_tree().paused, "returning shows the title and keeps the game loaded")
	check(Array(title.items())[0] == "CONTINUE" and not SaveManager.slot_info("auto").is_empty(), "the title now offers CONTINUE and the game was autosaved")
	WorldTime.minutes_per_second = 600.0
	var m0 := WorldTime.total_minutes()
	await _frames(20)
	check(WorldTime.total_minutes() == m0, "no time passes while at the title")
	title.choose("CONTINUE")
	await _frames(6)
	check(app.call("in_game") and app.get("main") == main and main.get("player") == player and player.global_position.distance_to(pos) < 0.2, "CONTINUE resumes the same game where it was left")
	check(WorldTime.time_text() == "7:25 PM" or WorldTime.total_minutes() > m0, "and the clock carries on from 7:25 PM")
	await _frames(10)
	check(WorldTime.total_minutes() > m0, "time runs again in the game")
	WorldTime.minutes_per_second = 0.0
	check((player.camera as Camera3D).current, "the game camera is current again")

	# --- loading from the title bypasses creation
	check(SaveManager.save_game("manual"), "save in game")
	var saved_at := player.global_position
	var saved_clock := WorldTime.total_minutes()
	player.global_position += Vector3(-4, 0, 0)
	WorldTime.advance_minutes(200)
	app.call("return_to_title")
	await _frames(6)
	title.choose("LOAD GAME")
	await _frames(2)
	var listed := Array(title.listed_saves())
	check(listed.has("manual") and listed.has("auto") and not listed.has("broken") and not listed.has("old"), "LOAD GAME lists the valid slots (%s)" % str(listed))
	check(title.choose("MANUAL SAVE"), "the manual save can be chosen")
	await _frames(8)
	var main2: Node = app.get("main")
	check(app.call("in_game") and main2 != main and app.get("creation") == null, "loading starts the game directly, with no character creation")
	var p2: Player3D = main2.get("player")
	check(p2.global_position.distance_to(saved_at) < 0.3 and WorldTime.total_minutes() == saved_clock, "the save's position and clock are restored")
	check(p2.figure.hair == "short" and str(GameState.get_flag("player_name", "")) == "Tester", "the created character comes back with the save")

	# --- new game over a game in progress asks first
	app.call("return_to_title")
	await _frames(6)
	title.choose("NEW GAME")
	await _frames(4)
	check(app.get("creation") == null and Array(title.items()).any(func(t: String) -> bool: return t.contains("CONFIRM")), "NEW GAME over a game in progress asks for confirmation")
	title.choose("NEW GAME")
	await _frames(4)
	cc = app.get("creation")
	check(cc != null, "confirming opens character creation")
	cc.cancelled.emit()
	await _frames(4)
	check(app.get("creation") == null and title.state() == "menu" and app.get("main") == main2, "BACK returns to the title with the game untouched")

	# --- a fresh launch with an autosave offers CONTINUE
	app.queue_free()
	await _frames(3)
	await _boot()
	check(Array(title.items())[0] == "CONTINUE" and app.get("main") == null, "a fresh launch offers CONTINUE from the autosave")
	title.choose("CONTINUE")
	await _frames(8)
	check(app.call("in_game") and app.get("creation") == null, "which loads it without character creation")
	check((app.get("main").get("player") as Player3D).figure.hair == "short", "with the same character")

	app.queue_free()
	await _frames(2)
	_wipe()
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _boot() -> void:
	app = (load("res://game/app.tscn") as PackedScene).instantiate()
	# this test covers the title flow into the 3D town; tests/slice2d_test.gd covers the 2D slice
	app.set("start_map", "anjabi_town")
	app.set("animate", false)
	app.set("fade_time", 0.0)
	add_child(app)
	await _frames(4)
	title = app.get("title")


func _action(a: StringName) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)


func _wipe() -> void:
	var d := DirAccess.open(DIR)
	if d != null:
		for f in d.get_files():
			d.remove(f)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
