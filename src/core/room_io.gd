class_name RoomIO
extends RefCounted
## Rooms as data: JSON in, RoomModel out, and back again.
##
## The flat began life as code (`rooms/ami_apartment.gd`). That file stays as
## the fallback and the canonical first version, but the editor works on JSON in
## `data/rooms/`, which means a layout change is a readable diff instead of a
## code review of forty Vector3 edits.
##
## Load order: `user://rooms/` overrides `res://data/rooms/`, which overrides the
## code builder. Saving prefers `res://` (works when running from the project,
## i.e. every dev machine) and falls back to `user://` in exported builds; a
## successful res:// save deletes any user:// override so a stale one can never
## shadow a freshly pulled repo.

const FORMAT_VERSION := 1
const DIR_RES := "res://data/rooms/"
const DIR_USER := "user://rooms/"


## Code fallbacks, one per shipped room.
static func builders() -> Dictionary:
	return {
		"ami_apartment": Callable(AmiApartment, "build"),
	}


# -- Primitive conversions ------------------------------------------------------

static func _v3(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _to_v3(a: Variant) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func _col(c: Color) -> String:
	return c.to_html(true)


static func _to_col(s: Variant) -> Color:
	return Color.html(str(s))


# -- Room <-> Dictionary --------------------------------------------------------

static func room_to_dict(room: RoomModel) -> Dictionary:
	var rects := []
	for r in room.walk_rects:
		rects.append([r.position.x, r.position.y, r.size.x, r.size.y])
	var props := []
	for p in room.props:
		props.append(prop_to_dict(p))
	return {
		"format": FORMAT_VERSION,
		"id": room.id,
		"display_name": room.display_name,
		"bounds": _v3(room.bounds),
		"spawn": _v3(room.spawn),
		"ambient_tint": _col(room.ambient_tint),
		"walk_rects": rects,
		"props": props,
	}


static func room_from_dict(d: Dictionary) -> RoomModel:
	var room := RoomModel.new()
	room.id = str(d.get("id", ""))
	room.display_name = str(d.get("display_name", ""))
	room.bounds = _to_v3(d.get("bounds", [14, 5, 14]))
	room.spawn = _to_v3(d.get("spawn", [6, 0, 6]))
	room.ambient_tint = _to_col(d.get("ambient_tint", "ffffffff"))

	var rects: Array[Rect2] = []
	for r in d.get("walk_rects", []):
		rects.append(Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])))
	room.walk_rects = rects

	var props: Array[PropDef] = []
	for pd in d.get("props", []):
		props.append(prop_from_dict(pd))
	room.props = props
	return room


static func prop_to_dict(p: PropDef) -> Dictionary:
	return {
		"id": p.id,
		"kind": PropDef.Kind.keys()[p.kind],
		"origin": _v3(p.origin),
		"size": _v3(p.size),
		"base_color": _col(p.base_color),
		"accent_color": _col(p.accent_color),
		"blocks": p.blocks,
		"decal": p.decal,
		"reacts_to_possession": p.reacts_to_possession,
		"interact_id": p.interact_id,
		"interact_label": p.interact_label,
		"interact_radius": p.interact_radius,
		"light_color": _col(p.light_color),
		"light_energy": p.light_energy,
		"light_scale": p.light_scale,
		"light_offset": _v3(p.light_offset),
	}


static func prop_from_dict(d: Dictionary) -> PropDef:
	var p := PropDef.new()
	p.id = str(d.get("id", ""))
	p.kind = int(PropDef.Kind.get(str(d.get("kind", "BOX")), PropDef.Kind.BOX)) as PropDef.Kind
	p.origin = _to_v3(d.get("origin", [0, 0, 0]))
	p.size = _to_v3(d.get("size", [1, 1, 1]))
	p.base_color = _to_col(d.get("base_color", "6d4630ff"))
	p.accent_color = _to_col(d.get("accent_color", "00000000"))
	p.blocks = bool(d.get("blocks", true))
	p.decal = str(d.get("decal", ""))
	p.reacts_to_possession = bool(d.get("reacts_to_possession", false))
	p.interact_id = str(d.get("interact_id", ""))
	p.interact_label = str(d.get("interact_label", ""))
	p.interact_radius = float(d.get("interact_radius", 1.6))
	p.light_color = _to_col(d.get("light_color", "00000000"))
	p.light_energy = float(d.get("light_energy", 0.0))
	p.light_scale = float(d.get("light_scale", 1.0))
	p.light_offset = _to_v3(d.get("light_offset", [0, 0, 0]))
	return p


# -- Disk -----------------------------------------------------------------------

## Returns the path written, or "" on failure.
static func save_room(room: RoomModel) -> String:
	if room.id == "":
		push_error("RoomIO: refusing to save a room with no id")
		return ""
	var text := JSON.stringify(room_to_dict(room), "\t") + "\n"

	for dir in [DIR_RES, DIR_USER]:
		DirAccess.make_dir_recursive_absolute(dir)
		var path := "%s%s.json" % [dir, room.id]
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			continue
		f.store_string(text)
		f.close()
		if dir == DIR_RES:
			# Kill any user override so it cannot shadow the repo copy later.
			var override := "%s%s.json" % [DIR_USER, room.id]
			if FileAccess.file_exists(override):
				DirAccess.remove_absolute(override)
		return path
	return ""


static func load_room(id: String) -> RoomModel:
	for dir in [DIR_USER, DIR_RES]:
		var path := "%s%s.json" % [dir, id]
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			return room_from_dict(parsed)
		push_warning("RoomIO: %s is not valid room JSON, skipping" % path)
	return null


## What the game actually calls: JSON if present, code builder if not.
static func load_or_build(id: String) -> RoomModel:
	var room := load_room(id)
	if room != null:
		return room
	var b := builders()
	if b.has(id):
		var built: RoomModel = b[id].call()
		return built
	push_error("RoomIO: no JSON and no builder for room '%s'" % id)
	return null
