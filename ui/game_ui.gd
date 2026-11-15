class_name GameUi
extends CanvasLayer
## Builds and owns every screen-space control. Panels pause the world.

signal new_game_requested
## The player chose "Title screen" in the pause menu.
signal title_requested

var touch: TouchControls
var hud: Hud
var dialogue_box: DialogueBox
var journal: JournalPanel
var menu: PauseMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.theme = UiTheme.build()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	touch = TouchControls.new()
	touch.process_mode = Node.PROCESS_MODE_PAUSABLE
	hud = Hud.new()
	dialogue_box = DialogueBox.new()
	journal = JournalPanel.new()
	menu = PauseMenu.new()
	for c: Control in [touch, hud, dialogue_box, journal, menu]:
		root.add_child(c)
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	hud.journal_pressed.connect(toggle_journal)
	hud.menu_pressed.connect(toggle_menu)
	journal.closed.connect(close_panels)
	menu.closed.connect(close_panels)
	menu.title_requested.connect(func() -> void: title_requested.emit())
	menu.new_game_requested.connect(func() -> void: new_game_requested.emit())


func bind_player(p: Node) -> void:
	hud.bind_player(p)


func toggle_journal() -> void:
	if journal.visible:
		close_panels()
	elif not Dialogue.active:
		close_panels()
		journal.refresh()
		journal.visible = true
		_set_paused(true)


func toggle_menu() -> void:
	if menu.visible or journal.visible:
		close_panels()
	elif not Dialogue.active:
		menu.visible = true
		menu.open()
		_set_paused(true)


func close_panels() -> void:
	journal.visible = false
	menu.visible = false
	_set_paused(false)


func _set_paused(v: bool) -> void:
	hud.visible = not v
	get_tree().paused = v


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"journal"):
		toggle_journal()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu"):
		toggle_menu()
		get_viewport().set_input_as_handled()
