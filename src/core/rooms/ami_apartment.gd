class_name AmiApartment
extends RefCounted
## Ami's flat — the cozy anchor of the whole game.
##
## Laid out from the concept render: window and sofa down the left wall, desk and
## haunted PC along the right wall, cat tree in the corner, Miso asleep on the rug
## in the middle. Everything is authored in world units only, so this file stays
## valid when the renderer changes.
##
## Reading order below follows the room clockwise from the back corner.

const WALL_H := 4.6
const WALL_T := 0.4


static func build() -> RoomModel:
	var room := RoomModel.new()
	room.id = "ami_apartment"
	room.display_name = "Ami's Flat"
	room.bounds = Vector3(15.0, WALL_H, 13.4)
	room.spawn = Vector3(6.2, 0.0, 6.4)
	room.ambient_tint = Color(0.60, 0.52, 0.60)

	# Reference silhouette: a full rectangle, a small notch bitten out of the
	# bottom-centre-left, the right side reaching lowest (under the cat rug),
	# and a short left extension carrying the side table and lamp.
	room.walk_rects = [
		Rect2(0.5, 0.5, 14.0, 10.0),
		Rect2(8.0, 10.5, 6.5, 2.4),
		Rect2(0.5, 10.5, 3.2, 1.8),
	]

	_walls(room)
	_left_wall_dressing(room)
	_desk_and_pc(room)
	_cat_corner(room)
	_living_area(room)
	_clutter(room)
	return room


# -- Shell ----------------------------------------------------------------------

static func _walls(room: RoomModel) -> void:
	room.add(PropDef.make({
		"id": "wall_left", "kind": PropDef.Kind.WALL,
		"origin": Vector3(0, 0, 0), "size": Vector3(WALL_T, WALL_H, 13.4),
		"base_color": Color("4d3f5c"), "blocks": true,
	}))
	room.add(PropDef.make({
		"id": "wall_right", "kind": PropDef.Kind.WALL,
		"origin": Vector3(0, 0, 0), "size": Vector3(15.0, WALL_H, WALL_T),
		"base_color": Color("574170"), "blocks": true,
	}))
	room.add(PropDef.make({
		"id": "skirting_left", "kind": PropDef.Kind.WALL,
		"origin": Vector3(WALL_T, 0, 0.4), "size": Vector3(0.12, 0.4, 13.0),
		"base_color": Color("2c2136"), "blocks": false,
	}))


# -- Left wall: door, books, window, sofa ---------------------------------------

static func _left_wall_dressing(room: RoomModel) -> void:
	room.add(PropDef.make({
		"id": "door", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.08, 0, 0.9), "size": Vector3(0.34, 2.9, 1.7),
		"base_color": Color("6b4630"), "accent_color": Palette.WARM_AMBER,
		"blocks": false, "decal": "door",
		"interact_id": "front_door", "interact_label": "Leave for a contract",
		"interact_radius": 1.8,
	}))
	room.add(PropDef.make({
		"id": "coat_hooks", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.42, 2.2, 2.9), "size": Vector3(0.1, 0.5, 0.9),
		"base_color": Color("5b3a28"), "blocks": false, "decal": "hooks",
	}))
	room.add(PropDef.make({
		"id": "wall_lantern", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.44, 2.6, 0.5), "size": Vector3(0.36, 0.6, 0.36),
		"base_color": Color("3a2c22"), "accent_color": Palette.WARM_AMBER,
		"blocks": false,
		"light_color": Palette.WARM_AMBER, "light_energy": 0.85, "light_scale": 2.8,
		"light_offset": Vector3(0.2, 0.1, 0.2),
	}))
	room.add(PropDef.make({
		"id": "bookshelf", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.5, 0, 3.5), "size": Vector3(1.1, 3.2, 2.2),
		"base_color": Color("5f3d29"), "decal": "books", "blocks": true,
		"interact_id": "bookshelf", "interact_label": "Read up on demonology",
	}))
	room.add(PropDef.make({
		"id": "window", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.06, 1.9, 6.2), "size": Vector3(0.36, 2.0, 2.4),
		"base_color": Color("20304a"), "accent_color": Color("8fb3d9"),
		"blocks": false, "decal": "window",
		"light_color": Color("6f8fc4"), "light_energy": 0.50, "light_scale": 3.8,
		"light_offset": Vector3(0.6, -0.6, 1.2),
	}))
	room.add(PropDef.make({
		"id": "sofa", "kind": PropDef.Kind.SOFT,
		"origin": Vector3(0.75, 0, 6.0), "size": Vector3(2.0, 1.15, 3.6),
		"base_color": Color("8a7a68"), "accent_color": Palette.DUSTY_ROSE,
		"decal": "cushions", "blocks": true,
	}))
	room.add(PropDef.make({
		"id": "side_table", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.8, 0, 10.1), "size": Vector3(1.1, 0.85, 1.1),
		"base_color": Color("6b4630"), "blocks": true,
	}))
	room.add(PropDef.make({
		"id": "table_lamp", "kind": PropDef.Kind.BOX,
		"origin": Vector3(1.05, 0.85, 10.35), "size": Vector3(0.6, 0.85, 0.6),
		"base_color": Color("4a3524"), "accent_color": Palette.WARM_AMBER,
		"blocks": false, "decal": "lamp",
		"light_color": Palette.WARM_AMBER, "light_energy": 1.10, "light_scale": 4.6,
		"light_offset": Vector3(0.3, 0.5, 0.3),
	}))


