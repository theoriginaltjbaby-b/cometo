@tool
extends Node2D
## PROVISIONAL ART. Ground painting for Anjabi / Collapsed Mine (location 04), drawn once.
## Layout follows Greybox Study 01: stairs down from the Estate (north-west), a walled
## yard on a cliff ledge, a path east toward the airpad, and a drop to the south.

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var earth := Color(0.17, 0.22, 0.2)
	var gravel := Color(0.27, 0.29, 0.3)
	var mud := Color(0.29, 0.26, 0.23)
	var rock := Color(0.17, 0.2, 0.22)
	draw_rect(Rect2(0, 0, 960, 704), earth)
	draw_rect(Rect2(900, 0, 60, 704), Color(0.08, 0.14, 0.13))
	draw_rect(Rect2(0, 0, 112, 704), rock)
	# inner yard and the corridor behind the washout
	draw_rect(Rect2(200, 106, 700, 144), gravel)
	draw_rect(Rect2(742, 250, 158, 50), gravel)
	draw_rect(Rect2(456, 106, 48, 144), mud.darkened(0.12))
	# stairs down from the Estate
	var stone := Color(0.4, 0.4, 0.38)
	draw_rect(Rect2(122, 0, 76, 252), stone)
	for i in 38:
		draw_line(Vector2(122, 16 + i * 6), Vector2(198, 16 + i * 6), stone.darkened(0.3), 1.0)
	draw_rect(Rect2(122, 0, 2, 252), stone.darkened(0.45))
	draw_rect(Rect2(196, 0, 2, 252), stone.darkened(0.45))
	# landing, path to the gate, haul road, wash-house apron, path east to the airpad
	draw_rect(Rect2(116, 250, 90, 44), mud)
	draw_colored_polygon(PackedVector2Array([Vector2(200, 258), Vector2(454, 254), Vector2(454, 292), Vector2(200, 294)]), mud)
	draw_colored_polygon(PackedVector2Array([Vector2(450, 690), Vector2(510, 690), Vector2(506, 250), Vector2(454, 250)]), mud)
	draw_colored_polygon(PackedVector2Array([Vector2(150, 596), Vector2(452, 584), Vector2(452, 620), Vector2(150, 628)]), mud.darkened(0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(508, 626), Vector2(900, 630), Vector2(900, 662), Vector2(508, 658)]), mud.darkened(0.05))
	draw_rect(Rect2(762, 340, 126, 46), Color(0.21, 0.25, 0.23))
	for x: float in [466.0, 494.0]:
		draw_line(Vector2(x, 690), Vector2(x, 250), mud.darkened(0.22), 2.0)
	# the drop to the south: rock lip, then mist
	draw_rect(Rect2(0, 690, 960, 14), rock.darkened(0.25))
	for i in 5:
		draw_rect(Rect2(0, 694 + i * 2, 960, 2), Color(0.45, 0.52, 0.58, 0.1 + i * 0.07))
	# puddles
	for p: Vector3 in [Vector3(472, 470, 9), Vector3(492, 360, 7), Vector3(470, 620, 11), Vector3(640, 644, 8),
			Vector3(330, 606, 7), Vector3(300, 170, 10), Vector3(640, 200, 8), Vector3(820, 270, 6),
			Vector3(480, 180, 9), Vector3(160, 272, 8)]:
		draw_set_transform(Vector2(p.x, p.y), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, p.z, Color(0.33, 0.42, 0.5, 0.85))
		draw_circle(Vector2(-p.z * 0.3, -p.z * 0.2), p.z * 0.35, Color(0.5, 0.6, 0.68, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# gravel flecks, weeds, rock cracks
	for i in 900:
		var p := Vector2(rng.randf_range(114, 898), rng.randf_range(108, 688))
		if p.x < 200 and p.y < 252:
			continue
		var on_road := p.x > 448 and p.x < 512
		if p.y < 250 or (p.x > 742 and p.y < 300):
			draw_rect(Rect2(p, Vector2(1, 1)), gravel.lightened(rng.randf_range(-0.15, 0.2)))
		elif not on_road:
			var c := earth.lightened(rng.randf_range(0.02, 0.14))
			draw_line(p, p + Vector2(rng.randf_range(-1, 1), -rng.randf_range(2, 4)), c, 1.0)
	for i in 60:
		var p := Vector2(rng.randf_range(4, 104), rng.randf_range(4, 700))
		draw_line(p, p + Vector2(rng.randf_range(-6, 6), rng.randf_range(6, 18)), rock.lightened(0.08), 1.0)
