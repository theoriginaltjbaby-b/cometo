class_name UiTheme
## Interface look, built in code so nothing falls back to default Godot styling.
## PROVISIONAL: system typeface. A licensed display/body face should replace it.

const INK := Color(0.05, 0.07, 0.09, 0.94)
const INK_SOFT := Color(0.05, 0.07, 0.09, 0.72)
const AMBER := Color(0.93, 0.69, 0.36)
const BONE := Color(0.87, 0.85, 0.79)
const DIM := Color(0.58, 0.62, 0.64)


static func box(bg: Color, border: Color, border_w: int = 1, pad: float = 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	s.anti_aliasing = false
	return s


static func build() -> Theme:
	var t := Theme.new()
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Avenir Next Condensed", "Avenir Next", "Helvetica Neue", "sans-serif"])
	f.font_weight = 500
	t.default_font = f
	t.default_font_size = 10

	t.set_stylebox("panel", "PanelContainer", box(INK, Color(AMBER, 0.45)))

	var flat := box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3.0)
	var hover := box(Color(AMBER, 0.14), Color(0, 0, 0, 0), 0, 3.0)
	var focus := box(Color(AMBER, 0.1), Color(AMBER, 0.8), 0, 3.0)
	focus.border_width_left = 2
	t.set_stylebox("normal", "Button", flat)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", flat)
	t.set_color("font_color", "Button", BONE)
	t.set_color("font_hover_color", "Button", AMBER)
	t.set_color("font_pressed_color", "Button", AMBER)
	t.set_color("font_focus_color", "Button", AMBER)
	t.set_color("font_disabled_color", "Button", Color(DIM, 0.5))

	t.set_color("font_color", "Label", BONE)
	t.set_color("default_color", "RichTextLabel", BONE)
	t.set_font_size("normal_font_size", "RichTextLabel", 10)
	t.set_constant("line_separation", "RichTextLabel", 1)
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_constant("separation", "HBoxContainer", 6)
	return t


## A small bordered button for HUD chips.
static func chip(button: Button) -> void:
	button.add_theme_stylebox_override("normal", box(INK_SOFT, Color(AMBER, 0.35), 1, 4.0))
	button.add_theme_stylebox_override("hover", box(INK, Color(AMBER, 0.8), 1, 4.0))
	button.add_theme_stylebox_override("pressed", box(INK, AMBER, 1, 4.0))
	button.add_theme_stylebox_override("focus", box(INK_SOFT, Color(AMBER, 0.35), 1, 4.0))
	button.focus_mode = Control.FOCUS_NONE