# -- Right wall: the desk, and the thing living inside the PC --------------------

static func _desk_and_pc(room: RoomModel) -> void:
	room.add(PropDef.make({
		"id": "wall_shelf", "kind": PropDef.Kind.BOX,
		"origin": Vector3(2.6, 3.0, 0.42), "size": Vector3(2.4, 0.16, 0.6),
		"base_color": Color("5f3d29"), "blocks": false, "decal": "shelf_books",
	}))
	room.add(PropDef.make({
		"id": "desk", "kind": PropDef.Kind.BOX,
		"origin": Vector3(2.3, 0, 0.5), "size": Vector3(3.7, 1.0, 1.6),
		"base_color": Color("6b4630"), "blocks": true,
	}))
	room.add(PropDef.make({
		"id": "monitor", "kind": PropDef.Kind.BOX,
		"origin": Vector3(3.0, 1.0, 0.75), "size": Vector3(1.5, 1.0, 0.18),
		"base_color": Color("241d2e"), "accent_color": Palette.POSSESSED_VIOLET,
		"blocks": false, "decal": "screen", "reacts_to_possession": true,
		"interact_id": "pc", "interact_label": "Open the contract inbox",
		"interact_radius": 2.2,
		"light_color": Palette.POSSESSED_VIOLET, "light_energy": 1.10, "light_scale": 4.0,
		"light_offset": Vector3(0.75, 0.5, 0.9),
	}))
	room.add(PropDef.make({
		"id": "pc_tower", "kind": PropDef.Kind.BOX,
		"origin": Vector3(4.75, 1.0, 0.7), "size": Vector3(0.6, 1.2, 1.0),
		"base_color": Color("2b2338"), "accent_color": Palette.POSSESSED_VIOLET,
		"blocks": false, "decal": "tower", "reacts_to_possession": true,
		"light_color": Palette.POSSESSED_VIOLET, "light_energy": 0.85, "light_scale": 2.4,
		"light_offset": Vector3(0.3, 0.5, 0.5),
	}))
	room.add(PropDef.make({
		"id": "keyboard", "kind": PropDef.Kind.BOX,
		"origin": Vector3(3.1, 1.0, 1.35), "size": Vector3(1.3, 0.1, 0.45),
		"base_color": Color("35293f"), "accent_color": Palette.SPECTRAL_MINT,
		"blocks": false, "decal": "keyboard",
	}))
	room.add(PropDef.make({
		"id": "desk_lamp", "kind": PropDef.Kind.BOX,
		"origin": Vector3(2.45, 1.0, 0.75), "size": Vector3(0.34, 1.0, 0.34),
		"base_color": Color("3a2c22"), "accent_color": Palette.WARM_AMBER,
		"blocks": false, "decal": "lamp",
		"light_color": Palette.WARM_AMBER, "light_energy": 0.80, "light_scale": 3.4,
		"light_offset": Vector3(0.2, 0.6, 0.4),
	}))
	room.add(PropDef.make({
		"id": "desk_chair", "kind": PropDef.Kind.SOFT,
		"origin": Vector3(3.5, 0, 2.4), "size": Vector3(1.0, 1.15, 1.0),
		"base_color": Color("3f3348"), "blocks": true,
	}))
	room.add(PropDef.make({
		"id": "drawers", "kind": PropDef.Kind.BOX,
		"origin": Vector3(6.2, 0, 0.55), "size": Vector3(1.4, 1.4, 1.3),
		"base_color": Color("5f3d29"), "blocks": true, "decal": "drawers",
	}))
	# The cat that is not there. Reads as a shadow cast on the wall, and it grows
	# with possession — "possession is environmental" (PDF p.8).
	room.add(PropDef.make({
		"id": "cat_shadow", "kind": PropDef.Kind.BOX,
		"origin": Vector3(7.9, 1.1, 0.41), "size": Vector3(2.6, 2.8, 0.02),
		"base_color": Color("120e1a"), "accent_color": Palette.POSSESSED_VIOLET,
		"blocks": false, "decal": "shadow_cat", "reacts_to_possession": true,
	}))


