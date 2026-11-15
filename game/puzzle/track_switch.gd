class_name TrackSwitch
extends StaticBody2D
## Points lever. Flips a GameState flag between "a" and "b"; anything on the
## rails reads that flag. PROVISIONAL ART (drawn in code).

@export var switch_key := "anjabi.spur_switch"
@export var notify_a := "The points grind across, toward the buffer."
@export var notify_b := "The points grind across, toward the washout."

var _interactable: Interactable


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	_interactable = Interactable.new()
	_interactable.prompt = "Throw"
	_interactable.label = "Points lever"
	add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)
	GameState.flag_changed.connect(_on_flag_changed)


func branch() -> String:
	return str(GameState.get_flag(switch_key, "a"))


func _on_interacted(_by: Node2D) -> void:
	var next := "b" if branch() == "a" else "a"
	GameState.set_flag(switch_key, next)
	GameState.notify(notify_b if next == "b" else notify_a)


func _on_flag_changed(key: String, _value: Variant) -> void:
	if key == switch_key:
		queue_redraw()


func _draw() -> void:
	var lean := -5.0 if branch() == "a" else 5.0
	draw_rect(Rect2(-4, -3, 8, 4), Color(0.2, 0.2, 0.22))
	draw_line(Vector2(0, -2), Vector2(lean, -14), Color(0.55, 0.3, 0.2), 2.0)
	draw_circle(Vector2(lean, -15), 2.0, Color(0.85, 0.82, 0.7) if branch() == "a" else Color(0.85, 0.3, 0.2))
