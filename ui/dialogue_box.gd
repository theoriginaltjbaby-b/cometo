class_name DialogueBox
extends Control
## Renders the Dialogue autoload. Tap / interact to finish a line, then to advance.

@export var chars_per_second := 70.0

var _panel: PanelContainer
var _speaker: Label
var _body: RichTextLabel
var _choices: VBoxContainer
var _more: Label
var _shown := 0.0
var _typing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_panel = PanelContainer.new()
	add_child(_panel)
	_panel.anchor_left = 0.14
	_panel.anchor_right = 0.86
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_bottom = -10
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", UiTheme.AMBER)
	_speaker.add_theme_font_size_override("font_size", 8)
	box.add_child(_speaker)
	_body = RichTextLabel.new()
	_body.fit_content = true
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(0, 30)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_body)
	_choices = VBoxContainer.new()
	box.add_child(_choices)
	_more = Label.new()
	_more.text = "▾"
	_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_more.add_theme_color_override("font_color", UiTheme.AMBER)
	_more.add_theme_font_size_override("font_size", 8)
	box.add_child(_more)

	Dialogue.started.connect(func(_id: String) -> void: visible = true)
	Dialogue.ended.connect(_on_ended)
	Dialogue.line_shown.connect(_on_line)
	Dialogue.choices_shown.connect(_on_choices)


func _process(delta: float) -> void:
	if not _typing:
		return
	_shown += delta * chars_per_second
	if _shown >= _body.text.length():
		_finish_typing()
	else:
		_body.visible_characters = int(_shown)


func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed(&"interact"):
		return
	get_viewport().set_input_as_handled()
	if _choices.get_child_count() > 0:
		var f := get_viewport().gui_get_focus_owner() as Button
		if f != null and f.get_parent() == _choices:
			f.pressed.emit()
	else:
		_step()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _choices.get_child_count() == 0:
			_step()


func _step() -> void:
	if _typing:
		_finish_typing()
	else:
		Dialogue.advance()


func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1
	_more.visible = _choices.get_child_count() == 0


func _on_line(speaker: String, text: String) -> void:
	_clear_choices()
	_speaker.text = speaker.to_upper()
	_speaker.visible = speaker != ""
	_body.add_theme_color_override("default_color", UiTheme.BONE if speaker != "" else Color(0.72, 0.76, 0.78))
	_body.text = text
	_body.visible_characters = 0
	_shown = 0.0
	_typing = true
	_more.visible = false


func _on_choices(options: Array[String]) -> void:
	_finish_typing()
	_clear_choices()
	_more.visible = false
	for i in options.size():
		var b := Button.new()
		b.text = "›  " + options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(Dialogue.choose.bind(i))
		_choices.add_child(b)
	if not options.is_empty():
		(_choices.get_child(0) as Button).grab_focus.call_deferred()


func _on_ended(_id: String) -> void:
	_clear_choices()
	_typing = false
	visible = false


func _clear_choices() -> void:
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
