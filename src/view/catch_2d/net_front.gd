extends Node2D
## The near side of the net's mesh, drawn *over* the balls.
##
## Without this the catch reads as balls floating in front of a net instead of
## balls sitting in one. It is the cheapest possible depth cue and it does all
## the work: back ropes behind, spheres between, front mesh in front.

var net: Node2D  ## the NetBody this belongs to


func _ready() -> void:
	z_index = 6
	top_level = false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if net == null:
		return
	var half: float = Playfield.NET_HALF_W
	var depth: float = Playfield.NET_DEPTH
	var mesh: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.30)

	draw_set_transform(Vector2.ZERO, net.lean(), Vector2.ONE)

	var left_top := Vector2(-half, -6)
	var right_top := Vector2(half, -6)
	var left_bottom := Vector2(-half + 8, depth)
	var right_bottom := Vector2(half - 8, depth)

	for i in 6:
		var t := float(i) / 5.0
		draw_line(left_top.lerp(right_top, t) + Vector2(0, 6),
			left_bottom.lerp(right_bottom, t), mesh, 1.8)
	for i in 5:
		var t := 0.18 + float(i) / 6.0
		draw_line(left_top.lerp(left_bottom, t), right_top.lerp(right_bottom, t), mesh, 1.4)

	# Front lip, so the mouth of the net has a clear edge.
	draw_line(Vector2(-half - 6, -6), Vector2(half + 6, -6),
		Palette.HEARTH_CREAM * Color(1, 1, 1, 0.75), 4.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
