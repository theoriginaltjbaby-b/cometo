extends Node
## Data-driven dialogue runner. UI listens to the signals; nothing here draws.
##
## res://data/dialogue/<id>.json:
## {
##   "entry": [ {"if": cond, "goto": "node"}, {"goto": "first"} ],
##   "nodes": {
##     "first": {
##       "do":   [effects on entering the node],
##       "say":  [["Speaker", "line"], ["", "narration"]],
##       "then": [effects once the lines have been read],
##       "choices": [ {"text": "...", "if": cond, "do": [effects], "goto": "node"} ],
##       "goto": "node"            (used when no choice is available; default "end")
##     }
##   }
## }

signal started(id: String)
signal line_shown(speaker: String, text: String)
signal choices_shown(options: Array[String])
signal ended(id: String)

const ROOT := "res://data/dialogue/%s.json"

var active := false
var current_id := ""
var current_choices: Array[Dictionary] = []

var _data: Dictionary = {}
var _node: Dictionary = {}
var _lines: Array = []
var _line_i := 0
var _cache: Dictionary = {}
var _hops := 0


func start(id: String) -> bool:
	if active:
		return false
	if not _cache.has(id):
		_cache[id] = Data.load_dict(ROOT % id)
	_data = _cache[id]
	if _data.is_empty():
		push_warning("Dialogue: nothing to say for '%s'" % id)
		return false
	current_id = id
	active = true
	started.emit(id)
	var entry := "start"
	for e: Dictionary in _data.get("entry", []):
		if GameState.check(e.get("if")):
			entry = str(e.get("goto", "start"))
			break
	_hops = 0
	_enter(entry)
	return true


func advance() -> void:
	if not active or not current_choices.is_empty():
		return
	_line_i += 1
	if _line_i < _lines.size():
		_emit_line()
	else:
		_after_lines()


func choose(index: int) -> void:
	if not active or index < 0 or index >= current_choices.size():
		return
	var c := current_choices[index]
	current_choices = []
	GameState.apply(c.get("do"))
	_hops = 0
	_enter(str(c.get("goto", "end")))


func cancel() -> void:
	if active:
		_finish()


func choice_texts() -> Array[String]:
	var out: Array[String] = []
	for c in current_choices:
		out.append(str(c.get("text", "...")))
	return out


func _enter(node_name: String) -> void:
	var nodes: Dictionary = _data.get("nodes", {})
	_hops += 1
	if node_name == "end" or not nodes.has(node_name) or _hops > 32:
		if node_name != "end":
			push_warning("Dialogue '%s': bad node '%s'" % [current_id, node_name])
		_finish()
		return
	_node = nodes[node_name]
	GameState.apply(_node.get("do"))
	_lines = _node.get("say", [])
	_line_i = 0
	if _lines.is_empty():
		_after_lines()
	else:
		_emit_line()


func _emit_line() -> void:
	var l: Array = _lines[_line_i]
	line_shown.emit(str(l[0]), str(l[1]))


func _after_lines() -> void:
	GameState.apply(_node.get("then"))
	var opts: Array[Dictionary] = []
	for c: Dictionary in _node.get("choices", []):
		if GameState.check(c.get("if")):
			opts.append(c)
	if opts.is_empty():
		_enter(str(_node.get("goto", "end")))
	else:
		current_choices = opts
		choices_shown.emit(choice_texts())


func _finish() -> void:
	var id := current_id
	active = false
	current_id = ""
	current_choices = []
	_lines = []
	ended.emit(id)
