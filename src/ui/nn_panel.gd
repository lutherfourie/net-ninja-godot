class_name NNPanel
extends Control
## Dark surface with a 2 px state border and flat hierarchy — the PC/email panel
## language from PDF p.6, reused for settings and the interaction prompt.

enum State { NEUTRAL, CURSED, CLEANSED, DANGER }

@export var title: String = ""
@export var state: State = State.NEUTRAL:
	set(value):
		state = value
		queue_redraw()

## Palette.CHARCOAL_PLUM, inlined so the editor can read the default without
## instantiating autoloads.
@export var fill_color: Color = Color("2a2032"):
	set(value):
		fill_color = value
		queue_redraw()

@export var show_shadow: bool = true


func border_colour() -> Color:
	match state:
		State.CURSED: return Palette.POSSESSED_VIOLET
		State.CLEANSED: return Palette.SPECTRAL_MINT
		State.DANGER: return Palette.WARNING_CORAL
		_: return Palette.HEARTH_CREAM * Color(1, 1, 1, 0.45)


func _draw() -> void:
	var cut: float = Tokens.CORNER_CUT
	if show_shadow:
		for layer: Dictionary in RuinedShape.shadow_layers(size, cut):
			var poly: PackedVector2Array = layer["poly"]
			var a: float = layer["alpha"]
			draw_colored_polygon(poly, Color(0, 0, 0, a))

	draw_colored_polygon(RuinedShape.frame(size, cut), fill_color)
	draw_polyline(RuinedShape.outline(size, cut), border_colour(), Tokens.BORDER_WIDTH, true)

	if title != "":
		var font := NNFonts.or_default(NNFonts.heading(), self)
		var fs: int = Tokens.TYPE["h2"]
		draw_string(font, Vector2(Tokens.BUBBLE_PADDING, Tokens.BUBBLE_PADDING + fs * 0.8),
			title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.HEARTH_CREAM)
