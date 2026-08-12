extends Node2D
## Draws one PropDef as a shaded isometric solid.
##
## Everything here is procedural on purpose. The prototype's job is to prove
## layout, silhouette and light — not to lock in art. When real sprites arrive,
## this script becomes a thin sprite placer and the room data does not change.

const OUTLINE := Color(0.07, 0.05, 0.10, 0.55)

var prop: PropDef
var highlighted := false:
	set(value):
		if value == highlighted:
			return
		highlighted = value
		queue_redraw()

var _possession := 0.0
var _pulse := 0.0


func setup(p: PropDef) -> void:
	prop = p
	z_index = _sort_index()
	_possession = GameState.possession
	if prop.reacts_to_possession:
		set_process(true)
		GameState.possession_changed.connect(_on_possession)
	else:
		set_process(false)
	queue_redraw()


func _on_possession(level: float) -> void:
	_possession = level
	queue_redraw()


func _process(delta: float) -> void:
	# Only possessed props animate; everything else is static and free.
	_pulse += delta * (1.0 + _possession * 1.8)
	queue_redraw()


func _sort_index() -> int:
	match prop.kind:
		PropDef.Kind.WALL:
			return -3000 + int(prop.origin.x + prop.origin.z)
		PropDef.Kind.FLOOR, PropDef.Kind.RUG:
			return -2000 + Iso.depth_to_z_index(Iso.depth(prop.origin, prop.size)) / 8
		_:
			return Iso.depth_to_z_index(Iso.depth(prop.origin, prop.size))


func _base_colour() -> Color:
	var c := prop.base_color
	if prop.reacts_to_possession:
		c = c.lerp(Palette.POSSESSED_VIOLET, _possession * 0.35)
	if highlighted:
		c = c.lerp(Palette.WARM_AMBER, 0.22)
	return c


func _draw() -> void:
	match prop.kind:
		PropDef.Kind.RUG, PropDef.Kind.FLOOR:
			_draw_flat()
		PropDef.Kind.ROUND:
			_draw_round()
		_:
			_draw_box()
	_draw_decal()
	if highlighted:
		_draw_highlight_ring()


# -- Primitives -----------------------------------------------------------------

func _draw_box() -> void:
	var base := _base_colour()
	var f := Palette.faces(base)
	var c_top: Color = f["top"]
	var c_left: Color = f["left"]
	var c_right: Color = f["right"]
	if prop.kind == PropDef.Kind.SOFT:
		# Soft goods read lighter on top and lose their hard bottom edge.
		c_top = base.lightened(0.15)

	var left := Iso.left_face(prop.origin, prop.size)
	var right := Iso.right_face(prop.origin, prop.size)
	var top := Iso.top_face(prop.origin, prop.size)

	draw_colored_polygon(left, c_left)
	draw_colored_polygon(right, c_right)
	draw_colored_polygon(top, c_top)

	if prop.kind != PropDef.Kind.WALL:
		_outline(top)
		draw_line(left[2], left[3], OUTLINE, 1.5)
		draw_line(right[2], right[3], OUTLINE, 1.5)
		draw_line(left[1], left[2], OUTLINE, 1.5)


func _draw_flat() -> void:
	var base := _base_colour()
	var top := Iso.top_face(prop.origin, prop.size)
	draw_colored_polygon(top, base)
	if prop.accent_color.a > 0.0:
		var inset := Iso.top_face(
			prop.origin + Vector3(0.28, 0.001, 0.28),
			prop.size - Vector3(0.56, 0.0, 0.56)
		)
		draw_colored_polygon(inset, prop.accent_color.darkened(0.1))


func _draw_round() -> void:
	var base := _base_colour()
	var c := prop.centre()
	var rx := prop.size.x * Iso.TILE_W * 0.5 * 0.5
	var ry := prop.size.z * Iso.TILE_H * 0.5 * 0.5
	var ground := Iso.to_screen(Vector3(c.x, prop.origin.y, c.z))
	var topc := Iso.to_screen(Vector3(c.x, prop.origin.y + prop.size.y, c.z))

	# Bottom disc, then a convex side wall, then the lit top disc.
	draw_colored_polygon(_ellipse(ground, rx, ry), base.darkened(0.34))
	draw_colored_polygon(PackedVector2Array([
		ground + Vector2(-rx, 0.0),
		topc + Vector2(-rx, 0.0),
		topc + Vector2(rx, 0.0),
		ground + Vector2(rx, 0.0),
	]), base.darkened(0.16))
	draw_colored_polygon(_ellipse(topc, rx, ry), base.lightened(0.12))


