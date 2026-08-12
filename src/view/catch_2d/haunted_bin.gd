extends Node2D
## The can. Trash at the edge.
##
## Hooded on purpose: nothing can fall straight in, so the only way to make
## progress is to load the net and carry it over. That is what keeps the loop a
## loop instead of a shooting gallery.

var _flash := 0.0
var _lid := 0.0


func _ready() -> void:
	z_index = 4
	_build_collision()


func _build_collision() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = Playfield.LAYER_SOLID
	solid.collision_mask = 0
	add_child(solid)

	# Sloped hood, so a stray ball rolls back into play rather than resting here.
	var hood := CollisionShape2D.new()
	var hood_shape := RectangleShape2D.new()
	hood_shape.size = Vector2(Playfield.BIN.size.x + 8.0, 16.0)
	hood.shape = hood_shape
	hood.position = Playfield.BIN.position + Vector2(Playfield.BIN.size.x * 0.5, -6.0)
	hood.rotation = -0.20
	solid.add_child(hood)


## Called when a dump lands, sized by how much bar it bought.
func celebrate(strength: float) -> void:
	_flash = clampf(0.5 + strength * 6.0, 0.5, 1.0)
	_lid = 1.0
	set_process(true)


func mouth() -> Vector2:
	return Playfield.BIN.position + Vector2(Playfield.BIN.size.x * 0.5, 6.0)


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 1.6, 0.0)
	_lid = maxf(_lid - delta * 2.2, 0.0)
	queue_redraw()
	if _flash <= 0.0 and _lid <= 0.0:
		set_process(false)


func _draw() -> void:
	var r: Rect2 = Playfield.BIN
	var body: Color = Palette.CHARCOAL_PLUM.lightened(0.06)
	var rim: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.5)

	# Can body, tapering slightly so it reads as a bin and not a box.
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(10, 0),
		r.position + Vector2(r.size.x - 10, 0),
		r.position + Vector2(r.size.x - 22, r.size.y),
		r.position + Vector2(22, r.size.y),
	]), body)

	# Mint glow from inside — the can is where cleansing happens.
	var inner: Color = Palette.SPECTRAL_MINT
	inner.a = 0.14 + _flash * 0.55
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(18, 6),
		r.position + Vector2(r.size.x - 18, 6),
		r.position + Vector2(r.size.x - 26, r.size.y * 0.45),
		r.position + Vector2(26, r.size.y * 0.45),
	]), inner)

	for i in 3:
		var y := r.position.y + 34.0 + i * 32.0
		draw_line(Vector2(r.position.x + 20, y), Vector2(r.end.x - 20, y),
			Color(0, 0, 0, 0.20), 3.0)

	# Hood, hinged open a crack when something just went in.
	var hinge := r.position + Vector2(-14, 2)
	draw_set_transform(hinge, -0.20 - _lid * 0.34, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -12), Vector2(r.size.x + 8, -12),
		Vector2(r.size.x + 8, 6), Vector2(0, 6),
	]), body.lightened(0.16))
	draw_line(Vector2(0, -12), Vector2(r.size.x + 8, -12), rim, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _flash > 0.0:
		var burst: Color = Palette.SPECTRAL_MINT
		burst.a = _flash * 0.7
		draw_arc(mouth(), 40.0 + (1.0 - _flash) * 120.0, PI, TAU, 28, burst, 5.0 * _flash + 1.0)
