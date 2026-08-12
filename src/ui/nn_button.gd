class_name NNButton
extends BaseButton
## The Net Ninja call to action.
##
## Ruined edges signal action (PDF p.8). One primary per screen — the class does
## not enforce that, but `variant` makes violations obvious in a scene tree.

enum Variant {
	PRIMARY,   ## Warm amber. Exactly one per screen.
	SECONDARY, ## Charcoal plum panel with a cream border.
	GHOST,     ## Border only. Settings, back, accessibility.
}

@export var text: String = "START GAME":
	set(value):
		text = value
		queue_redraw()

@export var variant: Variant = Variant.PRIMARY:
	set(value):
		variant = value
		queue_redraw()

## Defaults to Tokens.TYPE["cta"] (26 px). Literal here so the editor can read
## the property default without instantiating the autoloads.
@export var font_size: int = 26:
	set(value):
		font_size = value
		queue_redraw()

## Draw the two cat-ear peaks. Off for dense lists.
@export var ears: bool = true:
	set(value):
		ears = value
		queue_redraw()

var _hover := 0.0


func _init() -> void:
	# No minimum size on purpose: the CTA floor (64 px) belongs to the screen
	# doing the layout, and a hard minimum here silently clips small ghost
	# buttons like MENU and SETTINGS.
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	mouse_entered.connect(func(): _tween_hover(1.0))
	mouse_exited.connect(func(): _tween_hover(0.0))
	focus_entered.connect(func(): _tween_hover(1.0))
	focus_exited.connect(func(): _tween_hover(0.0))
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _tween_hover(to: float) -> void:
	var t := create_tween()
	t.tween_method(func(v: float): _hover = v; queue_redraw(), _hover, to, 0.12)


func _colours() -> Dictionary:
	match variant:
		Variant.PRIMARY:
			return {
				"fill": Palette.WARM_AMBER,
				"border": Palette.MIDNIGHT_INK,
				"label": Palette.MIDNIGHT_INK,
			}
		Variant.SECONDARY:
			return {
				"fill": Palette.CHARCOAL_PLUM,
				"border": Palette.HEARTH_CREAM,
				"label": Palette.HEARTH_CREAM,
			}
		_:
			return {
				"fill": Color(0, 0, 0, 0),
				"border": Palette.HEARTH_CREAM,
				"label": Palette.HEARTH_CREAM,
			}


func _draw() -> void:
	var col := _colours()
	var s := size
	var cut: float = Tokens.CORNER_CUT
	var offset := Tokens.PRESSED_OFFSET if button_pressed else Vector2.ZERO
	var alpha := Tokens.DISABLED_ALPHA if disabled else 1.0

	draw_set_transform(offset, 0.0, Vector2.ONE)

	# Shadow sits under the resting button only; pressing moves the button into it.
	if not button_pressed and not disabled:
		for layer: Dictionary in RuinedShape.shadow_layers(s, cut):
			var poly: PackedVector2Array = layer["poly"]
			var a: float = layer["alpha"]
			draw_colored_polygon(poly, Color(0, 0, 0, a))

	var fill: Color = col["fill"]
	if fill.a > 0.0:
		fill = fill.lightened(_hover * 0.12)
		fill.a *= alpha
		if ears:
			for ear in RuinedShape.ears(s, cut):
				draw_colored_polygon(ear, fill)
		draw_colored_polygon(RuinedShape.frame(s, cut), fill)

	var border: Color = col["border"]
	border.a *= alpha
	draw_polyline(RuinedShape.outline(s, cut), border, Tokens.BORDER_WIDTH, true)

	var font := NNFonts.or_default(NNFonts.heading(), self)
	var label: Color = col["label"]
	label.a *= alpha
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var at := Vector2(
		(s.x - text_size.x) * 0.5,
		(s.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
