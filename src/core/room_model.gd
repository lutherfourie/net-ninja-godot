class_name RoomModel
extends Resource
## Render-agnostic description of a playable space.
##
## Holds geometry, props, walkable area and lighting mood. No rendering concepts
## leak in here — see docs/ARCHITECTURE.md for why that matters.

@export var id: String = ""
@export var display_name: String = ""

## Interior extents in world units (x, height, z).
@export var bounds: Vector3 = Vector3(14, 5, 14)

## Where the player starts, on the ground plane.
@export var spawn: Vector3 = Vector3(6, 0, 6)

## Union of walkable rectangles in the XZ plane. Supports the L-shaped floor of
## the reference room without needing a navmesh.
@export var walk_rects: Array[Rect2] = []

@export var props: Array[PropDef] = []

## Multiplied over the whole canvas before lights are added — this is what turns
## a flat greybox into "night, indoors".
@export var ambient_tint: Color = Color(0.42, 0.37, 0.5)


func add(prop: PropDef) -> PropDef:
	props.append(prop)
	return prop


func interactables() -> Array[PropDef]:
	var out: Array[PropDef] = []
	for p in props:
		if p.interact_id != "":
			out.append(p)
	return out


func blockers() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for p in props:
		if p.blocks:
			out.append(p.footprint())
	return out


## True when a ground-plane point is inside any walkable rect.
func is_walkable(point: Vector2) -> bool:
	for r in walk_rects:
		if r.has_point(point):
			return true
	return false


## Nearest walkable point, used to unstick an actor pushed out of bounds.
func clamp_to_walkable(point: Vector2) -> Vector2:
	if is_walkable(point):
		return point
	var best := point
	var best_d := INF
	for r in walk_rects:
		var c := Vector2(
			clampf(point.x, r.position.x, r.end.x),
			clampf(point.y, r.position.y, r.end.y)
		)
		var d := c.distance_squared_to(point)
		if d < best_d:
			best_d = d
			best = c
	return best


## Screen-space bounding box of the whole room, so a camera can frame it.
func screen_bounds() -> Rect2:
	var pts := [
		Iso.to_screen(Vector3(0, 0, 0)),
		Iso.to_screen(Vector3(bounds.x, 0, 0)),
		Iso.to_screen(Vector3(bounds.x, 0, bounds.z)),
		Iso.to_screen(Vector3(0, 0, bounds.z)),
		Iso.to_screen(Vector3(0, bounds.y, 0)),
		Iso.to_screen(Vector3(bounds.x, bounds.y, 0)),
		Iso.to_screen(Vector3(0, bounds.y, bounds.z)),
	]
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r
