extends Control
## Possession readout for the hub HUD.
##
## Violet fill = how cursed the flat currently is. The mint tick marks the level
## a cleanse would bring it back to, so the two spectral colours keep their
## meanings and never just decorate.

const HEIGHT := 14.0

var _shown := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(180, HEIGHT + 22.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shown = GameState.possession
	GameState.possession_changed.connect(func(_v): set_process(true))
	set_process(true)


func _process(delta: float) -> void:
	var target := GameState.possession
	_shown = move_toward(_shown, target, delta * 0.8)
	queue_redraw()
	if is_equal_approx(_shown, target):
		set_process(false)


func _draw() -> void:
	var font := NNFonts.or_default(NNFonts.mono(), self)
	var fs: int = Tokens.TYPE["meta"]
	draw_string(font, Vector2(0, fs), "POSSESSION", HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		Palette.HEARTH_CREAM * Color(1, 1, 1, 0.7))

	var bar := Rect2(Vector2(0, fs + 8.0), Vector2(size.x, HEIGHT))
	draw_colored_polygon(_at(RuinedShape.frame(bar.size, 5.0), bar.position),
		Palette.MIDNIGHT_INK * Color(1, 1, 1, 0.85))

	if _shown > 0.01:
		var fill := Vector2(maxf(bar.size.x * _shown, 8.0), bar.size.y)
		draw_colored_polygon(_at(RuinedShape.frame(fill, 5.0), bar.position),
			Palette.POSSESSED_VIOLET)

	draw_polyline(_at(RuinedShape.outline(bar.size, 5.0), bar.position),
		Palette.HEARTH_CREAM * Color(1, 1, 1, 0.35), 2.0, true)

	# Mint tick: where a successful cleanse would land it.
	var tick_x := bar.position.x + bar.size.x * maxf(_shown - 0.2, 0.0)
	draw_line(Vector2(tick_x, bar.position.y - 3.0),
		Vector2(tick_x, bar.end.y + 3.0), Palette.SPECTRAL_MINT, 2.0)


func _at(poly: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + offset)
	return out
