class_name TilesetWorld
extends TileWorld
## A TileWorld painted with TileMapLayers and the Anjabi TileSets (art/tilesets/anjabi)
## instead of being built from a data/maps2d file. It answers the same questions
## (can_enter, foot, tile_of, spawns), so GridPlayer, GridNpc, main and the HUD use it
## unchanged.
##
## Scene layout (see world2d/maps/Anjabi_Tileset_Test.tscn):
##   Ground, Edges, Terrain     flat TileMapLayers under everyone
##   Entities (y-sorted)        Nature, Architecture, Industrial, Props layers, people
##   Signs                      one node per usable tile, standing on that tile: either
##                              an Interactable, or a Marker2D with meta "prompt",
##                              "label", "dialogue" (and "to", "spawn" for a door:
##                              stepping onto or using it travels to that map)
##   Spawns                     Marker2D per spawn, at world.foot(tile); meta "facing"
##
## What a tile does comes from its TileSet custom data (tools/build_anjabi_tileset.gd):
##   solid_cells  Array of Vector2i, cells it blocks: x right, y up from its own cell
##   lamp         px above its foot that it casts lamplight from (0 = none)
## Run on its own (F6 in the editor) the scene brings its own player; inside the game
## main supplies one as for any TileWorld.
## The cell size is the Ground layer's TileSet tile size: 32 px for the Anjabi library
## (the 16x32 placeholder people are then drawn at 2x to stand one tile wide), 16 px
## for the coast kit (people at their own size). Either way the view is the full
## 480x270 instead of the Steps slice's 240x135.

const CELL := 32
## Character sheet (art/pixel/chars/<id>.png) the player wears on this map; "" keeps
## the sheet drawn from the created character's look.
@export var player_sheet := ""

## Cell size in px, and how many times a 16 px actor sheet is enlarged to fit it.
var cell := CELL
var actor_scale := 2

var _box: SubViewportContainer
var _shrink := 2


func _enter_tree() -> void:
	# main's 2D view halves the resolution for 16 px maps; this map wants all of it
	_box = get_viewport().get_parent() as SubViewportContainer if get_viewport() is SubViewport else null
	if _box != null:
		_shrink = _box.stretch_shrink
		_box.stretch_shrink = 1


func _exit_tree() -> void:
	if _box != null:
		_box.stretch_shrink = _shrink
		_box = null


func _ready() -> void:
	var layers := find_children("*", "TileMapLayer", true, false)
	var used := Rect2i()
	for l: TileMapLayer in layers:
		l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if l.name == &"Ground":
			used = l.get_used_rect()
			cell = l.tile_set.tile_size.x
	actor_scale = maxi(1, cell / 16)
	size = used.end
	bounds = Rect2(Vector2.ZERO, Vector2(size * cell))
	var bg := ColorRect.new()
	bg.color = PixelArt.VOID
	bg.position = Vector2(-cell * 20, -cell * 20)
	bg.size = Vector2(size * cell) + Vector2(cell * 40, cell * 40)
	bg.z_index = -30
	add_child(bg)
	entities.y_sort_enabled = true
	entities.child_entered_tree.connect(_on_entity)
	for e in entities.get_children():
		_on_entity(e)
	lighting = EnvironmentController2D.new()
	lighting.name = "Lighting"
	lighting.indoor = indoor
	add_child(lighting)
	for l: TileMapLayer in layers:
		var ts := l.tile_set
		if ts == null or ts.get_custom_data_layer_by_name("solid_cells") < 0:
			continue
		for c in l.get_used_cells():
			var td := l.get_cell_tile_data(c)
			if td == null:
				continue
			for o: Vector2i in td.get_custom_data("solid_cells"):
				_solid[c + Vector2i(o.x, -o.y)] = true
			var lamp := int(td.get_custom_data("lamp"))
			if lamp > 0:
				var src := ts.get_source(l.get_cell_source_id(c)) as TileSetAtlasSource
				var w := src.get_tile_size_in_atlas(l.get_cell_atlas_coords(c)).x
				lighting.add_lamp(Vector2(c.x * cell + w * cell * 0.5, (c.y + 1) * cell - lamp), 1.6, 160.0)
	var signs := get_node_or_null("Signs")
	if signs != null:
		for it in signs.get_children():
			var at := tile_of((it as Node2D).position)
			if it is Interactable:
				_signs[at] = it
				continue
			var to := str(it.get_meta(&"to", ""))
			var to_spawn := str(it.get_meta(&"spawn", "default"))
			if to != "":
				_warps[at] = {"map": to, "spawn": to_spawn}
			if it.has_meta(&"label"):
				_sign(at, str(it.get_meta(&"prompt", "Look")), str(it.get_meta(&"label")), str(it.get_meta(&"dialogue", "")), to, to_spawn)
	if get_parent() == get_tree().root:
		_play_alone.call_deferred()


## The scene was run directly: walk it without the rest of the game.
func _play_alone() -> void:
	InputSetup.ensure()
	var p := GridPlayer.new()
	entities.add_child(p)
	p.position = spawn_position("default")
	p.setup(null, self)
	p.place(tile_of(p.position), spawn_facing("default"))
	player = p


## People on this map are drawn at twice their sheet size (see the header).
func _on_entity(n: Node) -> void:
	if n is GridPlayer and player_sheet != "" and (n as GridPlayer).sprite == null:
		(n as GridPlayer).sheet_id = player_sheet  # before its _ready builds the sprite
	if n is GridActor:
		_fit.call_deferred(n)


func _fit(a: GridActor) -> void:
	if is_instance_valid(a) and a.sprite != null:
		a.sprite.scale = Vector2(actor_scale, actor_scale)


func foot(t: Vector2i) -> Vector2:
	return Vector2(t.x * cell + cell * 0.5, t.y * cell + cell - 1)


func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / cell), floori((p.y - 1) / cell))
