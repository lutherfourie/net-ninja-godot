class_name RuinedShape
extends RefCounted
## The one shape language shared by buttons, panels, bubbles and Cat-alog frames.
##
## PDF p.5/p.6: "Ruined corners • cat-ear peaks", corner cut 12-20 px, border
## 2-3 px. Peaks are returned separately from the body so every polygon we hand
## to the renderer stays convex — cheaper, and no triangulation surprises.

## Chamfered body. `cut` is the corner bite in pixels.
static func frame(size: Vector2, cut: float = Tokens.CORNER_CUT) -> PackedVector2Array:
	var c := minf(cut, minf(size.x, size.y) * 0.4)
	var half := c * 0.5
	return PackedVector2Array([
		Vector2(c, 0),
		Vector2(size.x - half, 0),
		Vector2(size.x, half),
		Vector2(size.x, size.y - c),
		Vector2(size.x - c, size.y),
		Vector2(half, size.y),
		Vector2(0, size.y - half),
		Vector2(0, c),
	])


## Closed outline for draw_polyline.
static func outline(size: Vector2, cut: float = Tokens.CORNER_CUT) -> PackedVector2Array:
	var pts := frame(size, cut)
	pts.append(pts[0])
	return pts


## Two cat-ear peaks riding the top edge. Draw these in the same colour as the
## body, before the border, so the silhouette reads as one shape.
static func ears(size: Vector2, cut: float = Tokens.CORNER_CUT) -> Array[PackedVector2Array]:
	var h := cut * 0.85
	var w := cut * 0.72
	var out: Array[PackedVector2Array] = []
	for x_ratio: float in [0.26, 0.74]:
		var x: float = size.x * x_ratio
		# Bases sit *inside* the body so the peak welds to it even under the
		# drop shadow, rather than reading as two floating triangles.
		out.append(PackedVector2Array([
			Vector2(x - w, cut * 0.4),
			Vector2(x, -h),
			Vector2(x + w, cut * 0.4),
		]))
	return out


## A speech bubble body plus a separate tail (PDF p.6: "Separate tail").
static func bubble(size: Vector2, cut: float = Tokens.CORNER_CUT) -> PackedVector2Array:
	return frame(size, cut)


static func bubble_tail(size: Vector2, from_ratio: float = 0.22) -> PackedVector2Array:
	var x := size.x * from_ratio
	return PackedVector2Array([
		Vector2(x, size.y - 1.0),
		Vector2(x + 20.0, size.y - 1.0),
		Vector2(x + 4.0, size.y + 16.0),
	])


## Soft drop shadow approximation: the same body, offset and darkened.
## (0 / 8 / 24 / 35% in the spec; a real blur costs a texture we do not need yet.)
static func shadow_layers(size: Vector2, cut: float = Tokens.CORNER_CUT) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in 3:
		var grow := Tokens.SHADOW_BLUR * (float(i + 1) / 3.0) * 0.35
		var offset := Tokens.SHADOW_OFFSET * (float(i + 1) / 3.0)
		var poly := frame(size + Vector2(grow, grow) * 2.0, cut)
		var moved := PackedVector2Array()
		for p in poly:
			moved.append(p - Vector2(grow, grow) + offset)
		out.append({
			"poly": moved,
			"alpha": Tokens.SHADOW_ALPHA / 3.0,
		})
	return out
