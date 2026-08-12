extends Node2D
## The room, seen from inside the fight.
##
## Deliberately quiet: this is the 55% dark neutrals the colour system asks for,
## so that a single mint ball or one violet shockwave still counts as an event.
## The two flash channels are how the screen reacts — violet on a slam, coral on
## a drop — without moving the camera, which would fight the physics read.

var _slam := 0.0
var _drop := 0.0


func set_flashes(slam: float, drop: float) -> void:
	if is_equal_approx(slam, _slam) and is_equal_approx(drop, _drop):
		return
	_slam = slam
	_drop = drop
	queue_redraw()


func _draw() -> void:
	var w: float = Playfield.WIDTH
	var h: float = Playfield.HEIGHT

	draw_rect(Rect2(-40, -40, w + 80, h + 80), Palette.MIDNIGHT_INK)

	# Wall above the skirting, floor below it — enough to say "still her flat".
	var floor_top: float = Playfield.FLOOR_Y - 88.0
	draw_polygon(
		PackedVector2Array([Vector2(-40, -40), Vector2(w + 40, -40),
			Vector2(w + 40, floor_top), Vector2(-40, floor_top)]),
		PackedColorArray([
			Palette.CHARCOAL_PLUM.darkened(0.30), Palette.CHARCOAL_PLUM.darkened(0.30),
			Palette.CHARCOAL_PLUM.lightened(0.04), Palette.CHARCOAL_PLUM.lightened(0.04)])
	)
	draw_rect(Rect2(-40, floor_top, w + 80, h - floor_top + 40), Color("53341f"))
	draw_line(Vector2(-40, floor_top), Vector2(w + 40, floor_top),
		Color(0, 0, 0, 0.45), 5.0)
	for i in 5:
		var y := floor_top + 26.0 + i * 34.0
		draw_line(Vector2(-40, y), Vector2(w + 40, y), Color(0, 0, 0, 0.13), 3.0)

	# The rail the net hangs from.
	draw_line(Vector2(-40, Playfield.RAIL_Y - 236.0), Vector2(w + 40, Playfield.RAIL_Y - 236.0),
		Palette.CHARCOAL_PLUM.lightened(0.22), 8.0)

	if _slam > 0.0:
		var v: Color = Palette.POSSESSED_VIOLET
		v.a = _slam * 0.16
		draw_rect(Rect2(-40, -40, w + 80, h + 80), v)
	if _drop > 0.0:
		var c: Color = Palette.WARNING_CORAL
		c.a = _drop * 0.20
		draw_rect(Rect2(-40, Playfield.FLOOR_Y - 150.0, w + 80, 200.0), c)
		c.a = _drop * 0.75
		draw_line(Vector2(-40, Playfield.FLOOR_Y), Vector2(w + 40, Playfield.FLOOR_Y), c, 6.0)