# -- Cat corner -----------------------------------------------------------------

static func _cat_corner(room: RoomModel) -> void:
	room.add(PropDef.make({
		"id": "cat_tree", "kind": PropDef.Kind.SOFT,
		"origin": Vector3(11.0, 0, 1.2), "size": Vector3(2.1, 3.5, 2.1),
		"base_color": Color("977d7c"), "accent_color": Palette.DUSTY_ROSE,
		"decal": "cat_tree", "blocks": true,
		"interact_id": "cat_tree", "interact_label": "Straighten the scratching post",
	}))
	room.add(PropDef.make({
		"id": "cat_cave", "kind": PropDef.Kind.SOFT,
		"origin": Vector3(11.5, 0, 4.0), "size": Vector3(1.9, 1.5, 1.9),
		"base_color": Color("8e8172"), "blocks": true, "decal": "cave",
	}))
	room.add(PropDef.make({
		"id": "toy_crate", "kind": PropDef.Kind.BOX,
		"origin": Vector3(10.7, 0, 8.9), "size": Vector3(1.3, 0.9, 1.3),
		"base_color": Color("6b4630"), "accent_color": Palette.WARNING_CORAL,
		"blocks": true, "decal": "toys",
	}))
	room.add(PropDef.make({
		"id": "plant_corner", "kind": PropDef.Kind.ROUND,
		"origin": Vector3(12.9, 0, 5.4), "size": Vector3(1.5, 2.2, 1.5),
		"base_color": Color("6b4630"), "accent_color": Color("4e7a52"),
		"blocks": true, "decal": "leaves",
	}))
	room.add(PropDef.make({
		"id": "storage_box", "kind": PropDef.Kind.BOX,
		"origin": Vector3(12.4, 0, 7.0), "size": Vector3(1.2, 1.0, 1.2),
		"base_color": Color("52407a"), "blocks": true,
	}))


# -- Living area: rug, table, and Miso -------------------------------------------

