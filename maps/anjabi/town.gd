extends GameMap
## Anjabi, whole settlement, greybox. Ground art and walkable area both come from
## docs/reference/anjabi_greybox_01.png (see tools/build_town_mask.gd).
## Announces the district the player is standing in.

## Image-pixel rectangles on the greybox; first match wins.
const DISTRICTS := [
	["THE STEPS", Rect2(820, 370, 125, 75)],
	["TRAM STATION", Rect2(940, 440, 180, 210)],
	["SHOPS", Rect2(890, 220, 170, 160)],
	["MAIN TAVERN", Rect2(670, 190, 215, 175)],
	["TION TOWER", Rect2(425, 300, 180, 175)],
	["GUARD TOWER", Rect2(930, 40, 210, 165)],
	["WORKER PODS", Rect2(440, 40, 325, 205)],
	["ESTATE GARDENS", Rect2(95, 320, 215, 100)],
	["ESTATE", Rect2(120, 420, 290, 165)],
	["COLLAPSED MINE", Rect2(60, 630, 250, 180)],
	["PRIVATE AIRPAD", Rect2(320, 735, 200, 130)],
	["BEACH", Rect2(500, 560, 430, 175)],
	["DOCKS AND BOARDWALK", Rect2(1060, 360, 320, 215)],
	["RAINFOREST APPROACH", Rect2(1255, 220, 165, 150)],
	["FOREST", Rect2(40, 40, 330, 215)],
]

var _district := ""
var _acc := 0.0

@onready var _mask: WalkMask = $WalkMask


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 0.25 or player == null:
		return
	_acc = 0.0
	var p := (player.global_position - _mask.global_position) / _mask.pixel_size
	var found := ""
	for d: Array in DISTRICTS:
		if (d[1] as Rect2).has_point(p):
			found = d[0]
			break
	if found != _district:
		_district = found
		if found != "":
			GameState.location_entered.emit("ANJABI  ·  " + found)
