class_name Hud
extends Control
## Minimal in-world HUD: one contextual prompt chip, two small corner chips,
## transient journal toasts and the location title card.

signal journal_pressed
signal menu_pressed

var player: Player

var _safe: Control
var _prompt: Button
var _toast: Label
var _title: Label
var _queue: Array[String] = []
var _toasting := false
var _title_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe = Control.new()
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	_safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var corner := HBoxContainer.new()
	_safe.add_child(corner)
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.position += Vector2(-6, 6)
	corner.add_child(_chip("JOURNAL", func() -> void: journal_pressed.emit()))
	corner.add_child(_chip("MENU", func() -> void: menu_pressed.emit()))

	_prompt = _chip("", func() -> void:
		if player != null:
			player.try_interact())
	_prompt.add_theme_font_size_override("font_size", 10)
	_safe.add_child(_prompt)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_bottom = -12
	_prompt.offset_top = -12
	_prompt.visible = false

	_toast = Label.new()
	_toast.add_theme_color_override("font_color", UiTheme.AMBER)
	_toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_toast.add_theme_font_size_override("font_size", 9)
	_toast.modulate.a = 0.0
	_safe.add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_toast.position = Vector2(8, 8)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.modulate.a = 0.0
	_safe.add_child(_title)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.offset_top = 46

	Journal.updated.connect(_on_journal_updated)
	GameState.notified.connect(toast)
	GameState.location_entered.connect(show_location)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func bind_player(p: Player) -> void:
	player = p


func show_location(text: String) -> void:
	_title.text = text
	if _title_tween != null:
		_title_tween.kill()
	_title.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "modulate:a", 1.0, 0.8).set_delay(0.3)
	_title_tween.tween_interval(2.2)
	_title_tween.tween_property(_title, "modulate:a", 0.0, 1.2)


func toast(text: String) -> void:
	_queue.append(text)
	if not _toasting:
		_next_toast()


func prompt_text() -> String:
	return _prompt.text if _prompt.visible else ""


func _process(_delta: float) -> void:
	var t: Interactable = player.target if is_instance_valid(player) else null
	var show := t != null and not Dialogue.active
	_prompt.visible = show
	if show:
		var text := t.prompt.to_upper()
		if t.label != "":
			text += "  ·  " + t.label
		if _prompt.text != text:
			_prompt.text = text


func _next_toast() -> void:
	if _queue.is_empty():
		_toasting = false
		return
	_toasting = true
	_toast.text = _queue.pop_front()
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_next_toast)


func _on_journal_updated(kind: String, text: String) -> void:
	match kind:
		"quest":
			toast("INVESTIGATION OPENED  ·  " + text)
		"objective_new":
			toast("NEW LEAD  ·  " + text)
		"objective":
			toast("LEAD FOLLOWED  ·  " + text)
		"clue":
			toast("CLUE RECORDED  ·  " + text)
		"complete":
			toast("JOURNAL UPDATED  ·  " + text)


func _chip(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 8)
	UiTheme.chip(b)
	b.pressed.connect(on_press)
	return b


## Keeps HUD chips clear of the notch and home indicator. Untested on device.
func _apply_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var k := get_viewport_rect().size / win
	_safe.offset_left = safe.position.x * k.x
	_safe.offset_top = safe.position.y * k.y
	_safe.offset_right = -(win.x - safe.end.x) * k.x
	_safe.offset_bottom = -(win.y - safe.end.y) * k.y
