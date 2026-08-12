extends Node2D
## The room editor: greybox Ami's flat without touching code or relaunching.
##
## Reached with F1 from the hub. Works on the same RoomModel the game plays,
## through the same Room2DView the game renders with — what you see here is
## exactly what ships. Saves JSON via RoomIO; the hub and menu load it back.
##
## Undo is a snapshot stack of serialized rooms. Room dictionaries are a few KB,
## edits are human-speed, and restoring is "load a save" — the boring design
## that cannot desync.

const Room2DView := preload("res://src/view/room_2d/room_2d_view.gd")
const EditorGrid := preload("res://src/editor/editor_grid.gd")
const PropInspector := preload("res://src/editor/prop_inspector.gd")

const ROOM_ID := "ami_apartment"
const SNAP := 0.05
const UNDO_LIMIT := 60
const PANEL_W := 292.0

var room: RoomModel

var _view          # Room2DView
var _grid          # EditorGrid
var _inspector     # PropInspector
var _title: Label
var _status: Label
var _help: Label

var _sel: PropDef = null
var _undo: Array[Dictionary] = []
var _dirty := false
var _ambient_on := true

# Input state.
var _panning := false
var _dragging := false
var _drag_moved := false
var _drag_undo_pushed := false
var _press_screen := Vector2.ZERO
var _press_ms := 0
var _drag_ground := Vector3.ZERO
var _drag_origin := Vector3.ZERO
var _new_prop_serial := 0


func _ready() -> void:
	room = RoomIO.load_or_build(ROOM_ID)

	_view = Room2DView.new()
	add_child(_view)

	_grid = EditorGrid.new()
	_view.add_child(_grid)

	_rebuild(true)

	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	_build_ui(ui)
	_update_title()


func _rebuild(first := false) -> void:
	var cam: Dictionary = {} if first else _view.get_camera_state()
	_view.setup(room)
	_view.set_actor_visible(false)
	if first:
		_view.set_camera_mode(RoomView.CameraMode.FIT)
	_view.set_camera_mode(RoomView.CameraMode.FREE)
	if not first:
		_view.set_camera_state(cam)
	_view.set_ambient_enabled(_ambient_on)

	# The grid was freed with the rest of the view's children; re-add it.
	_grid = EditorGrid.new()
	_view.add_child(_grid)
	_grid.set_room(room)

	if _sel != null:
		_view.highlight(_sel.id)


# -- UI -------------------------------------------------------------------------

func _build_ui(ui: CanvasLayer) -> void:
	var bar := ColorRect.new()
	bar.color = Color(Palette.MIDNIGHT_INK.r, Palette.MIDNIGHT_INK.g,
		Palette.MIDNIGHT_INK.b, 0.88)
	bar.size = Vector2(Tokens.DESIGN_SIZE.x, 54.0)
	ui.add_child(bar)

	_title = Label.new()
	_title.add_theme_font_override("font", NNFonts.or_default(NNFonts.heading(), _title))
	_title.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]) + 2)
	_title.add_theme_color_override("font_color", Palette.HEARTH_CREAM)
	_title.position = Vector2(12, 14)
	# The action row owns the right side of the bar; keep the title clear of it.
	_title.custom_minimum_size = Vector2(150, 0)
	_title.clip_text = true
	_title.size = Vector2(160, 24)
	ui.add_child(_title)

	var actions := [
		["SAVE", func() -> void: _save()],
		["ADD", func() -> void: _add_prop()],
		["DUP", func() -> void: _duplicate_sel()],
		["DEL", func() -> void: _delete_sel()],
		["UNDO", func() -> void: _do_undo()],
		["LIGHT", func() -> void: _toggle_ambient()],
		["PLAY", func() -> void: _play()],
	]
	var x := Tokens.DESIGN_SIZE.x - 8.0
	for i in range(actions.size() - 1, -1, -1):
		var b := NNButton.new()
		b.text = actions[i][0]
		b.variant = NNButton.Variant.PRIMARY if actions[i][0] == "PLAY" else NNButton.Variant.GHOST
		b.ears = false
		b.font_size = int(Tokens.TYPE["meta"])
		var w := 64.0 if actions[i][0] != "LIGHT" else 70.0
		b.custom_minimum_size = Vector2(w, 36.0)
		b.size = Vector2(w, 36.0)
		x -= w + 6.0
		b.position = Vector2(x, 9.0)
		b.pressed.connect(actions[i][1])
		ui.add_child(b)

	_inspector = PropInspector.new()
	_inspector.position = Vector2(Tokens.DESIGN_SIZE.x - PANEL_W - 8.0, 62.0)
	_inspector.size = Vector2(PANEL_W, Tokens.DESIGN_SIZE.y - 150.0)
	_inspector.before_change.connect(_push_undo)
	_inspector.edited.connect(_on_inspector_edited)
	_inspector.structural.connect(_on_inspector_structural)
	ui.add_child(_inspector)

	_status = Label.new()
	_status.add_theme_font_override("font", NNFonts.or_default(NNFonts.mono(), _status))
	_status.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]))
	_status.add_theme_color_override("font_color", Palette.SPECTRAL_MINT)
	_status.position = Vector2(12, Tokens.DESIGN_SIZE.y - 78.0)
	_status.modulate.a = 0.0
	ui.add_child(_status)

	_help = Label.new()
	_help.text = "click select · click again cycle · drag move · shift+drag height · " \
		+ "arrows nudge · R/F raise/lower\nwheel zoom · RMB pan · S spawn@mouse · " \
		+ "TAB panel · G grid · Ctrl+Z undo · Ctrl+S save · F1 play"
	_help.add_theme_font_override("font", NNFonts.or_default(NNFonts.mono(), _help))
	_help.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]) - 2)
	_help.add_theme_color_override("font_color", Palette.HEARTH_CREAM * Color(1, 1, 1, 0.45))
	_help.position = Vector2(12, Tokens.DESIGN_SIZE.y - 52.0)
	ui.add_child(_help)


