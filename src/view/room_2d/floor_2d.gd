extends Node2D
## Floorboards for the room's walkable footprint.
##
## The visible floor is the walkable area grown by half a unit so boards run
## under the furniture and up to the skirting. Drawn as one node rather than one
## node per plank — a room is a few hundred triangles, not a few hundred nodes.

const OVERHANG := 0.5      ## Grow walkable rects to reach the walls
const THICKNESS := 0.42    ## Visible slab depth on the open edges

var _rects: Array[Rect2] = []


func setup(room: RoomModel) -> void:
	z_index = -2500
	_rects.clear()
	for r in room.walk_rects:
		_rects.append(r.grow(OVERHANG))
	queue_redraw()


func _draw() -> void:
	# Skirts first; interior ones are painted over by the boards that follow.
	for r in _rects:
		_slab_edges(r)
	for r in _rects:
		_boards(r)


func _slab_edges(r: Rect2) -> void:
	var edge_base: Color = Palette.WOOD["right"]
	var lip_base: Color = Palette.WOOD["left"]
	var edge_col := edge_base.darkened(0.35)
	var lip_col := lip_base.darkened(0.15)

	# +X edge (falls away to the lower right of screen).
	draw_colored_polygon(PackedVector2Array([
		Iso.to_screen(Vector3(r.end.x, 0, r.position.y)),
		Iso.to_screen(Vector3(r.end.x, 0, r.end.y)),
		Iso.to_screen(Vector3(r.end.x, -THICKNESS, r.end.y)),
		Iso.to_screen(Vector3(r.end.x, -THICKNESS, r.position.y)),
	]), edge_col)

	# +Z edge (falls away to the lower left of screen).
	draw_colored_polygon(PackedVector2Array([
		Iso.to_screen(Vector3(r.position.x, 0, r.end.y)),
		Iso.to_screen(Vector3(r.end.x, 0, r.end.y)),
		Iso.to_screen(Vector3(r.end.x, -THICKNESS, r.end.y)),
		Iso.to_screen(Vector3(r.position.x, -THICKNESS, r.end.y)),
	]), lip_col)


func _boards(r: Rect2) -> void:
	var z := r.position.y
	var i := 0
	while z < r.end.y - 0.001:
		var depth := minf(1.0, r.end.y - z)
		var col: Color = Palette.WOOD["floor_a"] if i % 2 == 0 else Palette.WOOD["floor_b"]
		# Slight per-board variation stops the grid reading as a checkerboard.
		col = col.lightened(0.03 * float((i * 7) % 3))
		draw_colored_polygon(Iso.top_face(
			Vector3(r.position.x, 0, z), Vector3(r.size.x, 0, depth)
		), col)
		# Board seam.
		draw_line(
			Iso.to_screen(Vector3(r.position.x, 0.001, z)),
			Iso.to_screen(Vector3(r.end.x, 0.001, z)),
			Color(0, 0, 0, 0.18), 1.0
		)
		z += depth
		i += 1
