extends Node
## Boots the game, owns the current map and the player, and is the "world" that
## SaveManager captures and restores.

const MAPS := {
	"anjabi_mine": "res://maps/anjabi/mine_3d.tscn",
	"anjabi_town": "res://maps/anjabi/town_3d.tscn",
}
const START_MAP := "anjabi_town"
const START_QUEST := "quiet_mine"
const PLAYER_SCENE := preload("res://game/player/player.tscn")

## GameMap (2D) or GameMap3D. The player is Player or Player3D to match.
var map
var player
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
	if player is Player and player.walk_mask != null:
		player.global_position = player.walk_mask.nearest_walkable(player.global_position)
	player.camera.reset_smoothing()


func capture_world() -> Dictionary:
	if player is Player3D:
		var p: Vector3 = player.global_position
		return {"map": map_id, "dim": 3, "x": p.x, "y": p.y, "z": p.z, "fx": player.facing.x, "fz": player.facing.z}
	return {
		"map": map_id,
		"x": player.global_position.x,
		"y": player.global_position.y,
		"fx": player.facing.x,
		"fy": player.facing.y,
	}


func restore_world(d: Dictionary) -> void:
	var id := str(d.get("map", START_MAP))
	var known := MAPS.has(id)
	if not known:
		# e.g. saves from the retired separate district map: resume at the Steps
		id = START_MAP
	_enter_map(id)
	if player is Player3D:
		if known and int(d.get("dim", 2)) == 3:
			player.global_position = Vector3(float(d.get("x", 0.0)), float(d.get("y", 0.0)), float(d.get("z", 0.0)))
			var f := Vector3(float(d.get("fx", 0.0)), 0.0, float(d.get("fz", 1.0)))
			player.facing = f.normalized() if f.length() > 0.01 else Vector3(0, 0, 1)
			player.face_now()
		else:
			player.global_position = map.spawn_position("default")
	else:
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
	map = (load(MAPS[id]) as PackedScene).instantiate()
	world.add_child(map)
	if map is GameMap3D:
		player = Player3D.new()
		map.entities.add_child(player)
		player.setup(ui.touch)
	else:
		player = PLAYER_SCENE.instantiate() as Player
		map.entities.add_child(player)
		player.setup(ui.touch, map.bounds)
		player.walk_mask = map.get_node_or_null("WalkMask") as WalkMask
	map.player = player
	ui.bind_player(player)
	# the 2D mist overlay is for 2D maps; 3D maps carry their own fog
	$Weather/Fog.visible = not (map is GameMap3D)
	ui.hud.show_location(map.display_name)


func _on_travel_requested(id: String, spawn: String) -> void:
	if MAPS.has(id):
		load_map.call_deferred(id, spawn)


func _on_tapped() -> void:
	if player != null:
		player.try_interact()
