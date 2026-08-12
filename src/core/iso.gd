class_name Iso
extends RefCounted
## Isometric projection maths — the seam between world data and any renderer.
##
## World space uses Godot's 3D convention on purpose: +X right, +Y up, +Z toward
## the camera. Every room, prop and actor is authored in these units. The 2D view
## projects them; a future Room3DView consumes the SAME numbers with no
## conversion, which is what "3D-ready" means in this project.
##
## Projection is a true 2:1 dimetric ("game isometric"), matching the reference
## art and the PDF's "orthographic isometric camera".

## Screen footprint of one world unit on the ground plane.
const TILE_W := 64.0
const TILE_H := 32.0
## Screen height of one world unit of elevation.
const TILE_Z := 38.0


## Project a world-space point to view-space pixels.
static func to_screen(w: Vector3) -> Vector2:
	return Vector2(
		(w.x - w.z) * (TILE_W * 0.5),
		(w.x + w.z) * (TILE_H * 0.5) - w.y * TILE_Z
	)


## Inverse projection onto the ground plane (y = 0). Used for tap-to-move and
## for hit-testing props from a touch position.
static func to_ground(screen: Vector2) -> Vector3:
	var a := screen.x / (TILE_W * 0.5)
	var b := screen.y / (TILE_H * 0.5)
	return Vector3((b + a) * 0.5, 0.0, (b - a) * 0.5)


## Painter's-algorithm depth key for an axis-aligned box.
## Larger = drawn later = closer to the viewer.
static func depth(origin: Vector3, size: Vector3) -> float:
	return (origin.x + size.x) + (origin.z + size.z) + origin.y * 0.5


## Godot's z_index is a 16-bit-ish int; quantise the float key into it.
static func depth_to_z_index(key: float) -> int:
	return clampi(int(round(key * 16.0)), -4000, 4000)


## The four ground-plane corners of a box, projected. Order is
## back, right, front, left — a convex quad ready for draw_colored_polygon.
static func top_face(origin: Vector3, size: Vector3) -> PackedVector2Array:
	var y := origin.y + size.y
	return PackedVector2Array([
		to_screen(Vector3(origin.x, y, origin.z)),
		to_screen(Vector3(origin.x + size.x, y, origin.z)),
		to_screen(Vector3(origin.x + size.x, y, origin.z + size.z)),
		to_screen(Vector3(origin.x, y, origin.z + size.z)),
	])


## The +Z facing side (reads as the "left" face on screen).
static func left_face(origin: Vector3, size: Vector3) -> PackedVector2Array:
	var z := origin.z + size.z
	return PackedVector2Array([
		to_screen(Vector3(origin.x, origin.y + size.y, z)),
		to_screen(Vector3(origin.x + size.x, origin.y + size.y, z)),
		to_screen(Vector3(origin.x + size.x, origin.y, z)),
		to_screen(Vector3(origin.x, origin.y, z)),
	])


## The +X facing side (reads as the "right" face on screen).
static func right_face(origin: Vector3, size: Vector3) -> PackedVector2Array:
	var x := origin.x + size.x
	return PackedVector2Array([
		to_screen(Vector3(x, origin.y + size.y, origin.z)),
		to_screen(Vector3(x, origin.y + size.y, origin.z + size.z)),
		to_screen(Vector3(x, origin.y, origin.z + size.z)),
		to_screen(Vector3(x, origin.y, origin.z)),
	])
