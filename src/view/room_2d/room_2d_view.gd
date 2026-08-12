extends RoomView
## The shipping renderer: a 2:1 isometric painter over procedural solids.
##
## Responsibilities are deliberately narrow — build nodes from a RoomModel, keep
## them sorted, run the camera, and expose the RoomView interface. It owns no
## gameplay state and never writes back into the model.

const Prop2D := preload("res://src/view/room_2d/prop_2d.gd")
const Floor2D := preload("res://src/view/room_2d/floor_2d.gd")
const Actor2D := preload("res://src/view/room_2d/actor_2d.gd")
const Wisp2D := preload("res://src/view/room_2d/wisp_2d.gd")

## Tuned so Ami is about 8% of screen height on a 720 x 1280 phone — big enough
## to read as a character, small enough to keep most of the flat in shot.
const FOLLOW_ZOOM := 1.6
const FIT_PADDING := 0.94
const CAMERA_LAG := 6.0

## Where the leftover exorcism residue hangs in Ami's flat.
const WISP_SPOTS := [
	Vector3(2.4, 0.0, 4.6),
	Vector3(12.6, 0.0, 1.8),
	Vector3(4.6, 0.0, 11.4),
]

var room: RoomModel

## FIT framing controls, for screens that want the room as a backdrop rather
## than a diagram: boost pushes past a strict fit, offset slides the framing so
## foreground UI (Ami on the menu) can stand on the floor instead of below it.
var fit_zoom_boost := 1.0
var fit_offset := Vector2.ZERO

var _camera: Camera2D
var _modulate: CanvasModulate
var _actor: Node2D
var _props: Dictionary = {}       ## id -> Prop2D
var _lights: Dictionary = {}      ## id -> PointLight2D
var _ambient_on := true
var _highlighted := ""
var _mode: CameraMode = CameraMode.FIT
var _light_texture: Texture2D
var _camera_target := Vector2.ZERO


func _ready() -> void:
	_light_texture = _make_light_texture()


func setup(r: RoomModel) -> void:
	room = r
	if _light_texture == null:
		_light_texture = _make_light_texture()

	for child in get_children():
		child.queue_free()
	_props.clear()
	_lights.clear()
	_highlighted = ""

	# Night, indoors. Lights add warmth back on top of this.
	_modulate = CanvasModulate.new()
	_modulate.color = room.ambient_tint if _ambient_on else Color.WHITE
	add_child(_modulate)

	var floor_node := Floor2D.new()
	add_child(floor_node)
	floor_node.setup(room)

	for prop in room.props:
		var node := Prop2D.new()
		add_child(node)
		node.setup(prop)
		if prop.id != "":
			_props[prop.id] = node
		_sync_light(prop)

	for i in WISP_SPOTS.size():
		var wisp := Wisp2D.new()
		add_child(wisp)
		wisp.setup(WISP_SPOTS[i], float(i) * 2.1, _light_texture)

	_actor = Actor2D.new()
	add_child(_actor)
	_actor.sync(room.spawn, Vector2(0, 1), false, 0.0)

	_camera = Camera2D.new()
	_camera.enabled = true
	_camera.ignore_rotation = true
	add_child(_camera)
	_apply_camera(true)


func sync_actor(p: Vector3, facing: Vector2, moving: bool, travel: float) -> void:
	if _actor == null:
		return
	_actor.sync(p, facing, moving, travel)
	if _mode == CameraMode.FOLLOW:
		_camera_target = Iso.to_screen(p + Vector3(0, 0.9, 0))


func set_camera_mode(mode: CameraMode) -> void:
	_mode = mode
	_apply_camera(true)


func set_actor_visible(v: bool) -> void:
	if _actor:
		_actor.visible = v


func highlight(prop_id: String) -> void:
	if prop_id == _highlighted:
		return
	if _props.has(_highlighted):
		_props[_highlighted].highlighted = false
	_highlighted = prop_id
	if _props.has(_highlighted):
		_props[_highlighted].highlighted = true


func prop_anchor(prop_id: String) -> Vector2:
	if not _props.has(prop_id):
		return Vector2.ZERO
	var p: PropDef = _props[prop_id].prop
	return Iso.to_screen(p.origin + Vector3(p.size.x * 0.5, p.size.y, p.size.z * 0.5))


func _process(delta: float) -> void:
	if _camera == null or _mode != CameraMode.FOLLOW:
		return
	_camera.position = _camera.position.lerp(
		_clamp_camera(_camera_target), 1.0 - exp(-CAMERA_LAG * delta))


