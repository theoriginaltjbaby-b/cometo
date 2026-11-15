extends Node
## Investigations (quests with objectives) and clues. Definitions are data
## (res://data/journal); this node only holds the player's progress.

signal updated(kind: String, text: String)

const HIDDEN := "hidden"
const ACTIVE := "active"
const DONE := "done"

var quest_defs: Dictionary = {}
var clue_defs: Dictionary = {}
## quest id -> {"objectives": {objective id: state}, "complete": bool}
var quests: Dictionary = {}
var clues: Array[String] = []


func _ready() -> void:
	quest_defs = Data.load_dict("res://data/journal/quests.json")
	clue_defs = Data.load_dict("res://data/journal/clues.json")


func reset() -> void:
	quests = {}
	clues.clear()


func start_quest(id: String) -> void:
	if quests.has(id) or not quest_defs.has(id):
		return
	var states := {}
	for o: Dictionary in quest_defs[id].get("objectives", []):
		states[str(o["id"])] = HIDDEN if o.get("hidden", false) else ACTIVE
	quests[id] = {"objectives": states, "complete": false}
	updated.emit("quest", quest_title(id))


func reveal_objective(path: String) -> void:
	var p := _split(path)
	if p.is_empty() or _state(p[0], p[1]) != HIDDEN:
		return
	quests[p[0]]["objectives"][p[1]] = ACTIVE
	updated.emit("objective_new", objective_text(p[0], p[1]))


func complete_objective(path: String) -> void:
	var p := _split(path)
	if p.is_empty() or _state(p[0], p[1]) in ["", DONE]:
		return
	quests[p[0]]["objectives"][p[1]] = DONE
	updated.emit("objective", objective_text(p[0], p[1]))


func complete_quest(id: String) -> void:
	if not quests.has(id) or quests[id]["complete"]:
		return
	quests[id]["complete"] = true
	updated.emit("complete", quest_title(id))


func add_clue(id: String) -> void:
	if clues.has(id) or not clue_defs.has(id):
		return
	clues.append(id)
	updated.emit("clue", str(clue_defs[id].get("title", id)))


func has_clue(id: String) -> bool:
	return clues.has(id)


func objective_state(quest: String, objective: String) -> String:
	return _state(quest, objective)


func is_complete(quest: String) -> bool:
	return quests.has(quest) and quests[quest]["complete"]


func quest_title(id: String) -> String:
	return str(quest_defs.get(id, {}).get("title", id))


func objective_text(quest: String, objective: String) -> String:
	for o: Dictionary in quest_defs.get(quest, {}).get("objectives", []):
		if str(o["id"]) == objective:
			return str(o.get("text", objective))
	return objective


func to_dict() -> Dictionary:
	return {"quests": quests.duplicate(true), "clues": clues.duplicate()}


func from_dict(d: Dictionary) -> void:
	quests = (d.get("quests", {}) as Dictionary).duplicate(true)
	clues.clear()
	for c: Variant in d.get("clues", []):
		clues.append(str(c))


func _split(path: String) -> PackedStringArray:
	var p := path.split(".")
	if p.size() != 2 or not quests.has(p[0]):
		return PackedStringArray()
	return p


func _state(quest: String, objective: String) -> String:
	if not quests.has(quest):
		return ""
	return str(quests[quest]["objectives"].get(objective, ""))