func _update_title() -> void:
	_title.text = "EDIT %s%s" % [ROOM_ID, "*" if _dirty else ""]


func _toast(text: String) -> void:
	_status.text = text
	var t := create_tween()
	t.tween_property(_status, "modulate:a", 1.0, 0.1)
	t.tween_interval(2.2)
	t.tween_property(_status, "modulate:a", 0.0, 0.4)


# -- Selection / mutation -------------------------------------------------------

func _select(p: PropDef) -> void:
	_sel = p
	_view.highlight(p.id if p != null else "")
	_inspector.set_target(p)


func _push_undo() -> void:
	_undo.append(RoomIO.room_to_dict(room))
	if _undo.size() > UNDO_LIMIT:
		_undo.pop_front()
	_dirty = true
	_update_title()


func _do_undo() -> void:
	if _undo.is_empty():
		_toast("nothing to undo")
		return
	var keep_id := _sel.id if _sel != null else ""
	room = RoomIO.room_from_dict(_undo.pop_back())
	_sel = null
	for p in room.props:
		if p.id == keep_id:
			_sel = p
			break
	_rebuild()
	_inspector.set_target(_sel)
	_dirty = true
	_update_title()
	_toast("undo (%d left)" % _undo.size())


func _save() -> void:
	var path := RoomIO.save_room(room)
	if path == "":
		_toast("SAVE FAILED")
		return
	_dirty = false
	_update_title()
	_toast("saved  %s" % path)


func _play() -> void:
	if _dirty:
		_save()
	SceneRouter.goto("room")


func _toggle_ambient() -> void:
	_ambient_on = not _ambient_on
	_view.set_ambient_enabled(_ambient_on)


func _add_prop() -> void:
	_push_undo()
	var p := PropDef.new()
	p.id = _unique_id("box")
	p.kind = PropDef.Kind.BOX
	var at: Vector3 = _view.camera_center_ground()
	p.origin = Vector3(snappedf(at.x - 0.5, SNAP), 0.0, snappedf(at.z - 0.5, SNAP))
	p.size = Vector3(1, 1, 1)
	p.base_color = Color("6b4630")
	room.add(p)
	_view.add_prop(p)
	_select(p)
	_toast("added %s" % p.id)


func _duplicate_sel() -> void:
	if _sel == null:
		return
	_push_undo()
	var copy: PropDef = _sel.duplicate()
	copy.id = _unique_id(_sel.id.rstrip("0123456789_"))
	copy.origin += Vector3(0.5, 0, 0.5)
	room.add(copy)
	_view.add_prop(copy)
	_select(copy)
	_toast("duplicated as %s" % copy.id)


func _delete_sel() -> void:
	if _sel == null:
		return
	_push_undo()
	var id := _sel.id
	room.props.erase(_sel)
	_view.remove_prop(id)
	_select(null)
	_toast("deleted %s" % id)


func _unique_id(base: String) -> String:
	var stem := base if base != "" else "prop"
	var existing := {}
	for p in room.props:
		existing[p.id] = true
	while true:
		_new_prop_serial += 1
		var candidate := "%s_%d" % [stem, _new_prop_serial]
		if not existing.has(candidate):
			return candidate
	return stem  # unreachable


func _on_inspector_edited() -> void:
	if _sel != null:
		_view.refresh_prop(_sel.id)
	_grid.queue_redraw()


func _on_inspector_structural() -> void:
	_rebuild()
	_inspector.refresh()


# -- Picking and dragging -------------------------------------------------------

func _ground(screen: Vector2) -> Vector3:
	return Iso.to_ground(_view.make_canvas_position_local(screen))


