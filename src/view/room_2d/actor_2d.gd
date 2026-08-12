extends Node2D
## Ami, drawn procedurally.
##
## Identity lock (PDF p.9): shoulder-length black hair, warm brown eyes, compact
## silhouette, calm confidence. The prototype only has to protect the silhouette
## and the proportions — the moment real character art lands, this becomes a
## sprite with the same anchor point and the same 1.65-unit height.

const HEIGHT_UNITS := 1.65
const SKIN := Color("e8c3a4")
const HAIR := Color("1c1720")
const OUTFIT := Color("221c2b")
const HOODIE := Color("4a3d57")

var world := Vector3.ZERO
var facing := Vector2(0, 1)
var moving := false
var travel := 0.0


func sync(p: Vector3, f: Vector2, is_moving: bool, walked: float) -> void:
	world = p
	facing = f
	moving = is_moving
	travel = walked
	position = Vector2.ZERO
	z_index = Iso.depth_to_z_index(Iso.depth(p, Vector3(0.4, HEIGHT_UNITS, 0.4)))
	queue_redraw()


## Screen-space direction Ami is looking, used to decide whether we see her face.
func _screen_facing() -> Vector2:
	var d := Iso.to_screen(Vector3(facing.x, 0, facing.y)) - Iso.to_screen(Vector3.ZERO)
	return d.normalized() if d.length_squared() > 0.0001 else Vector2(0, 1)


func _draw() -> void:
	var feet := Iso.to_screen(world)
	var sd := _screen_facing()
	var toward_camera := sd.y >= 0.0
	var lean := sd.x * 2.0
	var bob := 0.0
	if moving and not GameState.get_setting("reduce_motion", false):
		bob = sin(travel * 7.0) * 1.8

	draw_set_transform(feet + Vector2(0, bob), 0.0, Vector2.ONE)

	# Contact shadow — "simple shadow language" from the style page.
	draw_set_transform(feet, 0.0, Vector2.ONE)
	_ellipse(Vector2(0, 0), 15.0, 7.5, Color(0.04, 0.03, 0.07, 0.42))

	draw_set_transform(feet + Vector2(0, bob), 0.0, Vector2.ONE)

	var h := HEIGHT_UNITS * Iso.TILE_Z  # total pixel height

	# Legs.
	var stride := 0.0
	if moving:
		stride = sin(travel * 7.0) * 3.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6 + stride * 0.4, 0), Vector2(-2 + stride * 0.4, 0),
		Vector2(-2, -h * 0.42), Vector2(-6, -h * 0.42)]), OUTFIT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(2 - stride * 0.4, 0), Vector2(6 - stride * 0.4, 0),
		Vector2(6, -h * 0.42), Vector2(2, -h * 0.42)]), OUTFIT)

	# Torso in the oversized hoodie: wider at the hem, soft shoulders.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9 + lean, -h * 0.38),
		Vector2(9 + lean, -h * 0.38),
		Vector2(8 + lean, -h * 0.72),
		Vector2(-8 + lean, -h * 0.72),
	]), HOODIE)
	# Hood bunched at the neck.
	_ellipse(Vector2(lean, -h * 0.71), 9.5, 4.5, HOODIE.lightened(0.08))
	# Drawstring / trim in human warmth.
	draw_line(Vector2(-3 + lean, -h * 0.68), Vector2(-3 + lean, -h * 0.58),
		Palette.DUSTY_ROSE, 1.6)
	draw_line(Vector2(3 + lean, -h * 0.68), Vector2(3 + lean, -h * 0.58),
		Palette.DUSTY_ROSE, 1.6)

	# Head.
	var head_y := -h * 0.86
	_ellipse(Vector2(lean, head_y), 8.0, 8.8, SKIN)

	# Hair: shoulder-length, reads as one shape at thumbnail size.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.2 + lean, head_y - 3.0),
		Vector2(-8.2 + lean, head_y + 11.0),
		Vector2(-4.6 + lean, head_y + 11.0),
		Vector2(-5.0 + lean, head_y - 1.0),
	]), HAIR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(9.2 + lean, head_y - 3.0),
		Vector2(8.2 + lean, head_y + 11.0),
		Vector2(4.6 + lean, head_y + 11.0),
		Vector2(5.0 + lean, head_y - 1.0),
	]), HAIR)
	# Fringe: wide enough to meet the side lengths, high enough to leave a face.
	_ellipse(Vector2(lean, head_y - 3.6), 9.4, 6.2, HAIR)
	if not toward_camera:
		# Back of the head: hair covers the face entirely.
		_ellipse(Vector2(lean, head_y + 0.5), 8.4, 8.2, HAIR)
	else:
		# Warm brown eyes, sitting just below the fringe. Two dots is enough to
		# hold the read at 48 px.
		draw_circle(Vector2(-3.2 + lean + sd.x * 1.4, head_y + 4.0), 1.6, Color("4a2f22"))
		draw_circle(Vector2(3.2 + lean + sd.x * 1.4, head_y + 4.0), 1.6, Color("4a2f22"))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	const STEPS := 18
	for i in STEPS:
		var a := TAU * (float(i) / STEPS)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
