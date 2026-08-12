extends Node2D
## The threat above.
##
## A silhouette, one spectral hue, no gore — the haunting rules from PDF p.3.
## The whole animation budget goes into the telegraph: eyes flash, paw lifts,
## paw lands. If the player can read the slam coming, losing is their fault,
## which is the only way a drop limit is fair.

const EYE_BASE := Vector2(0, -14.0)

var _t := 0.0
var _paw_x := 0.5
var _telegraph := 0.0   ## 1 -> 0 while winding up
var _impact := 0.0      ## 1 -> 0 after landing
var _eye_flash := 0.0


func _ready() -> void:
	z_index = -4


func telegraph(at_x: float) -> void:
	_paw_x = at_x
	_telegraph = 1.0
	_eye_flash = 1.0


func impact() -> void:
	_telegraph = 0.0
	_impact = 1.0


func paw_point() -> Vector2:
	return Vector2(Playfield.rail_x(_paw_x), Playfield.SPAWN_Y)


func _process(delta: float) -> void:
	var rate := 0.35 if GameState.get_setting("reduce_motion", false) else 1.0
	_t += delta
	if _telegraph > 0.0:
		_telegraph = maxf(_telegraph - delta / maxf(0.42, 0.01), 0.0)
	_impact = maxf(_impact - delta * 2.6 * rate, 0.0)
	_eye_flash = maxf(_eye_flash - delta * 1.4, 0.0)
	queue_redraw()


func _draw() -> void:
	var band: float = Playfield.CAT_BAND
	var w: float = Playfield.WIDTH
	var body: Color = Palette.POSSESSED_VIOLET.darkened(0.62)
	var body_lit: Color = Palette.POSSESSED_VIOLET.darkened(0.46)

	# A ceiling of cat: the mass fills the top of the screen and the readable
	# features hang below the status plate.
	var breath := sin(_t * 1.1) * 4.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-40, -20), Vector2(w + 40, -20),
		Vector2(w + 40, band * 0.58 + breath),
		Vector2(w * 0.76, band * 0.76 + breath),
		Vector2(w * 0.5, band * 0.62 + breath),
		Vector2(w * 0.24, band * 0.78 + breath),
		Vector2(-40, band * 0.56 + breath),
	]), body)

	# Head and ears, placed against CAT_HEAD_Y so the eye line always clears
	# STATUS_BAND. A cropped ear reads as a bug; a hidden eye reads as nothing.
	var head := Vector2(w * 0.5, Playfield.CAT_HEAD_Y + breath)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-148, -26), head + Vector2(-118, -118), head + Vector2(-58, -46)]), body_lit)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(148, -26), head + Vector2(118, -118), head + Vector2(58, -46)]), body_lit)
	draw_colored_polygon(_ellipse(head, 168.0, 86.0), body_lit)

	_draw_eyes(head)
	_draw_paw(band, breath, body_lit)


func _draw_eyes(head: Vector2) -> void:
	# Amber at rest, violet when it is about to move. Colour carries the warning.
	var hue: Color = Palette.WARM_AMBER.lerp(Palette.POSSESSED_VIOLET, 0.16 + _eye_flash * 0.62)
	hue = hue.lerp(Color.WHITE, _eye_flash * 0.45)
	var open := 1.0 + _eye_flash * 0.45
	for side: float in [-1.0, 1.0]:
		var at: Vector2 = head + Vector2(62.0 * side, EYE_BASE.y)
		# Almond, wider than tall, with a vertical slit — cat, not owl.
		draw_colored_polygon(_ellipse(at, 34.0, 24.0 * open), hue)
		draw_colored_polygon(_ellipse(at, 6.0, 20.0 * open), Palette.MIDNIGHT_INK)


func _draw_paw(band: float, breath: float, col: Color) -> void:
	if _telegraph <= 0.0 and _impact <= 0.0:
		return
	var x: float = Playfield.rail_x(_paw_x)
	# Wind up above the band, then punch through it.
	var lift := _telegraph * 104.0
	var y := band * 0.94 + breath - lift + _impact * 26.0

	draw_line(Vector2(x, band * 0.3), Vector2(x, y), col, 52.0)
	draw_colored_polygon(_ellipse(Vector2(x, y), 46.0, 38.0), col.lightened(0.08))
	for i in 3:
		var tx := x - 26.0 + i * 26.0
		draw_colored_polygon(_ellipse(Vector2(tx, y + 26.0), 13.0, 11.0), col.lightened(0.16))

	if _impact > 0.0:
		# Violet shockwave announcing the burst.
		var r := (1.0 - _impact) * 190.0 + 24.0
		var ring: Color = Palette.POSSESSED_VIOLET
		ring.a = _impact * 0.8
		draw_arc(Vector2(x, y + 24.0), r, 0.0, TAU, 40, ring, 6.0 * _impact + 1.0)
		ring.a = _impact * 0.35
		draw_arc(Vector2(x, y + 24.0), r * 0.6, 0.0, TAU, 32, ring, 4.0 * _impact + 1.0)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	const STEPS := 26
	for i in STEPS:
		var a := TAU * (float(i) / STEPS)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