## Props under a ground point, smallest footprint first so clutter beats walls.
func _candidates(g: Vector3) -> Array[PropDef]:
	var out: Array[PropDef] = []
	for p in room.props:
		if p.footprint().grow(0.12).has_point(Vector2(g.x, g.z)):
			out.append(p)
	out.sort_custom(func(a: PropDef, b: PropDef) -> bool:
		return a.footprint().get_area() < b.footprint().get_area())
	return out


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_view.camera_zoom_by(1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_view.camera_zoom_by(1.0 / 1.1)
			MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
				_panning = event.pressed
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_press(event.position)
				else:
					_release(event.position)
	elif event is InputEventMouseMotion:
		if _panning:
			_view.camera_pan(event.relative)
		elif _dragging and _sel != null:
			_drag_to(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event)


func _press(screen: Vector2) -> void:
	_press_screen = screen
	_press_ms = Time.get_ticks_msec()
	var g := _ground(screen)
	var cands := _candidates(g)
	if cands.is_empty():
		_select(null)
		return
	if _sel == null or not cands.has(_sel):
		_select(cands[0])
	_dragging = true
	_drag_moved = false
	_drag_undo_pushed = false
	_drag_ground = g
	_drag_origin = _sel.origin


func _drag_to(event: InputEventMouseMotion) -> void:
	if not _drag_undo_pushed:
		# Undo captures the pre-drag room exactly once per gesture.
		_push_undo()
		_drag_undo_pushed = true
	if event.shift_pressed:
		var dy := (_press_screen.y - event.position.y) / Iso.TILE_Z
		_sel.origin.y = maxf(snappedf(_drag_origin.y + dy, SNAP), 0.0)
	else:
		var g := _ground(event.position)
		var delta := g - _drag_ground
		_sel.origin.x = snappedf(_drag_origin.x + delta.x, SNAP)
		_sel.origin.z = snappedf(_drag_origin.z + delta.z, SNAP)
	_drag_moved = true
	_view.refresh_prop(_sel.id)
	_inspector.refresh()


func _release(screen: Vector2) -> void:
	var was_quick := Time.get_ticks_msec() - _press_ms < 220 \
		and screen.distance_to(_press_screen) < 6.0
	if _dragging and not _drag_moved and was_quick and _sel != null:
		# Cycle through overlapping props on repeated quick clicks.
		var cands := _candidates(_ground(screen))
		var i := cands.find(_sel)
		if i >= 0 and cands.size() > 1:
			_select(cands[(i + 1) % cands.size()])
	_dragging = false


func _key(event: InputEventKey) -> void:
	var step := 0.5 if event.shift_pressed else 0.1
	match event.keycode:
		KEY_LEFT: _nudge(Vector3(-step, 0, 0))
		KEY_RIGHT: _nudge(Vector3(step, 0, 0))
		KEY_UP: _nudge(Vector3(0, 0, -step))
		KEY_DOWN: _nudge(Vector3(0, 0, step))
		KEY_R: _nudge(Vector3(0, 0.1, 0))
		KEY_F: _nudge(Vector3(0, -0.1, 0))
		KEY_DELETE, KEY_BACKSPACE: _delete_sel()
		KEY_D:
			if event.ctrl_pressed:
				_duplicate_sel()
		KEY_Z:
			if event.ctrl_pressed:
				_do_undo()
		KEY_S:
			if event.ctrl_pressed:
				_save()
			else:
				_set_spawn_at_mouse()
		KEY_TAB: _inspector.visible = not _inspector.visible
		KEY_G: _grid.visible = not _grid.visible
		KEY_L: _toggle_ambient()
		KEY_COMMA: _step_selection(-1)
		KEY_PERIOD: _step_selection(1)
		KEY_F1, KEY_ESCAPE: _play()


func _nudge(delta: Vector3) -> void:
	if _sel == null:
		return
	_push_undo()
	_sel.origin += delta
	_sel.origin.y = maxf(_sel.origin.y, 0.0)
	_view.refresh_prop(_sel.id)
	_inspector.refresh()


func _set_spawn_at_mouse() -> void:
	_push_undo()
	var g := _ground(get_viewport().get_mouse_position())
	room.spawn = Vector3(snappedf(g.x, SNAP), 0.0, snappedf(g.z, SNAP))
	_grid.queue_redraw()
	_toast("spawn moved")


## Walk the prop list linearly — the escape hatch for anything the ground-plane
## pick cannot reach (wall art, shelves, lights high on the wall).
func _step_selection(dir: int) -> void:
	if room.props.is_empty():
		return
	var i := room.props.find(_sel) if _sel != null else -1
	var next: PropDef = room.props[(i + dir + room.props.size()) % room.props.size()]
	_select(next)
	_toast(next.id)
