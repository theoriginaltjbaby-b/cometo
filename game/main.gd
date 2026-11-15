extends Node
## Boots the game, owns the current map and the player, and is the "world" that
## SaveManager captures and restores.

const MAPS := {
	"anjabi_mine": "res://maps/anjabi/mine.tscn",
	"anjabi_town": "res://maps/anjabi/town.tscn",
}
const START_MAP := "anjabi_mine"
const START_QUEST := "quiet_mine"
const PLAYER_SCENE := preload("res://game/player/player.tscn")

var map: GameMap
var player: Player
var map_id := ""

@onready var world: Node2D = $World
@onready var ui: GameUi = $UI


func _ready() -> void:
	SaveManager.world = self
	ui.new_game_requested.connect(new_game)
	ui.touch.tapped.connect(_on_tapped)
	GameState.travel_requested.connect(_on_travel_requested)
	if SaveManager.boot_from_autosave and SaveManager.has_save("auto") and SaveManager.load_game("auto"):
		return
	new_game()


func new_game() -> void:
	GameState.reset()
	Journal.reset()
	load_map(START_MAP, "default")
	Journal.start_quest(START_QUEST)


func load_map(id: String, spawn: String = "default") -> void:
	_enter_map(id)
	player.global_position = map.spawn_position(spawn)
	if player.walk_mask != null:
		player.global_position = player.walk_mask.nearest_walkable(player.global_position)
	player.camera.reset_smoothing()


func capture_world() -> Dictionary:
	return {
		"map": map_id,
		"x": player.global_position.x,
		"y": player.global_position.y,
		"fx": player.facing.x,
		"fy": player.facing.y,
	}


func restore_world(d: Dictionary) -> void:
	var id := str(d.get("map", START_MAP))
	if not MAPS.has(id):
		id = START_MAP
	_enter_map(id)
	player.global_position = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	player.facing = Vector2(float(d.get("fx", 0.0)), float(d.get("fy", 1.0)))
	player.camera.reset_smoothing()


func _enter_map(id: String) -> void:
	Dialogue.cancel()
	get_tree().paused = false
	if map != null:
		world.remove_child(map)
		map.queue_free()
	map_id = id
	map = (load(MAPS[id]) as PackedScene).instantiate() as GameMap
	world.add_child(map)
	player = PLAYER_SCENE.instantiate() as Player
	map.entities.add_child(player)
	player.setup(ui.touch, map.bounds)
	player.walk_mask = map.get_node_or_null("WalkMask") as WalkMask
	map.player = player
	ui.bind_player(player)
	ui.hud.show_location(map.display_name)


func _on_travel_requested(id: String, spawn: String) -> void:
	if MAPS.has(id):
		load_map.call_deferred(id, spawn)


func _on_tapped() -> void:
	if player != null:
		player.try_interact()
