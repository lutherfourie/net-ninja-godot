class_name NNFonts
extends RefCounted
## Typeface access with graceful degradation.
##
## The type system is Nunito Sans (ExtraBold headings, SemiBold UI/body) plus
## Space Mono for tech data only. Those files are OFL but are not committed —
## run `tools/fetch_fonts.ps1` (or the .sh) once and they land in assets/fonts/.
## If they are missing the project still runs on Godot's default face, so a fresh
## clone is never broken, it is only off-brand.

const DIR := "res://assets/fonts/"

static var _cache := {}


static func heading() -> Font:
	return _weighted(["NunitoSans-ExtraBold.ttf", "NunitoSans-Bold.ttf"], 800)


static func ui() -> Font:
	return _weighted(["NunitoSans-SemiBold.ttf", "NunitoSans-Regular.ttf"], 600)


static func body() -> Font:
	return ui()


static func mono() -> Font:
	return _weighted(["SpaceMono-Regular.ttf"], 400)


## The ruined display face is still to be commissioned (PDF p.5: "Custom
## Ruined-style"). Until then the wordmark leans on ExtraBold plus the procedural
## damage in wordmark.gd, and nothing else is allowed to use it.
static func display() -> Font:
	return heading()


static func has_brand_fonts() -> bool:
	for name in ["NunitoSans-ExtraBold.ttf", "NunitoSans-Variable.ttf"]:
		if FileAccess.file_exists(DIR + name):
			return true
	return false


static func _weighted(candidates: Array, weight: int) -> Font:
	var key := "%s|%d" % [str(candidates), weight]
	if _cache.has(key):
		return _cache[key]

	var font: Font = null
	for name in candidates:
		var path: String = DIR + name
		if FileAccess.file_exists(path):
			var f := FontFile.new()
			var err := f.load_dynamic_font(path)
			if err == OK:
				font = f
				break

	# Variable-font fallback: one file, many weights.
	if font == null:
		var variable := DIR + "NunitoSans-Variable.ttf"
		if FileAccess.file_exists(variable):
			var base := FontFile.new()
			if base.load_dynamic_font(variable) == OK:
				var v := FontVariation.new()
				v.base_font = base
				v.variation_opentype = {"wght": weight}
				font = v

	_cache[key] = font
	return font


## Convenience for _draw code: never returns null.
static func or_default(font: Font, item: CanvasItem) -> Font:
	return font if font != null else item.get_theme_default_font()
