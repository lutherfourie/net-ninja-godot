extends Control
## The "you can touch this" bubble.
##
## Follows the dialogue-bubble rules: separate tail, 24 px padding, no baked
## text. Amber border because amber invites action.

const PAD := 18.0

var _label := ""
var _target := Vector2.ZERO
var _shown := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0


func show_for(label: String, screen_position: Vector2) -> void:
	if label == _label and _shown:
		_target = screen_position
		queue_redraw()
		return
	_label = label
	_target = screen_position
	_shown = true
	queue_redraw()
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)


func clear() -> void:
	if not _shown:
		return
	_shown = false
	create_tween().tween_property(self, "modulate:a", 0.0, 0.12)


func track(screen_position: Vector2) -> void:
	if _shown and not _target.is_equal_approx(screen_position):
		_target = screen_position
		queue_redraw()


func _draw() -> void:
	if _label == "":
		return
	var font := NNFonts.or_default(NNFonts.ui(), self)
	var fs: int = Tokens.TYPE["body"]
	var hint := "E"
	if DisplayServer.is_touchscreen_available():
		hint = "TAP"

	var text_w := font.get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var badge_w := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 22.0
	var w := text_w + badge_w + PAD * 3.0
	var h := fs + PAD * 2.0

	var vp := get_viewport_rect().size
	var at := Vector2(
		clampf(_target.x - w * 0.5, 12.0, maxf(12.0, vp.x - w - 12.0)),
		clampf(_target.y - h - 26.0, 12.0, maxf(12.0, vp.y - h - 12.0))
	)

	draw_set_transform(at, 0.0, Vector2.ONE)
	var cut: float = Tokens.CORNER_CUT * 0.8
	var body := Vector2(w, h)

	for layer: Dictionary in RuinedShape.shadow_layers(body, cut):
		var poly: PackedVector2Array = layer["poly"]
		var a: float = layer["alpha"]
		draw_colored_polygon(poly, Color(0, 0, 0, a))

	draw_colored_polygon(RuinedShape.bubble_tail(body), Palette.CHARCOAL_PLUM)
	draw_colored_polygon(RuinedShape.bubble(body, cut), Palette.CHARCOAL_PLUM)
	draw_polyline(RuinedShape.outline(body, cut), Palette.WARM_AMBER, Tokens.BORDER_WIDTH, true)

	var baseline := h * 0.5 + font.get_ascent(fs) * 0.5 - font.get_descent(fs) * 0.5
	draw_string(font, Vector2(PAD, baseline), _label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.HEARTH_CREAM)

	# Input badge.
	var badge := Rect2(Vector2(w - badge_w - PAD, (h - fs - 10.0) * 0.5),
		Vector2(badge_w, fs + 10.0))
	draw_colored_polygon(_offset(RuinedShape.frame(badge.size, 6.0), badge.position),
		Palette.WARM_AMBER)
	draw_string(font, badge.position + Vector2(11.0, badge.size.y * 0.74), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.MIDNIGHT_INK)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _offset(poly: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + by)
	return out
