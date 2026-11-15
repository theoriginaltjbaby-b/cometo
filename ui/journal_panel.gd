class_name JournalPanel
extends Control
## Investigations and clues, read straight from the Journal autoload.

signal closed

var _quests: RichTextLabel
var _clues: RichTextLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	var root := VBoxContainer.new()
	panel.add_child(root)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	root.add_child(cols)
	_quests = _column(cols, "INVESTIGATIONS")
	_clues = _column(cols, "CLUES")
	var close := Button.new()
	close.text = "CLOSE"
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.add_theme_font_size_override("font_size", 8)
	UiTheme.chip(close)
	close.pressed.connect(func() -> void: closed.emit())
	root.add_child(close)


func refresh() -> void:
	var amber := UiTheme.AMBER.to_html(false)
	var dim := UiTheme.DIM.to_html(false)
	var q := ""
	for id: String in Journal.quests:
		var def: Dictionary = Journal.quest_defs.get(id, {})
		q += "[color=#%s]%s[/color]" % [amber, Journal.quest_title(id)]
		if Journal.is_complete(id):
			q += "  [color=#%s](to be continued)[/color]" % dim
		q += "\n[color=#%s]%s[/color]\n\n" % [dim, str(def.get("summary", ""))]
		for o: Dictionary in def.get("objectives", []):
			var st := Journal.objective_state(id, str(o["id"]))
			if st == Journal.DONE:
				q += "[color=#%s]✓  %s[/color]\n" % [dim, str(o["text"])]
			elif st == Journal.ACTIVE:
				q += "◦  %s\n" % str(o["text"])
		q += "\n"
	_quests.text = q if q != "" else "[color=#%s]Nothing yet.[/color]" % dim
	var c := ""
	for id in Journal.clues:
		var def: Dictionary = Journal.clue_defs.get(id, {})
		c += "[color=#%s]%s[/color]\n%s\n\n" % [amber, str(def.get("title", id)), str(def.get("text", ""))]
	_clues.text = c if c != "" else "[color=#%s]Nothing recorded.[/color]" % dim


func _column(parent: Control, title: String) -> RichTextLabel:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 8)
	head.add_theme_color_override("font_color", UiTheme.DIM)
	col.add_child(head)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	return body
