extends Node
## Persistent world state: a flat dictionary of flags, plus the tiny condition/effect
## language shared by dialogue, interactables and puzzles.
##
## Conditions (Dictionary):
##   {"flag": "k"}                truthy flag
##   {"flag": "k", "eq": value}   flag equals value
##   {"clue": "id"}               journal holds the clue
##   {"not": cond} {"all": [..]} {"any": [..]}
## Effects (Array of Dictionary):
##   {"set": {"k": value}}  {"clue": "id"}  {"quest": "id"}
##   {"reveal": "quest.objective"}  {"objective": "quest.objective"}  {"complete": "quest"}
##   {"notify": "text"}

signal flag_changed(key: String, value: Variant)
signal notified(text: String)
## Asks the world (game/main.gd) to move the player to another map.
signal travel_requested(map_id: String, spawn: String)
## A named place was entered; the HUD shows it as a title card.
signal location_entered(text: String)

var flags: Dictionary = {}


func _ready() -> void:
	InputSetup.ensure()


func reset() -> void:
	flags = {}


func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)


func set_flag(key: String, value: Variant) -> void:
	if flags.has(key) and _same(flags[key], value):
		return
	flags[key] = value
	flag_changed.emit(key, value)


func notify(text: String) -> void:
	notified.emit(text)


func check(cond: Variant) -> bool:
	if cond == null:
		return true
	if cond is Array:
		for c: Variant in cond:
			if not check(c):
				return false
		return true
	if not cond is Dictionary:
		return bool(cond)
	var d: Dictionary = cond
	if d.is_empty():
		return true
	if d.has("all"):
		return check(d["all"])
	if d.has("any"):
		for c: Variant in d["any"]:
			if check(c):
				return true
		return false
	if d.has("not"):
		return not check(d["not"])
	if d.has("clue"):
		return Journal.has_clue(str(d["clue"]))
	if d.has("flag"):
		var v: Variant = get_flag(str(d["flag"]))
		if d.has("eq"):
			return _same(v, d["eq"])
		return _truthy(v)
	push_warning("GameState.check: unknown condition %s" % [d])
	return true


func apply(effects: Variant) -> void:
	if not effects is Array:
		return
	for e: Variant in effects:
		if not e is Dictionary:
			continue
		var d: Dictionary = e
		if d.has("set"):
			var s: Dictionary = d["set"]
			for k: Variant in s:
				set_flag(str(k), s[k])
		if d.has("clue"):
			Journal.add_clue(str(d["clue"]))
		if d.has("quest"):
			Journal.start_quest(str(d["quest"]))
		if d.has("reveal"):
			Journal.reveal_objective(str(d["reveal"]))
		if d.has("objective"):
			Journal.complete_objective(str(d["objective"]))
		if d.has("complete"):
			Journal.complete_quest(str(d["complete"]))
		if d.has("notify"):
			notify(str(d["notify"]))


func to_dict() -> Dictionary:
	return flags.duplicate(true)


func from_dict(d: Dictionary) -> void:
	flags = d.duplicate(true)


static func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


static func _same(a: Variant, b: Variant) -> bool:
	if _is_num(a) and _is_num(b):
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b


static func _truthy(v: Variant) -> bool:
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING:
			return v != ""
	return true
