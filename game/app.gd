extends Node
## The application's root scene (project main scene). Shows the title screen, then runs
## the game (game/main.tscn) underneath it.
##
##   title -> NEW GAME  -> character creation -> [intro hook] -> game
##   title -> LOAD GAME -> game (no character creation, no intro)
##   title -> CONTINUE  -> the game in progress, or the autosave
##   game  -> pause menu "Title screen" -> title; the game is kept, not restarted
##
## While the title is up the world clock is paused (WorldTime.pause("title")) and the
## game, if one is loaded, is taken out of the scene tree: it keeps every bit of its
## state but does not process or draw. Running game/main.tscn directly (tests, tools)
## still works and skips all of this.

const MAIN := preload("res://game/main.tscn")

## Seconds for the fades between title, creation and game. Tests set 0.
var fade_time := 0.6
## False in tests: no title fade-in.
var animate := true

var main: Node
var title: TitleScreen
var creation: CharacterCreation

var _layer: CanvasLayer
var _root: Control
var _shade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_root = Control.new()
	_root.theme = UiTheme.build()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title = TitleScreen.new()
	title.animate = animate
	_root.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.continue_requested.connect(_on_continue)
	title.new_game_requested.connect(_on_new_game)
	title.load_requested.connect(_on_load)
	title.quit_requested.connect(_on_quit)
	title.prototype_requested.connect(_on_prototype)
	var top := CanvasLayer.new()
	top.layer = 100
	add_child(top)
	_shade = ColorRect.new()
	_shade.color = Color(0.0, 0.01, 0.03, 1.0)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enter_title()
	if animate:
		_fade(0.0, 2.0)
	else:
		_shade.modulate.a = 0.0


## True while the player is in the game rather than at the title or creating a character.
func in_game() -> bool:
	return main != null and main.is_inside_tree()


func _enter_title() -> void:
	WorldTime.pause("title")
	Audio.play_music("title")
	title.session_live = main != null
	_layer.visible = true
	title.visible = true
	title.show_menu()


# --- title choices ------------------------------------------------------------------

func _on_new_game() -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0)
	creation = CharacterCreation.new()
	_root.add_child(creation)
	creation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	creation.done.connect(_on_created)
	creation.cancelled.connect(_on_creation_cancelled)
	title.set_process_unhandled_input(false)
	title.set_covered(true)
	await _fade(0.0)
	_busy = false


func _on_creation_cancelled() -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0)
	_close_creation()
	title.show_menu()
	await _fade(0.0)
	_busy = false


func _on_created(profile: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0)
	_close_creation()
	await _play_intro()
	_start("new", profile)
	await _fade(0.0)
	_busy = false


func _on_load(slot: String) -> void:
	if _busy or SaveManager.slot_info(slot).is_empty():
		return
	_busy = true
	await _fade(1.0)
	_start("load:" + slot, {})
	await _fade(0.0)
	_busy = false


func _on_continue() -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0)
	if main != null:
		add_child(main)
		move_child(main, 0)
		_enter_game()
	else:
		_start("load:auto", {})
	await _fade(0.0)
	_busy = false


## The Golden Sun-style 2D test area: a fresh game started on the 2D Steps.
func _on_prototype() -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0)
	_start("proto2d", {})
	await _fade(0.0)
	_busy = false


func _on_quit() -> void:
	# a game set aside behind the title was autosaved on the way here
	get_tree().quit()


# --- game ---------------------------------------------------------------------------

## PLACEHOLDER: the introductory cinematic plays here, before a NEW game only. Loading
## and continuing never reach this. Nothing exists yet, so it returns at once.
func _play_intro() -> void:
	await get_tree().process_frame


func _start(boot: String, profile: Dictionary) -> void:
	if main != null:
		if main.is_inside_tree():
			remove_child(main)
		main.free()
	main = MAIN.instantiate()
	main.set("boot", boot)
	main.set("profile", profile)
	add_child(main)
	move_child(main, 0)
	var ui: GameUi = main.get("ui")
	ui.menu.title_enabled = true
	ui.title_requested.connect(return_to_title)
	_enter_game()


func _enter_game() -> void:
	_layer.visible = false
	WorldTime.resume("title")
	Audio.play_music("game")


## Leave the game for the title without ending it: autosave, then set it aside.
func return_to_title() -> void:
	if _busy or not in_game():
		return
	_busy = true
	(main.get("ui") as GameUi).close_panels()
	await _fade(1.0)
	if SaveManager.autosave_enabled:
		SaveManager.save_game("auto")
	remove_child(main)
	_enter_title()
	await _fade(0.0)
	_busy = false


func _notification(what: int) -> void:
	# a game set aside behind the title is not in the tree, so it must be freed by hand
	if what == NOTIFICATION_PREDELETE and is_instance_valid(main) and not main.is_inside_tree():
		main.free()


func _close_creation() -> void:
	if creation != null:
		creation.queue_free()
		creation = null
	title.set_process_unhandled_input(true)
	title.set_covered(false)


func _fade(to: float, seconds: float = -1.0) -> void:
	var t := fade_time if seconds < 0.0 else seconds
	if t <= 0.0 or not animate:
		_shade.modulate.a = to
		return
	var tw := create_tween()
	tw.tween_property(_shade, "modulate:a", to, t).set_trans(Tween.TRANS_SINE)
	await tw.finished
