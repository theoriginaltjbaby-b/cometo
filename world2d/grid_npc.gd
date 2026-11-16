class_name GridNpc
extends GridActor
## A person on a TileWorld. Talkable NPCs come from data/npcs2d.json (name, dialogue,
## look) and turn to face whoever speaks to them. Walkers wander a rectangle a step at
## a time. Schedules (WorldTime) and factions attach here later; nothing in this class
## draws except through GridActor and PixelArt.

var npc_id := ""
var display_name := ""
var dialogue_id := ""
var interactable: Interactable
## Tiles a walker may wander (empty = stands still).
var wander := Rect2i()
var _wait := 0.0


func _ready() -> void:
	walk_time = 0.32
	super._ready()
	if dialogue_id != "":
		interactable = Interactable.new()
		interactable.prompt = "Talk"
		interactable.label = display_name
		interactable.dialogue_id = dialogue_id
		add_child(interactable)
		interactable.interacted.connect(_on_talk)
	_wait = randf_range(0.5, 3.0)


func _on_talk(by: Node2D) -> void:
	var d := (by.position - position)
	if absf(d.x) > absf(d.y):
		face(Vector2i(signi(int(signf(d.x))), 0))
	else:
		face(Vector2i(0, signi(int(signf(d.y)))))


func _process(delta: float) -> void:
	super._process(delta)
	if wander.size == Vector2i.ZERO or _moving or Dialogue.active:
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = randf_range(1.2, 4.0)
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var d: Vector2i = dirs[randi() % 4]
	if wander.has_point(tile + d):
		try_step(d)
	else:
		face(d)