func _apply_camera(snap: bool) -> void:
	if _camera == null or room == null:
		return
	var bounds := room.screen_bounds()
	match _mode:
		CameraMode.FIT:
			var vp := get_viewport_rect().size
			var z := minf(vp.x / bounds.size.x, vp.y / bounds.size.y) \
				* FIT_PADDING * fit_zoom_boost
			_camera.zoom = Vector2(z, z)
			_camera.position = bounds.get_center() + fit_offset
			_camera_target = _camera.position
		CameraMode.FOLLOW:
			_camera.zoom = Vector2(FOLLOW_ZOOM, FOLLOW_ZOOM)
			if snap:
				_camera.position = _clamp_camera(_camera_target)
		CameraMode.FREE:
			pass  # The editor drives the camera directly.


## Keep the room filling the frame; if the room is smaller than the view on an
## axis, centre it there instead of sliding empty space into shot.
func _clamp_camera(target: Vector2) -> Vector2:
	var bounds := room.screen_bounds().grow(48.0)
	var half := get_viewport_rect().size * 0.5 / _camera.zoom
	var out := target
	if bounds.size.x <= half.x * 2.0:
		out.x = bounds.get_center().x
	else:
		out.x = clampf(target.x, bounds.position.x + half.x, bounds.end.x - half.x)
	if bounds.size.y <= half.y * 2.0:
		out.y = bounds.get_center().y
	else:
		out.y = clampf(target.y, bounds.position.y + half.y, bounds.end.y - half.y)
	return out


## Create, update or remove the PointLight2D for a prop, tracked by id so the
## editor can retune lights live without rebuilding the whole room.
func _sync_light(prop: PropDef) -> void:
	var wants := prop.light_energy > 0.0 and prop.light_color.a > 0.0 and prop.id != ""
	var has := _lights.has(prop.id)
	if not wants:
		if has:
			_lights[prop.id].queue_free()
			_lights.erase(prop.id)
		return
	var light: PointLight2D
	if has:
		light = _lights[prop.id]
	else:
		light = PointLight2D.new()
		light.texture = _light_texture
		light.blend_mode = Light2D.BLEND_MODE_ADD
		add_child(light)
		_lights[prop.id] = light
	light.color = prop.light_color
	light.energy = prop.light_energy
	# light_scale is authored as a radius in world units; the falloff texture is
	# 256 px wide and one world unit is Iso.TILE_W across, hence the conversion.
	light.texture_scale = prop.light_scale * Iso.TILE_W * 2.0 / 256.0
	light.position = Iso.to_screen(prop.centre() + prop.light_offset)


# -- Editor support -------------------------------------------------------------
# The editor mutates PropDefs in place and tells the view what changed. Nothing
# below is used by gameplay scenes.

func add_prop(prop: PropDef) -> void:
	var node := Prop2D.new()
	add_child(node)
	node.setup(prop)
	if prop.id != "":
		_props[prop.id] = node
	_sync_light(prop)


func remove_prop(prop_id: String) -> void:
	if _highlighted == prop_id:
		highlight("")
	if _props.has(prop_id):
		_props[prop_id].queue_free()
		_props.erase(prop_id)
	if _lights.has(prop_id):
		_lights[prop_id].queue_free()
		_lights.erase(prop_id)


## Re-read a mutated PropDef: recompute depth, redraw, retune its light.
func refresh_prop(prop_id: String) -> void:
	if not _props.has(prop_id):
		return
	var node: Node2D = _props[prop_id]
	node.setup(node.prop)
	node.highlighted = _highlighted == prop_id
	_sync_light(node.prop)


## Editor toggle: see the room without the night grade, for judging base colours.
func set_ambient_enabled(on: bool) -> void:
	_ambient_on = on
	if _modulate:
		_modulate.color = room.ambient_tint if on else Color.WHITE


func camera_pan(screen_delta: Vector2) -> void:
	if _camera:
		_camera.position -= screen_delta / _camera.zoom.x


func camera_zoom_by(factor: float) -> void:
	if _camera:
		var z := clampf(_camera.zoom.x * factor, 0.35, 3.5)
		_camera.zoom = Vector2(z, z)


func camera_center_ground() -> Vector3:
	if _camera == null:
		return Vector3.ZERO
	return Iso.to_ground(_camera.position)


func get_camera_state() -> Dictionary:
	if _camera == null:
		return {}
	return {"pos": _camera.position, "zoom": _camera.zoom.x}


func set_camera_state(state: Dictionary) -> void:
	if _camera == null or state.is_empty():
		return
	_camera.position = state["pos"]
	var z: float = state["zoom"]
	_camera.zoom = Vector2(z, z)


## One shared radial falloff, generated so the repo carries no binary art yet.
func _make_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	# Tight falloff. A broad one stacks additively across six lights and washes
	# the whole room pink, which loses the "pools of light" read entirely.
	gradient.offsets = PackedFloat32Array([0.0, 0.22, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1), Color(1, 1, 1, 0.42), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)
	])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
