class_name PauseMenu
extends Control

signal closed
signal new_game_requested
signal title_requested

## Set by game/app.gd when a title screen exists to return to.
var title_enabled := false
var _title: Button

var _status: Label
var _load: Button
var _new: Button
var _first: Button
var _confirm_new := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.04, 0.08, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 0)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "COMETO"
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	title.add_theme_font_override("font", UiTheme.caps_font())
	title.add_theme_font_size_override("font_size", 10)
	box.add_child(title)
	_first = _button(box, "Resume", func() -> void: closed.emit())
	_button(box, "Save", _on_save)
	_load = _button(box, "Load", _on_load)
	_new = _button(box, "New game", _on_new)
	_title = _button(box, "Title screen", func() -> void: title_requested.emit())
	_status = Label.new()
	_status.add_theme_color_override("font_color", UiTheme.DIM)
	_status.add_theme_font_size_override("font_size", 8)
	box.add_child(_status)


func open() -> void:
	_confirm_new = false
	_title.visible = title_enabled
	_new.text = "New game"
	_status.text = "The game also saves itself when you leave."
	_load.disabled = not SaveManager.has_save("manual")
	_first.grab_focus.call_deferred()


func _on_save() -> void:
	var ok := SaveManager.save_game("manual")
	_status.text = "Saved." if ok else "Could not save."
	_load.disabled = not SaveManager.has_save("manual")


func _on_load() -> void:
	if SaveManager.load_game("manual"):
		closed.emit()
	else:
		_status.text = "Could not load."


func _on_new() -> void:
	if not _confirm_new:
		_confirm_new = true
		_new.text = "New game - press again to confirm"
		return
	new_game_requested.emit()
	closed.emit()


func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b