func _ellipse(centre: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	const STEPS := 22
	for i in STEPS:
		var a := TAU * (float(i) / STEPS)
		pts.append(centre + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _outline(poly: PackedVector2Array) -> void:
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, OUTLINE, 1.5, true)


func _draw_highlight_ring() -> void:
	var c := prop.centre()
	var ground := Iso.to_screen(Vector3(c.x, 0.02, c.z))
	var rx := maxf(prop.size.x, 0.8) * Iso.TILE_W * 0.42
	var ry := maxf(prop.size.z, 0.8) * Iso.TILE_H * 0.42
	var ring := _ellipse(ground, rx, ry)
	ring.append(ring[0])
	draw_polyline(ring, Palette.WARM_AMBER, 2.5, true)


# -- Decals ---------------------------------------------------------------------

func _draw_decal() -> void:
	match prop.decal:
		"screen": _decal_screen()
		"tower": _decal_tower()
		"keyboard": _decal_keyboard()
		"window": _decal_window()
		"door": _decal_door()
		"books", "shelf_books": _decal_books()
		"lamp": _decal_lamp()
		"leaves": _decal_leaves()
		"cat": _decal_cat()
		"cat_tree": _decal_cat_tree()
		"cat_chair": _decal_cat_chair()
		"shadow_cat": _decal_shadow_cat()
		"mug": _decal_mug()
		"cushions": _decal_cushions()
		"drawers": _decal_drawers()
		"hooks": _decal_hooks()
		"toys": _decal_toys()
		"cave": _decal_cave()
		_: pass


func _decal_screen() -> void:
	# The monitor face, inset on the +Z side, glowing violet.
	var o := prop.origin
	var s := prop.size
	var glow: Color = Palette.POSSESSED_VIOLET.lerp(
		Palette.SPECTRAL_MINT, 0.12 * sin(_pulse * 2.2) + 0.12
	)
	glow = glow.lerp(Color.WHITE, 0.15 + _possession * 0.25)
	var face := PackedVector2Array([
		Iso.to_screen(Vector3(o.x + 0.09, o.y + s.y - 0.1, o.z + s.z)),
		Iso.to_screen(Vector3(o.x + s.x - 0.09, o.y + s.y - 0.1, o.z + s.z)),
		Iso.to_screen(Vector3(o.x + s.x - 0.09, o.y + 0.14, o.z + s.z)),
		Iso.to_screen(Vector3(o.x + 0.09, o.y + 0.14, o.z + s.z)),
	])
	draw_colored_polygon(face, glow)
	# Scanline hint — cheap, and it sells "something is watching from inside".
	var top_l: Vector2 = face[0]
	var top_r: Vector2 = face[1]
	var bot_l: Vector2 = face[3]
	for i in range(1, 5):
		var t := float(i) / 5.0
		draw_line(
			top_l.lerp(bot_l, t),
			top_r.lerp(bot_l + (top_r - top_l), t),
			Color(0, 0, 0, 0.13), 1.0
		)


func _decal_tower() -> void:
	var o := prop.origin
	var s := prop.size
	var glow: Color = Palette.POSSESSED_VIOLET.lightened(0.1 + 0.15 * sin(_pulse * 3.0))
	var panel := PackedVector2Array([
		Iso.to_screen(Vector3(o.x + 0.08, o.y + s.y - 0.12, o.z + s.z)),
		Iso.to_screen(Vector3(o.x + s.x - 0.08, o.y + s.y - 0.12, o.z + s.z)),
		Iso.to_screen(Vector3(o.x + s.x - 0.08, o.y + 0.12, o.z + s.z)),
		Iso.to_screen(Vector3(o.x + 0.08, o.y + 0.12, o.z + s.z)),
	])
	draw_colored_polygon(panel, glow * Color(1, 1, 1, 0.85))


func _decal_keyboard() -> void:
	var top := Iso.top_face(prop.origin + Vector3(0.06, 0.0, 0.06), prop.size - Vector3(0.12, 0, 0.12))
	draw_colored_polygon(top, Palette.SPECTRAL_MINT.darkened(0.45))


func _decal_window() -> void:
	var o := prop.origin
	var s := prop.size
	var night := Color("1b2b45")
	var pane := PackedVector2Array([
		Iso.to_screen(Vector3(o.x + s.x, o.y + s.y - 0.12, o.z + 0.12)),
		Iso.to_screen(Vector3(o.x + s.x, o.y + s.y - 0.12, o.z + s.z - 0.12)),
		Iso.to_screen(Vector3(o.x + s.x, o.y + 0.12, o.z + s.z - 0.12)),
		Iso.to_screen(Vector3(o.x + s.x, o.y + 0.12, o.z + 0.12)),
	])
	draw_colored_polygon(pane, night)
	# Mullion cross.
	var a: Vector2 = pane[0].lerp(pane[3], 0.5)
	var b: Vector2 = pane[1].lerp(pane[2], 0.5)
	draw_line(a, b, prop.base_color.lightened(0.25), 2.0)
	draw_line(pane[0].lerp(pane[1], 0.5), pane[3].lerp(pane[2], 0.5), prop.base_color.lightened(0.25), 2.0)
	# Curtain slabs, warm against the cold pane.
	for side in [0.0, 1.0]:
		var z0: float = o.z + lerpf(0.0, s.z - 0.55, side)
		var curtain := PackedVector2Array([
			Iso.to_screen(Vector3(o.x + s.x + 0.02, o.y + s.y + 0.15, z0)),
			Iso.to_screen(Vector3(o.x + s.x + 0.02, o.y + s.y + 0.15, z0 + 0.55)),
			Iso.to_screen(Vector3(o.x + s.x + 0.02, o.y - 0.35, z0 + 0.55)),
			Iso.to_screen(Vector3(o.x + s.x + 0.02, o.y - 0.35, z0)),
		])
		draw_colored_polygon(curtain, Palette.HEARTH_CREAM.darkened(0.42))


func _decal_door() -> void:
	var o := prop.origin
	var s := prop.size
	var panel := PackedVector2Array([
		Iso.to_screen(Vector3(o.x + s.x, o.y + s.y - 0.25, o.z + 0.2)),
		Iso.to_screen(Vector3(o.x + s.x, o.y + s.y - 0.25, o.z + s.z - 0.2)),
		Iso.to_screen(Vector3(o.x + s.x, o.y + 0.25, o.z + s.z - 0.2)),
		Iso.to_screen(Vector3(o.x + s.x, o.y + 0.25, o.z + 0.2)),
	])
	draw_colored_polygon(panel, prop.base_color.darkened(0.18))
	var knob := Iso.to_screen(Vector3(o.x + s.x, o.y + 1.25, o.z + s.z - 0.3))
	draw_circle(knob, 3.5, Palette.WARM_AMBER)


func _decal_books() -> void:
	var o := prop.origin
	var s := prop.size
	var spines := [Palette.WARNING_CORAL, Palette.SPECTRAL_MINT, Palette.WARM_AMBER,
		Palette.DUSTY_ROSE, Palette.POSSESSED_VIOLET, Palette.HEARTH_CREAM]
	var shelves := maxi(1, int(s.y / 0.85))
	for row in shelves:
		var y := o.y + 0.35 + row * 0.85
		if y + 0.5 > o.y + s.y:
			continue
		var n := 5
		for i in n:
			var z := o.z + 0.22 + (s.z - 0.44) * (float(i) / n)
			var w := (s.z - 0.44) / n * 0.72
			var h := 0.42 + 0.12 * ((i * 7 + row * 3) % 3)
			var col: Color = spines[(i + row * 2) % spines.size()]
			var quad := PackedVector2Array([
				Iso.to_screen(Vector3(o.x + s.x + 0.01, y + h, z)),
				Iso.to_screen(Vector3(o.x + s.x + 0.01, y + h, z + w)),
				Iso.to_screen(Vector3(o.x + s.x + 0.01, y, z + w)),
				Iso.to_screen(Vector3(o.x + s.x + 0.01, y, z)),
			])
			draw_colored_polygon(quad, col.darkened(0.42))


func _decal_lamp() -> void:
	var c := prop.centre()
	var shade_top := Iso.to_screen(Vector3(c.x, prop.origin.y + prop.size.y + 0.05, c.z))
	draw_circle(shade_top, 7.0, Palette.WARM_AMBER.lightened(0.35))


func _decal_leaves() -> void:
	var c := prop.centre()
	var green: Color = prop.accent_color if prop.accent_color.a > 0 else Color("4e7a52")
	var base := Iso.to_screen(Vector3(c.x, prop.origin.y + prop.size.y * 0.45, c.z))
	for i in 7:
		var a := TAU * (float(i) / 7.0) + 0.4
		var r := 11.0 + 5.0 * ((i * 5) % 3)
		var tip := base + Vector2(cos(a) * r, sin(a) * r * 0.72 - 8.0)
		draw_line(base, tip, green.darkened(0.1), 4.0)
		draw_circle(tip, 4.0, green.lightened(0.12))


func _decal_cat() -> void:
	# Miso: a sleeping comma of a cat. Amber eye slits open as possession rises.
	var c := prop.centre()
	var body := Iso.to_screen(Vector3(c.x, 0.16, c.z))
	var fur: Color = prop.base_color.lerp(Palette.POSSESSED_VIOLET, _possession * 0.30)
	draw_set_transform(body, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 15.0, fur)
	draw_circle(Vector2(-13, -4), 10.0, fur)
	# Ears.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, -10), Vector2(-16, -19), Vector2(-12, -10)]), fur)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -11), Vector2(-6, -19), Vector2(-3, -10)]), fur)
	# Tail curl.
	draw_arc(Vector2(6, 4), 13.0, -0.4, 2.2, 12, fur, 5.0)
	var eye_open := 0.25 + _possession * 0.75
	var eye: Color = Palette.WARM_AMBER.lerp(Palette.POSSESSED_VIOLET, _possession)
	draw_line(Vector2(-17, -5), Vector2(-17, -5 - 4.0 * eye_open), eye, 2.5)
	draw_line(Vector2(-9, -5), Vector2(-9, -5 - 4.0 * eye_open), eye, 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _decal_cat_tree() -> void:
	var o := prop.origin
	var s := prop.size
	var post := Palette.WARM_AMBER.darkened(0.45)
	# Sisal post.
	var px := o.x + s.x * 0.5
	var pz := o.z + s.z * 0.5
	var bottom := Iso.to_screen(Vector3(px, 0.6, pz))
	var top := Iso.to_screen(Vector3(px, s.y - 0.55, pz))
	draw_line(bottom, top, post, 12.0)
	# Platforms.
	for level in [0.55, 1.9, s.y - 0.5]:
		var plat := Iso.top_face(
			Vector3(o.x + 0.15, level, o.z + 0.15),
			Vector3(s.x - 0.3, 0.16, s.z - 0.3)
		)
		draw_colored_polygon(plat, prop.base_color.lightened(0.18))
		draw_polyline(plat, OUTLINE, 1.4, true)
	# Dangling toy.
	var anchor := Iso.to_screen(Vector3(o.x + s.x - 0.35, s.y - 0.5, pz))
	draw_line(anchor, anchor + Vector2(0, 22), Palette.HEARTH_CREAM.darkened(0.5), 1.5)
	draw_circle(anchor + Vector2(0, 24), 4.0, Palette.WARNING_CORAL)


func _decal_cat_chair() -> void:
	# The cat-ear beanbag: two peaks on the back rim.
	var o := prop.origin
	var s := prop.size
	var ear_a := Iso.to_screen(Vector3(o.x + 0.3, s.y, o.z + 0.3))
	var ear_b := Iso.to_screen(Vector3(o.x + s.x - 0.3, s.y, o.z + 0.3))
	var col: Color = prop.base_color.lightened(0.2)
	for e in [ear_a, ear_b]:
		draw_colored_polygon(PackedVector2Array([
			e + Vector2(-9, 2), e + Vector2(0, -14), e + Vector2(9, 2)]), col)
	var seat := Iso.top_face(
		Vector3(o.x + 0.28, s.y * 0.72, o.z + 0.28),
		Vector3(s.x - 0.56, 0.02, s.z - 0.56)
	)
	draw_colored_polygon(seat, prop.accent_color if prop.accent_color.a > 0 else col.darkened(0.2))


func _decal_shadow_cat() -> void:
	# Not a real cat. Sits on the wall, ignores the light, grows with possession.
	var o := prop.origin
	var s := prop.size
	var scale_up := 1.0 + _possession * 0.18
	var col := Color(prop.base_color.r, prop.base_color.g, prop.base_color.b, 0.72)
	var base := Iso.to_screen(Vector3(o.x + s.x * 0.5, o.y, o.z))
	draw_set_transform(base, 0.0, Vector2(scale_up, scale_up))
	var w := s.x * Iso.TILE_W * 0.42
	var h := s.y * Iso.TILE_Z
	# Seated silhouette: haunch, chest, head, two ears, tail.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.55, 0), Vector2(-w * 0.42, -h * 0.42),
		Vector2(-w * 0.05, -h * 0.5), Vector2(w * 0.3, -h * 0.2),
		Vector2(w * 0.5, 0),
	]), col)
	draw_circle(Vector2(-w * 0.18, -h * 0.66), w * 0.26, col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.40, -h * 0.74), Vector2(-w * 0.34, -h * 0.98), Vector2(-w * 0.18, -h * 0.78)]), col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.10, -h * 0.79), Vector2(w * 0.02, -h * 0.99), Vector2(w * 0.08, -h * 0.74)]), col)
	draw_arc(Vector2(w * 0.52, -h * 0.1), h * 0.30, -1.2, 1.4, 14, col, 7.0)
	# Eye glint only once the curse is awake.
	if _possession > 0.45:
		var glint: Color = prop.accent_color
		glint.a = clampf((_possession - 0.45) * 2.0, 0.0, 1.0) * (0.65 + 0.35 * sin(_pulse * 4.0))
		draw_circle(Vector2(-w * 0.25, -h * 0.68), 2.6, glint)
		draw_circle(Vector2(-w * 0.10, -h * 0.68), 2.6, glint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _decal_mug() -> void:
	var o := prop.origin
	var s := prop.size
	var top := o.y + s.y
	var mug := Iso.to_screen(Vector3(o.x + s.x * 0.62, top, o.z + s.z * 0.45))
	draw_circle(mug, 7.0, Palette.HEARTH_CREAM)
	draw_arc(mug + Vector2(8, -1), 4.5, -1.6, 1.6, 8, Palette.HEARTH_CREAM, 2.0)
	# A book, closed, with a mint bookmark.
	var book := Iso.top_face(
		Vector3(o.x + 0.2, top, o.z + 0.35), Vector3(0.9, 0.09, 0.7))
	draw_colored_polygon(book, Palette.CHARCOAL_PLUM.lightened(0.18))
	draw_polyline(book, OUTLINE, 1.4, true)


func _decal_cushions() -> void:
	var o := prop.origin
	var s := prop.size
	var accent: Color = prop.accent_color if prop.accent_color.a > 0 else Palette.DUSTY_ROSE
	# Backrest along the wall side.
	var back := Iso.top_face(Vector3(o.x, s.y, o.z), Vector3(s.x * 0.42, 0.55, s.z))
	draw_colored_polygon(back, prop.base_color.lightened(0.1))
	# Throw blanket.
	var blanket := Iso.top_face(
		Vector3(o.x + s.x * 0.45, s.y + 0.02, o.z + 0.3), Vector3(s.x * 0.5, 0.02, 1.3))
	draw_colored_polygon(blanket, accent.darkened(0.12))


func _decal_drawers() -> void:
	var o := prop.origin
	var s := prop.size
	for i in 2:
		var y := o.y + 0.25 + i * (s.y * 0.45)
		var face := PackedVector2Array([
			Iso.to_screen(Vector3(o.x + 0.12, y + s.y * 0.32, o.z + s.z + 0.01)),
			Iso.to_screen(Vector3(o.x + s.x - 0.12, y + s.y * 0.32, o.z + s.z + 0.01)),
			Iso.to_screen(Vector3(o.x + s.x - 0.12, y, o.z + s.z + 0.01)),
			Iso.to_screen(Vector3(o.x + 0.12, y, o.z + s.z + 0.01)),
		])
		draw_colored_polygon(face, prop.base_color.darkened(0.22))


func _decal_hooks() -> void:
	var o := prop.origin
	var s := prop.size
	for i in 3:
		var z := o.z + 0.15 + i * (s.z - 0.3) / 3.0
		var p := Iso.to_screen(Vector3(o.x + s.x, o.y + 0.15, z))
		draw_line(p, p + Vector2(3, 8), Palette.WARM_AMBER.darkened(0.35), 2.5)
	# A satchel hanging off the middle hook.
	var bag := Iso.to_screen(Vector3(o.x + s.x, o.y - 0.25, o.z + s.z * 0.5))
	draw_circle(bag, 8.0, Color("6b4630"))


func _decal_toys() -> void:
	var o := prop.origin
	var s := prop.size
	var cols := [Palette.WARNING_CORAL, Palette.SPECTRAL_MINT, Palette.WARM_AMBER]
	for i in 3:
		var p := Iso.to_screen(Vector3(
			o.x + 0.3 + i * 0.3, o.y + s.y + 0.1, o.z + 0.35 + (i % 2) * 0.45))
		draw_circle(p, 5.0, cols[i])


func _decal_cave() -> void:
	var o := prop.origin
	var s := prop.size
	var mouth := Iso.to_screen(Vector3(o.x + s.x * 0.5, s.y * 0.32, o.z + s.z))
	draw_circle(mouth, 13.0, Color(0.06, 0.05, 0.09, 0.9))
