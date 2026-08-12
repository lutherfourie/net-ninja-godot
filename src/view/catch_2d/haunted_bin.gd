extends Node2D
## The can. Trash at the edge — now a real container.
##
## net-lab port: items BANK by physically landing in the bin (world.binX/binY/
## binRadius), and pour is the only deliberate emptying verb. So the hood is
## gone: the can is open-topped with solid walls, and a sensor in its throat
## banks whatever falls in — a poured haul, or a lucky juggle deflection. The
## clamp-up facing rule is what keeps this honest: the bag physically cannot
## tip anywhere else.

signal banked(body: Node)

var _flash := 0.0


func _ready() -> void:
	z_index = 2
	_build_collision()


func _build_collision() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = Playfield.LAYER_SOLID
	solid.collision_mask = 0
	add_child(solid)

	var r: Rect2 = Playfield.BIN
	# Two walls and a floor; the top is open to the sky.
	_wall(solid, Vector2(r.position.x + 8.0, r.position.y + r.size.y * 0.5),
		Vector2(14.0, r.size.y), 0.06)
	_wall(solid, Vector2(r.end.x - 8.0, r.position.y + r.size.y * 0.5),
		Vector2(14.0, r.size.y), -0.06)
	_wall(solid, Vector2(r.position.x + r.size.x * 0.5, r.end.y - 6.0),
		Vector2(r.size.x, 14.0), 0.0)

	# The bank: anything that gets this deep is cleansed.
	var throat := Area2D.new()
	throat.collision_layer = 0
	throat.collision_mask = Playfield.LAYER_BALL
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(r.size.x - 34.0, 46.0)
	shape.shape = rect
	shape.position = r.position + Vector2(r.size.x * 0.5, r.size.y * 0.55)
	throat.add_child(shape)
	throat.body_entered.connect(func(body: Node) -> void: banked.emit(body))
	add_child(throat)


func _wall(parent: StaticBody2D, at: Vector2, size: Vector2, tilt: float) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	shape.rotation = tilt
	parent.add_child(shape)


## Called per banked ball, sized by how much bar it bought.
func celebrate(strength: float) -> void:
	_flash = clampf(_flash + 0.35 + strength * 4.0, 0.4, 1.0)
	set_process(true)


func mouth() -> Vector2:
	return Playfield.BIN.position + Vector2(Playfield.BIN.size.x * 0.5, 6.0)


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 1.6, 0.0)
	queue_redraw()
	if _flash <= 0.0:
		set_process(false)


func _draw() -> void:
	var r: Rect2 = Playfield.BIN
	var body: Color = Palette.CHARCOAL_PLUM.lightened(0.06)
	var rim: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.5)

	# Can body, tapering slightly so it reads as a bin and not a box.
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(2, 0),
		r.position + Vector2(r.size.x - 2, 0),
		r.position + Vector2(r.size.x - 18, r.size.y),
		r.position + Vector2(18, r.size.y),
	]), body)

	# Mint glow from inside — the can is where cleansing happens.
	var inner: Color = Palette.SPECTRAL_MINT
	inner.a = 0.16 + _flash * 0.55
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(14, 4),
		r.position + Vector2(r.size.x - 14, 4),
		r.position + Vector2(r.size.x - 22, r.size.y * 0.5),
		r.position + Vector2(22, r.size.y * 0.5),
	]), inner)

	for i in 3:
		var y := r.position.y + 38.0 + i * 32.0
		draw_line(Vector2(r.position.x + 18, y), Vector2(r.end.x - 18, y),
			Color(0, 0, 0, 0.20), 3.0)

	# Open rim: a bright front lip and a darker back lip — an ellipse read.
	draw_line(r.position + Vector2(0, 2), r.position + Vector2(r.size.x, 2),
		rim * Color(1, 1, 1, 0.6), 3.0)
	draw_line(r.position + Vector2(4, 10), r.position + Vector2(r.size.x - 4, 10),
		rim, 4.0)

	if _flash > 0.0:
		var burst: Color = Palette.SPECTRAL_MINT
		burst.a = _flash * 0.7
		draw_arc(mouth(), 40.0 + (1.0 - _flash) * 110.0, PI, TAU, 28, burst,
			5.0 * _flash + 1.0)
