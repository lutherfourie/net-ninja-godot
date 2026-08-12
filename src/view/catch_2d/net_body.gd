extends AnimatableBody2D
## The dangling net.
##
## Control is one axis: drag left and right, and the net tips into the can at the
## far right on its own. That keeps a thumb on a phone in charge of exactly one
## thing while the physics does the interesting part.
##
## The handle and rim lean with horizontal speed, but the *collision* never
## rotates. PDF p.12 asks for cloth weight "without making touch control laggy",
## and a tilting catch mouth is exactly the kind of thing that reads as
## unfairness. The lean is honestly cosmetic, and it is enough.

signal ball_settled(body: Node)

const MAX_LEAN := 0.13
const FOLLOW := 16.0

var target_x := Playfield.WIDTH * 0.5

var _lean := 0.0
var _sensor: Area2D
var _last_x := 0.0
var _speed := 0.0


func lean() -> float:
	return _lean


func _ready() -> void:
	sync_to_physics = true
	# Behind the balls; net_front.gd draws the near mesh over them.
	z_index = -1
	collision_layer = Playfield.LAYER_NET
	collision_mask = Playfield.LAYER_BALL
	position = Vector2(target_x, Playfield.RAIL_Y)
	_last_x = position.x

	var half := Playfield.NET_HALF_W
	var depth := Playfield.NET_DEPTH
	var t := Playfield.NET_WALL

	_wall(Vector2(-half - t * 0.5, depth * 0.4), Vector2(t, depth * 1.25))
	_wall(Vector2(half + t * 0.5, depth * 0.4), Vector2(t, depth * 1.25))
	_wall(Vector2(0, depth + t * 0.5), Vector2(half * 2.0 + t * 2.0, t))

	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = Playfield.LAYER_BALL
	_sensor.monitoring = true
	var sensor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(half * 2.0, depth + 26.0)
	sensor_shape.shape = rect
	sensor_shape.position = Vector2(0, depth * 0.5)
	_sensor.add_child(sensor_shape)
	_sensor.body_entered.connect(_on_body_entered)
	_sensor.body_exited.connect(_on_body_exited)
	add_child(_sensor)


func _wall(at: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = at
	add_child(shape)


func _physics_process(delta: float) -> void:
	var want := clampf(target_x, Playfield.NET_MIN_X, Playfield.NET_MAX_X)
	var next_x: float = lerpf(position.x, want, 1.0 - exp(-FOLLOW * delta))
	_speed = (next_x - _last_x) / maxf(delta, 0.0001)
	_last_x = next_x

	var tip := Playfield.tip_amount(next_x)
	position = Vector2(next_x, Playfield.RAIL_Y + tip * Playfield.TIP_DROP)

	var want_lean := clampf(-_speed * 0.00022, -MAX_LEAN, MAX_LEAN) + tip * 0.30
	_lean = lerpf(_lean, want_lean, 1.0 - exp(-9.0 * delta))
	queue_redraw()


## Balls currently held, ignoring any still moving fast enough to be passing through.
func held() -> Array:
	var out := []
	for body in _sensor.get_overlapping_bodies():
		if is_instance_valid(body):
			out.append(body)
	return out


func load_count() -> int:
	return _sensor.get_overlapping_bodies().size()


func _on_body_entered(body: Node) -> void:
	if body.has_method("pop"):
		body.pop()
	ball_settled.emit(body)


func _on_body_exited(_body: Node) -> void:
	pass


func _draw() -> void:
	var half: float = Playfield.NET_HALF_W
	var depth: float = Playfield.NET_DEPTH
	var frame: Color = Palette.HEARTH_CREAM
	var mesh: Color = Palette.SPECTRAL_MINT * Color(1, 1, 1, 0.42)
	var pole: Color = Color("6b4630")

	draw_set_transform(Vector2.ZERO, _lean, Vector2.ONE)

	# Handle, running up out of frame toward Ami's hands.
	draw_line(Vector2(0, -14), Vector2(0, -230), pole, 11.0)
	draw_line(Vector2(0, -14), Vector2(0, -230), Color(0, 0, 0, 0.25), 3.0)

	# Rim.
	draw_line(Vector2(-half - 6, -8), Vector2(half + 6, -8), frame, 7.0)

	# Bag: two side ropes and a floor, with a diagonal mesh between them.
	var left_top := Vector2(-half, -6)
	var right_top := Vector2(half, -6)
	var left_bottom := Vector2(-half + 8, depth)
	var right_bottom := Vector2(half - 8, depth)
	draw_line(left_top, left_bottom, frame, 5.0)
	draw_line(right_top, right_bottom, frame, 5.0)
	draw_line(left_bottom, right_bottom, frame, 5.0)

	# Far side of the mesh only — the near side lives in net_front.gd.
	for i in 7:
		var t := float(i) / 6.0
		draw_line(left_top.lerp(left_bottom, t), right_top.lerp(right_bottom, t), mesh, 1.6)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
