class_name QuestTracker
extends VBoxContainer
## Top-left tracker in the style of the director's key art: the game's name, then the
## open investigation with its active objectives as checkboxes. Reads Journal; draws
## nothing of its own state.

var _name: Label
var _rule: ColorRect
var _quest: Label
var _list: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	_name = _label("COMETOGRAPHIA", 6, UiTheme.DIM)
	_name.add_theme_font_override("font", UiTheme.caps_font())
	_rule = ColorRect.new()
	_rule.color = Color(UiTheme.ACCENT, 0.6)
	_rule.custom_minimum_size = Vector2(110, 1)
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rule)
	_quest = _label("", 8, UiTheme.ACCENT)
	_quest.add_theme_font_override("font", UiTheme.caps_font())
	_list = VBoxContainer.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", 0)
	add_child(_list)
	Journal.updated.connect(func(_k: String, _t: String) -> void: refresh())
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var qid := ""
	for id: String in Journal.quests:
		if not Journal.is_complete(id):
			qid = id
			break
	if qid == "":
		_quest.text = ""
		return
	_quest.text = Journal.quest_title(qid).to_upper()
	for o: Dictionary in Journal.quest_defs.get(qid, {}).get("objectives", []):
		var st := Journal.objective_state(qid, str(o["id"]))
		if st == Journal.ACTIVE:
			_list.add_child(_label_node("–  " + str(o["text"]), 7, UiTheme.BONE))
		elif st == Journal.DONE:
			_list.add_child(_label_node("✓  " + str(o["text"]), 7, Color(UiTheme.DIM, 0.8)))


func _label(text: String, size: int, col: Color) -> Label:
	var l := _label_node(text, size, col)
	add_child(l)
	return l


func _label_node(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", UiTheme.SHADOW)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
