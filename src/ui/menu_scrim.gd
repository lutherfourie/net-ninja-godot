extends Control
## Dim + vignette over the live room backdrop.
##
## The menu needs the room readable but never competing with the logo or the CTA.
## Straight alpha alone flattens it, so this adds a soft edge falloff that pushes
## attention into the focal zone.

@export var dim: float = 0.42


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(
		Palette.MIDNIGHT_INK.r, Palette.MIDNIGHT_INK.g, Palette.MIDNIGHT_INK.b, dim))

	# Vignette as four edge gradients — cheap, and it survives any aspect ratio.
	var band := s.y * 0.22
	var ink: Color = Palette.MIDNIGHT_INK
	_gradient_rect(Rect2(0, 0, s.x, band), Color(ink.r, ink.g, ink.b, 0.75), true)
	_gradient_rect(Rect2(0, s.y - band, s.x, band), Color(ink.r, ink.g, ink.b, 0.88), false)


func _gradient_rect(r: Rect2, col: Color, fade_down: bool) -> void:
	var top := col
	var bottom := Color(col.r, col.g, col.b, 0.0)
	if not fade_down:
		var swap := top
		top = bottom
		bottom = swap
	draw_polygon(
		PackedVector2Array([
			r.position, Vector2(r.end.x, r.position.y),
			r.end, Vector2(r.position.x, r.end.y)
		]),
		PackedColorArray([top, top, bottom, bottom])
	)
