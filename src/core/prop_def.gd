class_name PropDef
extends Resource
## A single piece of the room, described in world units and nothing else.
##
## A PropDef contains no Node2D, no texture and no screen coordinate. That is the
## whole point: Room2DView renders it as a shaded isometric box today, and a
## Room3DView can render the identical data as a MeshInstance3D tomorrow without
## the room author touching a thing.

enum Kind {
	BOX,     ## Standard shaded cuboid — furniture, appliances, boxes
	FLOOR,   ## Flat ground quad — floorboards, tiles
	RUG,     ## Flat, slightly raised, soft edges
	WALL,    ## Tall thin cuboid drawn behind everything
	SOFT,    ## Cuboid with a lightened rounded top — cushions, beds, plush
	ROUND,   ## Ellipse on the ground plane with a shaded body — pots, bowls, cats
}

@export var id: String = ""
@export var kind: Kind = Kind.BOX

## Minimum corner on the ground plane, in world units.
@export var origin: Vector3 = Vector3.ZERO
## Extents along +X, +Y (up) and +Z.
@export var size: Vector3 = Vector3.ONE

@export var base_color: Color = Color("6d4630")
## Optional accent used by decals (screen glow, cushion piping, plant leaves).
@export var accent_color: Color = Color(0, 0, 0, 0)

## Blocks the player when true. Rugs, floors and wall art do not.
@export var blocks: bool = true

## Non-empty turns this prop into an interactable. The room hub raises a prompt
## when Ami is inside `interact_radius` world units of the prop centre.
@export var interact_id: String = ""
@export var interact_label: String = ""
@export var interact_radius: float = 1.6

## Emissive pool of light attached to this prop. Lights are how the PDF's
## "warm pools of baked light" and "violet PC light" get expressed.
@export var light_color: Color = Color(0, 0, 0, 0)
@export var light_energy: float = 0.0
@export var light_scale: float = 1.0
@export var light_offset: Vector3 = Vector3.ZERO

## Optional extra detail the view may draw on top of the base shape.
## Recognised by Room2DView: "screen", "window", "books", "leaves", "cat",
## "poster", "shadow_cat", "keyboard", "mug".
@export var decal: String = ""

## Props whose colour should react to GameState.possession.
@export var reacts_to_possession: bool = false


func centre() -> Vector3:
	return origin + size * 0.5


## Ground-plane footprint, for collision and interaction tests.
func footprint() -> Rect2:
	return Rect2(Vector2(origin.x, origin.z), Vector2(size.x, size.z))


static func make(cfg: Dictionary) -> PropDef:
	var p := PropDef.new()
	for key in cfg.keys():
		p.set(key, cfg[key])
	return p
