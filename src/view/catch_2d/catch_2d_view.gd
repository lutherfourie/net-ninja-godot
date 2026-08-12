extends Node2D
## The catch playfield: net-lab net play on Godot physics.
##
## Runs in design space (720 x 1280) with no camera. CatchModel still owns the
## cadence, drop limit and cleanse bar; what changed in the net-lab port is HOW
## catches and dumps happen — balls physically enter the net's bag, and banking
## means physically landing in the can (a pour, or a lucky deflection). The
## model is told what happened; it never simulates anything the physics already
## knows.

const SpectralBall := preload("res://src/view/catch_2d/spectral_ball.gd")
const NetRig := preload("res://src/view/catch_2d/net_rig.gd")
const CursedCat := preload("res://src/view/catch_2d/cursed_cat.gd")
const HauntedBin := preload("res://src/view/catch_2d/haunted_bin.gd")
const CatchBackdrop := preload("res://src/view/catch_2d/catch_backdrop.gd")

## Hard ceiling on live bodies. A stuck run should get harder, not slower.
const MAX_BALLS := 46
const KEY_NET_SPEED := 1050.0

var model: CatchModel

# Script-defined nodes whose APIs are not on Node2D — untyped on purpose.
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
	_bin.banked.connect(_on_banked)
	add_child(_bin)

	_balls = Node2D.new()
	add_child(_balls)

	_net = NetRig.new()
	_net.target = Vector2(Playfield.WIDTH * 0.42, Playfield.RAIL_Y)
	_net.position = _net.target
	_net.release_container = _balls
	add_child(_net)

	model.slam_telegraphed.connect(_on_telegraph)
	model.slam_landed.connect(_on_slam)
	set_process_unhandled_input(true)


func net_rig() -> Node2D:
	return _net


# -- Scenery colliders ----------------------------------------------------------

func _build_bounds() -> void:
	# Side walls bounce items back into play — net-lab world.wallRestitution.
	var walls := StaticBody2D.new()
	walls.collision_layer = Playfield.LAYER_SOLID
	walls.collision_mask = 0
	var wall_mat := PhysicsMaterial.new()
	wall_mat.bounce = NetLabRules.WALL_RESTITUTION
	wall_mat.friction = 0.1
	walls.physics_material_override = wall_mat
	add_child(walls)
	_wall(walls, Vector2(-Playfield.WALL_T * 0.5, Playfield.HEIGHT * 0.5),
		Vector2(Playfield.WALL_T, Playfield.HEIGHT * 2.0))
	_wall(walls, Vector2(Playfield.WIDTH + Playfield.WALL_T * 0.5, Playfield.HEIGHT * 0.5),
		Vector2(Playfield.WALL_T, Playfield.HEIGHT * 2.0))

	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = Playfield.LAYER_SOLID
	floor_body.collision_mask = 0
	add_child(floor_body)
	_wall(floor_body, Vector2(Playfield.WIDTH * 0.5, Playfield.FLOOR_Y + 30.0),
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


func _on_banked(body: Node) -> void:
	if not is_instance_valid(body) or not body.is_inside_tree():
		return
	body.queue_free()
	var gained := model.register_dump(1)
	_bin.celebrate(gained)


# -- Frame ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	# Magnet assist: falling balls near an un-full mouth get a gentle pull
	# toward its centre, strongest up close, zero at the radius edge. Pure
	# config maths, applied at the physics rate (netCatcher.applyMagnet).
	if not NetLabRules.MAGNET_ENABLED or _net == null or _net.is_full():
		return
	var r := NetLabRules.magnet_radius_px()
	var mouth: Vector2 = _net.position
	for ball in _balls.get_children():
		if not is_instance_valid(ball):
			continue
		if ball.linear_velocity.y < -60.0:
			continue  # rising off a bounce — let the juggle live
		var d := mouth.distance_to(ball.position)
		if d >= r or d < 1.0:
			continue
		var pull := NetLabRules.magnet_strength_px() * (1.0 - d / r)
		ball.linear_velocity += (mouth - ball.position) / d * pull * delta


func _process(delta: float) -> void:
	if model == null:
		return
	model.tick(delta)

	# Keyboard and gamepad steer the same target the pointer drags.
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if axis.length_squared() > 0.003:
		_net.target = Playfield.clamp_net(_net.target + axis * KEY_NET_SPEED * delta)

	model.report_net_load(_net.held_count())

	_cull()

	_drop_flash = maxf(_drop_flash - delta * 2.2, 0.0)
	_slam_flash = maxf(_slam_flash - delta * 3.0, 0.0)
	_backdrop.set_flashes(_slam_flash, _drop_flash)


func _cull() -> void:
	for child in _balls.get_children():
		if child.position.y > Playfield.HEIGHT + 160.0 \
				or absf(child.position.x - Playfield.WIDTH * 0.5) > Playfield.WIDTH:
			child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		if event.pressed:
			_grab(event.position, true)
	elif event is InputEventScreenDrag:
		_grab(event.position, true)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_grab(event.position, false)
	elif event is InputEventMouseMotion and _dragging:
		_grab(event.position, false)


func _grab(screen_position: Vector2, is_touch: bool) -> void:
	var local := make_canvas_position_local(screen_position)
	if is_touch:
		# net-lab input.touchOffsetY: the net rides above the fingertip so the
		# hand never occludes the catch.
		local.y -= NetLabRules.touch_offset_px()
	_net.target = Playfield.clamp_net(local)
