extends Node
## Boots the game, owns the current map and the player, and is the "world" that
## SaveManager captures and restores.

const MAPS := {
	"anjabi_mine": "res://maps/anjabi/mine_3d.tscn",
	"anjabi_town": "res://maps/anjabi/town_3d.tscn",
	# interiors (InteriorMap3D)
	"anjabi_shop": "res://maps/anjabi/interiors/shop.tscn",
	# Golden Sun-style 2D prototype baked from the 3D district (tools/bake_2d.gd)
	"anjabi_steps_2d": "res://maps/anjabi/steps_2d.tscn",
	# the 2D tile-based rebuild (branch 2d): the Steps vertical slice
	"anjabi_steps": "res://world2d/maps/steps.tscn",
	"anjabi_steps_shop": "res://world2d/maps/shop.tscn",
}
const START_MAP := "anjabi_town"
const START_QUEST := "quiet_mine"
const PLAYER_SCENE := preload("res://game/player/player.tscn")

## GameMap (2D) or GameMap3D. The player is Player or Player3D to match.
var map
var player
var map_id := ""
## How to start, set by game/app.gd before this enters the tree:
## "" = resume the autosave or start new (running this scene directly, tests),
## "new" = new game with `profile`, "load:<slot>" = load that save.
var boot := ""
## Play the arrival shot the next time a game starts or resumes in the town (set by
## game/app.gd when leaving the title; tests leave it off).
var arrival_shot := false
## The map a new game starts on (game/app.gd sets the 2D slice; tests that build
## main.tscn directly keep the 3D town).
var start_map := START_MAP
## Tile maps render here at their native pixel size (240x135 at the reference size)
## and are scaled up by a whole number, so pixels stay square and crisp.
var view2d: SubViewport
## Flags a new game starts with (the created character: player_name, player_look).
var profile := {}

@onready var world: Node2D = $World
## 3D maps render here: at the base resolution with sharp upscaling when
## ArtStyle.handheld is on, otherwise straight to the screen.
var view3d: Node
@onready var ui: GameUi = $UI


func _ready() -> void:
	view3d = world
	if ArtStyle.handheld:
		# a 480x270 image needs far less shadow resolution and filtering
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
		var layer := CanvasLayer.new()
		layer.layer = -1
		add_child(layer)
		var box := SubViewportContainer.new()
		box.stretch = true
		box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var grade := ShaderMaterial.new()
		grade.shader = preload("res://art/shaders/handheld_grade.gdshader")
		box.material = grade
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(box)
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var vp := SubViewport.new()
		vp.own_world_3d = true
		vp.audio_listener_enable_3d = true
		box.add_child(vp)
		view3d = vp
	var layer2 := CanvasLayer.new()
	layer2.layer = -1
	add_child(layer2)
	var box2 := SubViewportContainer.new()
	box2.stretch = true
	box2.stretch_shrink = 2
	box2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer2.add_child(box2)
	box2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view2d = SubViewport.new()
	view2d.snap_2d_transforms_to_pixel = true
	view2d.snap_2d_vertices_to_pixel = true
	view2d.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box2.add_child(view2d)
	SaveManager.world = self
	ui.new_game_requested.connect(new_game)
	ui.touch.tapped.connect(_on_tapped)
	GameState.travel_requested.connect(_on_travel_requested)
	$Weather/Fog.add_to_group(&"fog_overlay")
	if boot == "proto2d":
		new_game("anjabi_steps_2d")
		return
	if boot.begins_with("load:"):
		if SaveManager.load_game(boot.trim_prefix("load:")):
			return
	elif boot == "" and SaveManager.boot_from_autosave and SaveManager.has_save("auto") and SaveManager.load_game("auto"):
		return
	new_game()


func new_game(first_map: String = "") -> void:
	GameState.reset()
	Journal.reset()
	for k: String in profile:
		GameState.set_flag(k, profile[k])
	WorldTime.reset()
	Weather.reset()
	load_map(first_map if first_map != "" else start_map, "default")
	Journal.start_quest(START_QUEST)


func load_map(id: String, spawn: String = "default") -> void:
	_enter_map(id)
	player.global_position = map.spawn_position(spawn)
	if player is GridPlayer:
		player.place(map.tile_of(player.position), map.spawn_facing(spawn))
	if player is Player2D:
		player.global_position = map.nearest_standable(player.global_position)
	if player is Player and player.walk_mask != null:
		player.global_position = player.walk_mask.nearest_walkable(player.global_position)
	player.camera.reset_smoothing()
	_arrive()


func _arrive() -> void:
	if arrival_shot and player is Player3D and map_id == "anjabi_town":
		arrival_shot = false
		(player as Player3D).camera.play_intro()


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
	_arrive()


func _enter_map(id: String) -> void:
	Dialogue.cancel()
	get_tree().paused = false
	if map != null:
		map.get_parent().remove_child(map)
		map.queue_free()
	map_id = id
	map = (load(MAPS[id]) as PackedScene).instantiate()
	if map is TileWorld:
		view2d.add_child(map)
	else:
		(view3d if map is GameMap3D else world).add_child(map)
	if map is TileWorld:
		player = GridPlayer.new()
		map.entities.add_child(player)
		player.setup(ui.touch, map)
	elif map is Map2D:
		player = Player2D.new()
		map.entities.add_child(player)
		player.setup(ui.touch, map)
	elif map is GameMap3D:
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
	$Weather/Rain.visible = not (map is GameMap3D)
	(get_node("Weather/Fog") as CanvasItem).z_index = 0
	ui.hud.show_location(map.display_name)


func _on_travel_requested(id: String, spawn: String) -> void:
	if MAPS.has(id):
		load_map.call_deferred(id, spawn)


func _on_tapped() -> void:
	if player != null:
		player.try_interact()
