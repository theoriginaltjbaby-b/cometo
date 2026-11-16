extends InteriorMap3D
## Interior of 12 Shop on the Steps (greybox landmark 12). PROVISIONAL dressing; what
## the shop sells and who keeps it are for the director. One room, counter at the back.


func _build() -> void:
	room(Vector3(10, 3.2, 7), ground_mat(Color(0.36, 0.3, 0.25), 0.0, 0.2, 0.0), M.panel)
	# counter along the back, a till on it
	box(Vector3(1.5, 0.55, -2.2), Vector3(4.2, 1.1, 0.8), M.timber)
	box(Vector3(2.6, 1.2, -2.2), Vector3(0.6, 0.2, 0.4), M.steel_dark, false)
	# shelving on both side walls
	for s: float in [-1.0, 1.0]:
		var x := s * 4.55
		box(Vector3(x, 1.1, -0.4), Vector3(0.7, 2.2, 4.4), M.timber)
		for k in 3:
			box(Vector3(x - s * 0.05, 0.45 + k * 0.7, -0.4), Vector3(0.6, 0.06, 4.2), M.steel_dark, false)
		var shelf := Interactable3D.new()
		shelf.prompt = "Look"
		shelf.label = "Shelves"
		shelf.dialogue_id = "anjabi/shop_shelves"
		shelf.radius = 1.4
		shelf.position = Vector3(x - s * 0.8, 0.9, -0.4)
		add_child(shelf)
	model("crate_stack", Vector3(-3.0, 0, -2.6), 0.3)
	model("barrel", Vector3(-1.6, 0, -2.8))
	model("barrel", Vector3(3.9, 0, 2.6))
	model("planter", Vector3(-3.9, 0, 2.7))
	# a rug in the middle
	box(Vector3(0, 0.01, 0.4), Vector3(3.6, 0.02, 2.4), M.canvas_teal, false)
	ceiling_lamp(Vector3(-1.5, 2.9, -0.5))
	ceiling_lamp(Vector3(2.0, 2.9, -1.0))
