extends Control
## Contract HUD: how much is cleansed, how many drops are left, what the net holds.
##
## Three readings, one glance. Mint fills as you win, coral pips vanish as you
## lose, and the net count sits beside the bar so the decision "one more catch or
## dump now?" never needs a second look.

const BAR_H := 18.0

var _cleansed := 0.0
var _shown := 0.0
var _drops := 0
var _limit := 8
var _load := 0
var _capacity := 9


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_cleansed(value: float) -> void:
	_cleansed = clampf(value, 0.0, 1.0)


func set_drops(used: int, limit: int) -> void:
	_drops = used
	_limit = limit
	queue_redraw()


func set_load(count: int, capacity: int) -> void:
	if count == _load:
		return
	_load = count
	_capacity = capacity
	queue_redraw()


func _process(delta: float) -> void:
	if is_equal_approx(_shown, _cleansed):
		return
	_shown = move_toward(_shown, _cleansed, delta * 0.55)
	queue_redraw()


func _draw() -> void:
	var mono := NNFonts.or_default(NNFonts.mono(), self)
	var head := NNFonts.or_default(NNFonts.heading(), self)
	var meta: int = Tokens.TYPE["meta"]
	var dim: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.7)

	# Row 1 — label left, net load right.
	draw_string(mono, Vector2(0, meta), "CLEANSE", HORIZONTAL_ALIGNMENT_LEFT, -1, meta, dim)
	var load_text := "NET %d/%d" % [_load, _capacity]
	var load_w := mono.get_string_size(load_text, HORIZONTAL_ALIGNMENT_LEFT, -1, meta).x
	var load_col: Color = Palette.SPECTRAL_MINT if _load > 0 else dim * Color(1, 1, 1, 0.65)
	if _load >= _capacity:
		load_col = Palette.WARM_AMBER
	draw_string(mono, Vector2(size.x - load_w, meta), load_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, meta, load_col)

	# Row 2 — the bar.
	var bar_at := Vector2(0, meta + 7.0)
	var bar_size := Vector2(size.x, BAR_H)
	draw_colored_polygon(_at(RuinedShape.frame(bar_size, 6.0), bar_at),
		Palette.MIDNIGHT_INK * Color(1, 1, 1, 0.85))
	if _shown > 0.005:
		var fill := Vector2(maxf(bar_size.x * _shown, 10.0), bar_size.y)
		draw_colored_polygon(_at(RuinedShape.frame(fill, 6.0), bar_at), Palette.SPECTRAL_MINT)
	draw_polyline(_at(RuinedShape.outline(bar_size, 6.0), bar_at),
		Palette.HEARTH_CREAM * Color(1, 1, 1, 0.35), 2.0, true)

	# Row 3 — drop pips, filled while you still have them.
	var pip_y := bar_at.y + BAR_H + 15.0
	var remaining := maxi(_limit - _drops, 0)
	var step := minf(20.0, (size.x - 150.0) / maxf(float(_limit), 1.0))
	for i in _limit:
		var cx := 6.0 + i * step
		var pip := PackedVector2Array([
			Vector2(cx, pip_y - 6.0), Vector2(cx + 6.0, pip_y),
			Vector2(cx, pip_y + 6.0), Vector2(cx - 6.0, pip_y),
		])
		if i < remaining:
			draw_colored_polygon(pip, Palette.WARNING_CORAL)
		else:
			var spent := pip.duplicate()
			spent.append(pip[0])
			draw_polyline(spent, Palette.WARNING_CORAL * Color(1, 1, 1, 0.32), 1.8, true)

	var label := "DROPS LEFT"
	if remaining == 0:
		label = "OUT OF DROPS"
	elif remaining <= 3:
		label = "LAST %d" % remaining
	var lw := head.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, meta).x
	var urgent: Color = Palette.WARNING_CORAL if remaining <= 3 else dim * Color(1, 1, 1, 0.8)
	draw_string(head, Vector2(size.x - lw, pip_y + 5.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, meta, urgent)


func _at(poly: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + offset)
	return out
