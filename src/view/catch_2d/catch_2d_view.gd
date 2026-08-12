extends Node2D
## The catch playfield: physics, presentation and input for one contract.
##
## Runs in design space (720 x 1280) with no camera, so every number here is the
## number in Playfield. The model is handed in from the scene and told what
## happened; it is never read for anything the physics already knows.

const SpectralBall := preload("res://src/view/catch_2d/spectral_ball.gd")
const NetBody := preload("res://src/view/catch_2d/net_body.gd")
const NetFront := preload("res://src/view/catch_2d/net_front.gd")
const CursedCat := preload("res://src/view/catch_2d/cursed_cat.gd")
const HauntedBin := preload("res://src/view/catch_2d/haunted_bin.gd")
const CatchBackdrop := preload("res://src/view/catch_2d/catch_backdrop.gd")

## Hard ceiling on live bodies. A stuck run should get harder, not slower.
const MAX_BALLS := 46

var model: CatchModel

# These four are untyped on purpose: each is a script-defined node whose API
# (telegraph, held, celebrate, set_flashes) is not on Node2D.
var _cat
var _net
var _bin
var _backdrop
var _balls: Node2D
var _dragging := false
var _drop_flash := 0.0
var _slam_flash := 0.0


func setup(catch_model: CatchModel) -> void:
	model = catch_model

	_backdrop = CatchBackdrop.new()
	_backdrop.z_index = -8
	add_child(_backdrop)

	_cat = CursedCat.new()
	add_child(_cat)

	_build_bounds()

	_bin = HauntedBin.new()
	_bin.z_index = 2
	add_child(_bin)

	_balls = Node2D.new()
	add_child(_balls)

	_net = NetBody.new()
	add_child(_net)
	var front := NetFront.new()
	front.net = _net
	_net.add_child(front)

	model.slam_telegraphed.connect(_on_telegraph)
	model.slam_landed.connect(_on_slam)
	set_process_unhandled_input(true)


# -- Scenery colliders ----------------------------------------------------------

func _build_bounds() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = Playfield.LAYER_SOLID
	solid.collision_mask = 0
	add_child(solid)
	_wall(solid, Vector2(-Playfield.WALL_T * 0.5, Playfield.HEIGHT * 0.5),
		Vector2(Playfield.WALL_T, Playfield.HEIGHT * 2.0))
	_wall(solid, Vector2(Playfield.WIDTH + Playfield.WALL_T * 0.5, Playfield.HEIGHT * 0.5),
		Vector2(Playfield.WALL_T, Playfield.HEIGHT * 2.0))
	_wall(solid, Vector2(Playfield.WIDTH * 0.5, Playfield.FLOOR_Y + 30.0),
		Vector2(Playfield.WIDTH + 80.0, 60.0))

	# Anything touching the floor is a drop. This is the only failure state.
	var floor_sensor := Area2D.new()
	floor_sensor.collision_layer = 0
	floor_sensor.collision_mask = Playfield.LAYER_BALL
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(Playfield.WIDTH + 80.0, 46.0)
	shape.shape = rect
	shape.position = Vector2(Playfield.WIDTH * 0.5, Playfield.FLOOR_Y - 12.0)
	floor_sensor.add_child(shape)
	floor_sensor.body_entered.connect(_on_floor_hit)
	add_child(floor_sensor)


func _wall(parent: StaticBody2D, at: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	parent.add_child(shape)


# -- Model callbacks ------------------------------------------------------------

func _on_telegraph(at_x: float) -> void:
	_cat.telegraph(at_x)


func _on_slam(count: int, _at_x: float) -> void:
	_cat.impact()
	_slam_flash = 1.0
	var origin: Vector2 = _cat.paw_point()
	var rules := model.rules
	for i in count:
		if _balls.get_child_count() >= MAX_BALLS:
			break
		var spread := rules.burst_spread
		var t := 0.0 if count == 1 else (float(i) / float(count - 1)) * 2.0 - 1.0
		var ball := SpectralBall.new()
		ball.z_index = 3
		_balls.add_child(ball)
		ball.configure(rules)
		ball.position = origin + Vector2(t * spread, randf_range(-24.0, 24.0))
		ball.linear_velocity = Vector2(t * rules.burst_impulse, randf_range(30.0, 110.0))


func _on_floor_hit(body: Node) -> void:
	if not is_instance_valid(body) or not body.is_inside_tree():
		return
	_drop_flash = 1.0
	body.queue_free()
	model.register_drop()


# -- Frame ----------------------------------------------------------------------

func _process(delta: float) -> void:
	if model == null:
		return
	model.tick(delta)

	# Keyboard and gamepad share the rail with the drag.
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.05:
		_net.target_x = clampf(_net.target_x + axis * 900.0 * delta,
			Playfield.NET_MIN_X, Playfield.NET_MAX_X)

	model.report_net_load(_net.load_count())

	if _net.position.x >= Playfield.DUMP_X:
		_dump()

	_cull()

	_drop_flash = maxf(_drop_flash - delta * 2.2, 0.0)
	_slam_flash = maxf(_slam_flash - delta * 3.0, 0.0)
	_backdrop.set_flashes(_slam_flash, _drop_flash)


func _dump() -> void:
	var held: Array = _net.held()
	if held.is_empty():
		return
	var gained := model.register_dump(held.size())
	if gained <= 0.0 and model.running:
		return
	for body in held:
		if is_instance_valid(body):
			body.queue_free()
	_bin.celebrate(gained)


func _cull() -> void:
	for child in _balls.get_children():
		if child.position.y > Playfield.HEIGHT + 160.0:
			child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		if event.pressed:
			_grab(event.position)
	elif event is InputEventScreenDrag:
		_grab(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_grab(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_grab(event.position)


func _grab(screen_position: Vector2) -> void:
	_net.target_x = clampf(make_canvas_position_local(screen_position).x,
		Playfield.NET_MIN_X, Playfield.NET_MAX_X)
