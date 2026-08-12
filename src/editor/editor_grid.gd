extends Node2D
## Ground-truth overlay for the editor: unit grid, walkable area, spawn, bounds.
##
## Sits above the floor and rugs but below furniture, so the grid reads as
## painted on the floorboards rather than floating over the room.

var room: RoomModel


func _ready() -> void:
	z_index = -1900


func set_room(r: RoomModel) -> void:
	room = r
	queue_redraw()


func _draw() -> void:
	if room == null:
		return
	var line: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.10)
	var major: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.20)

	# Unit grid across the bounds.
	for x in range(0, int(room.bounds.x) + 1):
		draw_line(
			Iso.to_screen(Vector3(x, 0.01, 0)),
			Iso.to_screen(Vector3(x, 0.01, room.bounds.z)),
			major if x % 5 == 0 else line, 1.0)
	for z in range(0, int(room.bounds.z) + 1):
		draw_line(
			Iso.to_screen(Vector3(0, 0.01, z)),
			Iso.to_screen(Vector3(room.bounds.x, 0.01, z)),
			major if z % 5 == 0 else line, 1.0)

	# Walkable rects in mint — mint confirms, and here it confirms "Ami fits".
	for r in room.walk_rects:
		var quad := PackedVector2Array([
			Iso.to_screen(Vector3(r.position.x, 0.02, r.position.y)),
			Iso.to_screen(Vector3(r.end.x, 0.02, r.position.y)),
			Iso.to_screen(Vector3(r.end.x, 0.02, r.end.y)),
			Iso.to_screen(Vector3(r.position.x, 0.02, r.end.y)),
		])
		quad.append(quad[0])
		draw_polyline(quad, Palette.SPECTRAL_MINT * Color(1, 1, 1, 0.5), 2.0, true)

	# Spawn marker.
	var s := Iso.to_screen(room.spawn)
	draw_arc(s, 12.0, 0, TAU, 20, Palette.DUSTY_ROSE, 2.5)
	draw_line(s + Vector2(0, -18), s + Vector2(0, -4), Palette.DUSTY_ROSE, 2.5)