static func _living_area(room: RoomModel) -> void:
	room.add(PropDef.make({
		"id": "rug", "kind": PropDef.Kind.RUG,
		"origin": Vector3(2.6, 0, 5.9), "size": Vector3(4.6, 0.03, 4.6),
		"base_color": Palette.DUSTY_ROSE.darkened(0.35),
		"accent_color": Palette.DUSTY_ROSE, "blocks": false, "decal": "round",
	}))
	room.add(PropDef.make({
		"id": "coffee_table", "kind": PropDef.Kind.ROUND,
		"origin": Vector3(3.9, 0, 7.2), "size": Vector3(2.1, 0.72, 2.1),
		"base_color": Color("7a4f34"), "accent_color": Palette.HEARTH_CREAM,
		"blocks": true, "decal": "mug",
		"interact_id": "tea", "interact_label": "Finish the tea",
	}))
	room.add(PropDef.make({
		"id": "cat_rug", "kind": PropDef.Kind.RUG,
		"origin": Vector3(7.3, 0, 7.9), "size": Vector3(2.6, 0.03, 2.6),
		"base_color": Palette.DUSTY_ROSE.darkened(0.28),
		"accent_color": Palette.DUSTY_ROSE, "blocks": false, "decal": "round",
	}))
	room.add(PropDef.make({
		"id": "miso", "kind": PropDef.Kind.ROUND,
		"origin": Vector3(7.95, 0, 8.55), "size": Vector3(1.3, 0.55, 1.1),
		"base_color": Color("15121c"), "accent_color": Palette.WARM_AMBER,
		"blocks": false, "decal": "cat", "reacts_to_possession": true,
		"interact_id": "cat", "interact_label": "Pet Miso",
		"interact_radius": 1.9,
	}))
	room.add(PropDef.make({
		"id": "cat_ear_bed", "kind": PropDef.Kind.SOFT,
		"origin": Vector3(2.9, 0, 3.0), "size": Vector3(1.5, 0.85, 1.5),
		"base_color": Color("e2d7c8"), "accent_color": Palette.DUSTY_ROSE,
		"blocks": true, "decal": "cat_chair",
	}))
	# The namesake, leaning at the desk exactly where the render puts it.
	room.add(PropDef.make({
		"id": "hand_net", "kind": PropDef.Kind.BOX,
		"origin": Vector3(1.85, 0, 1.7), "size": Vector3(0.65, 2.05, 0.7),
		"base_color": Color(0, 0, 0, 0), "blocks": false, "decal": "handnet",
		"interact_id": "hand_net", "interact_label": "Take the net",
		"interact_radius": 1.7,
	}))
	room.add(PropDef.make({
		"id": "string_lights", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.06, 3.15, 2.9), "size": Vector3(0.38, 0.3, 3.6),
		"base_color": Color(0, 0, 0, 0), "blocks": false, "decal": "string_lights",
	}))
	room.add(PropDef.make({
		"id": "wall_frames", "kind": PropDef.Kind.BOX,
		"origin": Vector3(0.06, 2.1, 3.0), "size": Vector3(0.38, 0.5, 1.0),
		"base_color": Color(0, 0, 0, 0), "blocks": false, "decal": "frames",
	}))
	room.add(PropDef.make({
		"id": "mouse_toy", "kind": PropDef.Kind.BOX,
		"origin": Vector3(9.9, 0, 10.9), "size": Vector3(0.5, 0.15, 0.4),
		"base_color": Color(0, 0, 0, 0), "blocks": false, "decal": "mouse_toy",
	}))


# -- Small stuff that sells "lived in" -------------------------------------------

static func _clutter(room: RoomModel) -> void:
	room.add(PropDef.make({
		"id": "door_mat", "kind": PropDef.Kind.RUG,
		"origin": Vector3(1.5, 0, 1.0), "size": Vector3(1.5, 0.02, 1.5),
		"base_color": Color("4a4050"), "blocks": false,
	}))
	room.add(PropDef.make({
		"id": "slippers", "kind": PropDef.Kind.BOX,
		"origin": Vector3(1.7, 0, 2.7), "size": Vector3(0.55, 0.16, 0.5),
		"base_color": Palette.DUSTY_ROSE.darkened(0.2), "blocks": false,
	}))
	room.add(PropDef.make({
		"id": "plant_shelf", "kind": PropDef.Kind.ROUND,
		"origin": Vector3(0.55, 2.5, 8.9), "size": Vector3(0.8, 1.1, 0.8),
		"base_color": Color("5f3d29"), "accent_color": Color("4e7a52"),
		"blocks": false, "decal": "leaves",
	}))
	room.add(PropDef.make({
		"id": "plant_sofa", "kind": PropDef.Kind.ROUND,
		"origin": Vector3(1.0, 0, 11.6), "size": Vector3(1.2, 1.8, 1.2),
		"base_color": Color("6b4630"), "accent_color": Color("59865c"),
		"blocks": true, "decal": "leaves",
	}))
	room.add(PropDef.make({
		"id": "toy_ball", "kind": PropDef.Kind.ROUND,
		"origin": Vector3(9.0, 0, 11.3), "size": Vector3(0.34, 0.34, 0.34),
		"base_color": Palette.WARNING_CORAL, "blocks": false,
	}))
	room.add(PropDef.make({
		"id": "book_stack", "kind": PropDef.Kind.BOX,
		"origin": Vector3(6.5, 1.4, 0.7), "size": Vector3(0.7, 0.35, 0.6),
		"base_color": Color("4a3f63"), "accent_color": Palette.HEARTH_CREAM,
		"blocks": false, "decal": "books",
	}))
