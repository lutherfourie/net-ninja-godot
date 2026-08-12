class_name NNWordmark
extends Control
## The NET NINJA logotype, procedurally "ruined".
##
## The real mark is a custom display face that has not been cut yet. Until it is,
## this draws ExtraBold letterforms with hand-placed damage: chipped edges, two
## cat-ear peaks and a violet ghost. Deterministic (fixed RNG seed) so the mark
## never flickers between frames or builds.
##
## Rules that survive the placeholder: minimum digital width 260 px, maximum 54%
## of screen width, clear space equal to the N stem.

const TITLE := "NET NINJA"
const SUBTITLE := "COZY OCCULT"
const TRACKING := 4.0
const SUB_TRACKING := 7.0

@export var show_subtitle: bool = true


func _ready() -> void:
	GameState.setting_changed.connect(func(_k, _v): queue_redraw())


func _draw() -> void:
	var font := NNFonts.or_default(NNFonts.display(), self)
	var target_w := maxf(size.x, Tokens.LOGO_MIN_WIDTH_PX)

	# Fit the mark to the available width, respecting the ruined face floor.
	var probe := 96
	var natural := _measure(font, TITLE, probe, TRACKING)
	var fs := int(clampf(probe * (target_w / maxf(natural, 1.0)), Tokens.RUINED_MIN_SIZE, 140))
	var width := _measure(font, TITLE, fs, TRACKING)
	var origin := Vector2((size.x - width) * 0.5, size.y * 0.62)

	# Cat-ear peaks sitting on the cap line, echoing the button frame.
	var cap := origin.y - font.get_ascent(fs) * 0.92
	var ear_col: Color = Palette.HEARTH_CREAM
	for ratio: float in [0.11, 0.89]:
		var x: float = origin.x + width * ratio
		var w := fs * 0.16
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - w, cap + w * 0.9),
			Vector2(x, cap - w * 1.5),
			Vector2(x + w, cap + w * 0.9),
		]), ear_col)

	# Violet ghost: the curse sitting just behind the name.
	_draw_tracked(font, TITLE, origin + Vector2(3, 4), fs, TRACKING,
		Palette.POSSESSED_VIOLET * Color(1, 1, 1, 0.75))
	_draw_tracked(font, TITLE, origin, fs, TRACKING, Palette.HEARTH_CREAM)

	_chip(origin, width, fs)

	if show_subtitle:
		var sub_font := NNFonts.or_default(NNFonts.mono(), self)
		var sub_size := int(maxf(Tokens.TYPE["meta"], fs * 0.20))
		var sub_w := _measure(sub_font, SUBTITLE, sub_size, SUB_TRACKING)
		var sub_at := Vector2((size.x - sub_w) * 0.5, origin.y + fs * 0.42)
		draw_line(
			Vector2(sub_at.x - 18, sub_at.y - sub_size * 0.35),
			Vector2(sub_at.x - 6, sub_at.y - sub_size * 0.35),
			Palette.SPECTRAL_MINT, 2.0)
		draw_line(
			Vector2(sub_at.x + sub_w + 6, sub_at.y - sub_size * 0.35),
			Vector2(sub_at.x + sub_w + 18, sub_at.y - sub_size * 0.35),
			Palette.SPECTRAL_MINT, 2.0)
		_draw_tracked(sub_font, SUBTITLE, sub_at, sub_size, SUB_TRACKING,
			Palette.HEARTH_CREAM * Color(1, 1, 1, 0.72))


## Bite deterministic notches out of the letterforms so the mark reads handmade
## rather than "bold sans on a dark rectangle".
func _chip(origin: Vector2, width: float, fs: int) -> void:
	if GameState.get_setting("high_contrast", false):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x4E494E4A  # "NINJ"
	# Restrained on purpose: the mark has to stay legible at app-icon size, and
	# the ruin is meant to read as chipped stone, not as damage to the word.
	var top := origin.y - fs * 0.70
	var bottom := origin.y + fs * 0.04
	for i in 6:
		var x := origin.x + rng.randf() * width
		var from_top := rng.randf() < 0.55
		var y := top if from_top else bottom
		var w := fs * rng.randf_range(0.035, 0.075)
		var h := fs * rng.randf_range(0.06, 0.13) * (1.0 if from_top else -1.0)
		# A chip is the background colour painted back over the glyph edge.
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - w, y), Vector2(x + w, y), Vector2(x + w * 0.2, y + h),
		]), Palette.MIDNIGHT_INK)


func _measure(font: Font, text: String, fs: int, tracking: float) -> float:
	var w := 0.0
	for c in text:
		w += font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + tracking
	return maxf(w - tracking, 0.0)


func _draw_tracked(font: Font, text: String, at: Vector2, fs: int, tracking: float, col: Color) -> void:
	var x := at.x
	for c in text:
		draw_string(font, Vector2(x, at.y), c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		x += font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + tracking
