extends AnimatableBody2D
## The net, rebuilt on net-lab's model with Godot doing what Godot does best.
##
## Division of labour, and where the lab's code went:
##
##   net-lab netCatcher.step()   -> ported verbatim below (_follow + _facing):
##                                  fill-weighted follow lerp, smoothed facing,
##                                  weighted self-righting, clamp-up, pour zone
##                                  authority. This is the FEEL and it is maths,
##                                  so it stays maths.
##   tryRimBounce (torus test)   -> real rim colliders + PhysicsMaterial. The
##                                  lab hand-rolled deflection because it had no
##                                  physics engine; we have one, and a kinematic
##                                  body's stroke velocity transfers into balls
##                                  natively (that IS net.rim.velTransfer).
##   tryCatch (mouth-plane sweep)-> balls physically enter the open mouth and
##                                  rest in the bag. Held = bodies in the bag
##                                  sensor. No teleporting onto the net.
##   fullBounce (webDeflect)     -> the LID: a collider across the mouth that
##                                  engages at capacity. Full net = taut webbing,
##                                  balls clank off it and stay juggleable.
##   tryPour                     -> the pour gates OPEN the lid and hand facing
##                                  authority to the stroke; the haul then falls
##                                  out under gravity and the bin banks whatever
##                                  lands in. Nothing is spliced out of a list.
##
## Facing is kept in net-lab's y-up convention internally and converted at the
## node boundary, so the ported block diffs cleanly against netCatcher.ts.

signal pour_state_changed(pouring: bool)
signal caught(body: Node)

const BAG_WALL_T := 16.0

## Where the pointer wants the mouth centre (screen px).
var target := Vector2.ZERO

## Where released (poured) balls are reparented to — set by the view.
var release_container: Node2D

# Ported state (net-lab names).
var facing := Vector2(0, 1)      # y-up, unit — the mouth normal
var vel_px := Vector2.ZERO
var _smooth_vel := Vector2.ZERO
var _catch_carry := 0.0

## netCatcher.held, literally: captured balls freeze and ride the rig. The lab
## glued held items to the net (`item.pos.copy(this.pos)`); a loose physical
## cargo got ejected by every braking stroke, so the port glues them too —
## flight, rim juggling and the pour stay fully physical.
var held_items: Array = []

var _bag: Area2D
var _lid: CollisionShape2D
var _pouring := false
var _front: Node2D


func _ready() -> void:
	# Kinematic teleport, sync_to_physics OFF. Hard-won, in sequence: with sync
	# ON this build clobbers node transform writes from _physics_process AND
	# _process (the smoke harness caught the net never moving — a bug v0.2
	# shipped with, invisibly); a velocity-driven RigidBody2D fought the solver
	# instead of obeying it. Plain per-tick transform writes on an
	# AnimatableBody2D with sync OFF are guaranteed motion; balls keep CCD and
	# the bag walls are thick, so contact quality holds at play speeds.
	sync_to_physics = false
	z_index = -1
	collision_layer = Playfield.LAYER_NET
	collision_mask = Playfield.LAYER_BALL

	var mat := PhysicsMaterial.new()
	# One material covers rim AND bag (Godot materials are per-body): springy
	# enough that rim clips juggle, calm enough that the bag doesn't eject its
	# own catch.
	mat.bounce = 0.30
	mat.friction = 0.5
	physics_material_override = mat

	_build_colliders()
	position = target


func _build_colliders() -> void:
	var r := NetLabRules.mouth_radius_px()
	var depth := NetLabRules.pouch_depth_px()
	var bottom := r * NetLabRules.POUCH_TAPER

	# Rim tips: the hoop's tube, as real circles the balls can clip and juggle on.
	for side: float in [-1.0, 1.0]:
		var tip := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 9.0
		tip.shape = c
		tip.position = Vector2(side * r, 0)
		add_child(tip)

	# Bag wall: a U of thick segments from rim tip to tapered bottom. Local space:
	# mouth spans the X axis at y=0, interior is +Y, mouth normal is -Y.
	var profile := PackedVector2Array([
		Vector2(-r, 0), Vector2(-r * 0.90, depth * 0.35),
		Vector2(-r * 0.64, depth * 0.72), Vector2(-bottom, depth),
		Vector2(bottom, depth), Vector2(r * 0.64, depth * 0.72),
		Vector2(r * 0.90, depth * 0.35), Vector2(r, 0),
	])
	for i in profile.size() - 1:
		_wall_segment(profile[i], profile[i + 1])

	# The lid: taut webbing across the mouth, engaged only at capacity.
	_lid = CollisionShape2D.new()
	var lid_rect := RectangleShape2D.new()
	lid_rect.size = Vector2(r * 2.0 + 10.0, 10.0)
	_lid.shape = lid_rect
	_lid.position = Vector2(0, -7.0)
	_lid.disabled = true
	add_child(_lid)

	# The catch: entering the bag interior IS the mouth-plane cross.
	_bag = Area2D.new()
	_bag.collision_layer = 0
	_bag.collision_mask = Playfield.LAYER_BALL
	var interior := CollisionPolygon2D.new()
	interior.polygon = PackedVector2Array([
		Vector2(-r * 0.86, 8), Vector2(-r * 0.58, depth * 0.70),
		Vector2(-bottom * 0.9, depth * 0.94), Vector2(bottom * 0.9, depth * 0.94),
		Vector2(r * 0.58, depth * 0.70), Vector2(r * 0.86, 8),
	])
	_bag.add_child(interior)
	_bag.body_entered.connect(_on_bag_entered)
	add_child(_bag)

	# Near-side mesh, drawn over the balls so they read as inside the bag.
	_front = Node2D.new()
	_front.z_index = 7
	_front.draw.connect(_draw_front.bind(_front))
	add_child(_front)


func _wall_segment(a: Vector2, b: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(a.distance_to(b) + BAG_WALL_T * 0.5, BAG_WALL_T)
	shape.shape = rect
	shape.position = (a + b) * 0.5
	shape.rotation = (b - a).angle()
	add_child(shape)


func held_count() -> int:
	return held_items.size()


func held_bodies() -> Array:
	return held_items


func is_full() -> bool:
	return held_count() >= NetLabRules.CAPACITY


func _on_bag_entered(body: Node) -> void:
	if _pouring or is_full() or held_items.has(body):
		return
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return
	held_items.append(body)
	# Freeze and re-seat deferred — we're inside a physics flush here.
	_capture.call_deferred(body)
	caught.emit(body)


func _capture(body: RigidBody2D) -> void:
	if not is_instance_valid(body) or not held_items.has(body):
		return
	body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	body.get_parent().remove_child(body)
	add_child(body)
	body.position = _slot(held_items.find(body))
	body.rotation = 0.0


## Stack positions inside the bag, two abreast, filling from the seam up.
func _slot(i: int) -> Vector2:
	var depth := NetLabRules.pouch_depth_px()
	var col := (i % 2) * 2 - 1
	var row := i / 2
	return Vector2(col * 26.0, depth - 36.0 - row * 46.0)


## The pour, physically: unfreeze the haul back into the world with the rig's
## motion inherited, and gravity does what gravity does — into the can below.
func _release_all() -> void:
	var out := held_items.duplicate()
	held_items.clear()
	for body in out:
		if not is_instance_valid(body):
			continue
		var world_pos: Vector2 = body.global_position
		remove_child(body)
		if release_container != null:
			release_container.add_child(body)
		else:
			get_parent().add_child(body)
		body.global_position = world_pos
		body.freeze = false
		body.linear_velocity = vel_px * 0.4 + Vector2(0, 60)


func is_pouring() -> bool:
	return _pouring


func _ease_facing_toward(dir: Vector2, alpha: float) -> void:
	var current := facing.angle()
	var delta := wrapf(dir.angle() - current, -PI, PI)
	facing = Vector2.from_angle(current + delta * alpha)


## True while the net can accept a catch — minSpeed 0 keeps this open today, but
## the carry logic is live so the commitment gate is one constant away.
func is_catch_committed() -> bool:
	if NetLabRules.CATCH_MIN_SPEED <= 0.0:
		return true
	return vel_px.length() / NetLabRules.PPU >= NetLabRules.CATCH_MIN_SPEED \
		or _catch_carry > 0.0


func _physics_process(dt: float) -> void:
	if dt <= 0.0:
		return
	var held := held_count()

	# --- Follow: netCatcher.step()'s exponential, frame-rate independent, with
	# the load-scaled speed cap so a full bag physically lumbers. ---
	var alpha := 1.0 - exp(-NetLabRules.follow_rate(held) * dt)
	var step := (target - position) * alpha
	step = step.limit_length(NetLabRules.speed_cap(held) * dt)
	var prev := position
	position += step
	vel_px = (position - prev) / dt
	_smooth_vel += (vel_px - _smooth_vel) * NetLabRules.FACING_SMOOTH_K

	# Everything below thinks in net-lab units: y-up, world units per second.
	var v := Vector2(_smooth_vel.x, -_smooth_vel.y) / NetLabRules.PPU
	var speed := v.length()
	var near_bin := absf(position.x - NetLabRules.bin_centre_px().x) \
		<= NetLabRules.bin_radius_px() * NetLabRules.POUR_X_CAPTURE

	# --- Facing: stroke-tracking with pour authority, self-right, clamp-up. ---
	# Divergence from netCatcher.ts, on purpose: the lab eased the facing as a
	# lerp-then-normalize on VECTORS, which is degenerate for a straight-down
	# stroke — (0, y).normalized() snaps back to (0, 1) every tick, so a
	# perfectly vertical pour could never tip. Real pointers are never that
	# clean; a bot's are. Easing the ANGLE keeps the identical smoothing shape
	# with no degenerate axis.
	var facing_gate := NetLabRules.FACING_SPEED_MIN
	if held > 0 and near_bin:
		facing_gate = NetLabRules.FACING_SPEED_MIN_POUR
	if speed > facing_gate:
		var ease := NetLabRules.FACING_EASE_ALPHA
		if held > 0 and near_bin:
			ease = NetLabRules.POUR_FACING_EASE
		_ease_facing_toward(v / speed, ease)
	elif NetLabRules.SELF_RIGHT and held > 0 and not near_bin:
		# A loaded bag's weight is a restoring torque: the mouth levels itself
		# upward at rest, harder the fuller it is.
		var fill := clampf(float(held) / float(NetLabRules.CAPACITY), 0.0, 1.0)
		_ease_facing_toward(Vector2(0, 1),
			minf(1.0, NetLabRules.SELF_RIGHT_RATE * fill * dt))
	elif NetLabRules.REST_POSE_LEVEL and held == 0 and not near_bin:
		# Rest pose "level": an idle empty net settles catch-ready, mouth up.
		_ease_facing_toward(Vector2(0, 1), minf(1.0, NetLabRules.REST_POSE_RATE * dt))

	if NetLabRules.CLAMP_UP and not near_bin and facing.y < 0.0:
		# Outside the pour zone the mouth never points below horizontal — which
		# is also what makes pour the ONLY place the bag can empty.
		facing = Vector2(signf(facing.x) if facing.x != 0.0 else 1.0, 0.0)

	# Rate-capped rotation: the facing model decides WHERE the mouth aims, the
	# cap decides how fast the physical bag may swing there (see NetLabRules).
	var desired := Vector2(facing.x, -facing.y).angle() + PI / 2.0
	var rate := NetLabRules.TIP_RATE_POUR if (held > 0 and near_bin) \
		else NetLabRules.TIP_RATE_MAX
	rotation = rotate_toward(rotation, desired, rate * dt)

	# --- Catch-carry window (netCatcher tail). ---
	if NetLabRules.CATCH_MIN_SPEED <= 0.0 or speed >= NetLabRules.CATCH_MIN_SPEED:
		_catch_carry = NetLabRules.SPEED_CARRY_SEC
	else:
		_catch_carry = maxf(0.0, _catch_carry - dt)

	# --- Pour gates: tryPour, but the outcome is physical. ---
	var raw_v := Vector2(vel_px.x, -vel_px.y) / NetLabRules.PPU
	var bin := NetLabRules.bin_centre_px()
	var h_above := (bin.y - position.y) / NetLabRules.PPU  # wu above the bin mouth
	var height_ok := h_above >= 0.12 and h_above <= NetLabRules.POUR_HEIGHT_ABOVE_WU
	var stroking_down := raw_v.y <= -NetLabRules.pour_down_gate(held)
	var stroke_tip_y := raw_v.y / raw_v.length() if raw_v.length() > 0.5 else 1.0
	var tipped := facing.y <= NetLabRules.POUR_FACE_DOWN_Y \
		or (stroking_down and stroke_tip_y <= NetLabRules.POUR_STROKE_TIP_Y)
	var pouring := near_bin and height_ok and tipped and held_items.size() > 0

	if pouring != _pouring:
		_pouring = pouring
		pour_state_changed.emit(pouring)

	# Release on GEOMETRY, not intent: the tip-rate cap means the bag lags the
	# pour decision, and unfreezing into a still-upright bag re-seats the haul
	# and sprays it mid-swing. Waiting until the mouth has physically swung
	# down over the can makes every pour drop straight into the throat.
	if _pouring and held_items.size() > 0 \
			and absf(wrapf(rotation, -PI, PI)) > 2.2:
		_release_all.call_deferred()

	# --- The lid: full bounce, released by the pour. ---
	var block := NetLabRules.FULL_BOUNCE and held >= NetLabRules.CAPACITY and not pouring
	if _lid.disabled == block:
		_lid.set_deferred("disabled", not block)

	queue_redraw()
	_front.queue_redraw()


# -- Drawing (local space — rotation carries the whole rig) ----------------------

func _draw() -> void:
	var r := NetLabRules.mouth_radius_px()
	var depth := NetLabRules.pouch_depth_px()
	var bottom := r * NetLabRules.POUCH_TAPER
	var frame: Color = Palette.HEARTH_CREAM
	var mesh: Color = Palette.SPECTRAL_MINT * Color(1, 1, 1, 0.40)

	# Grip stub off the right rim tip — the hand is off-screen, the net is hers.
	draw_line(Vector2(r, 0), Vector2(r + 44, -26), Color("6b4630"), 10.0)
	draw_line(Vector2(r, 0), Vector2(r + 44, -26), Color(0, 0, 0, 0.25), 3.0)

	# Bag profile (far side).
	var profile := PackedVector2Array([
		Vector2(-r, 0), Vector2(-r * 0.90, depth * 0.35),
		Vector2(-r * 0.64, depth * 0.72), Vector2(-bottom, depth),
		Vector2(bottom, depth), Vector2(r * 0.64, depth * 0.72),
		Vector2(r * 0.90, depth * 0.35), Vector2(r, 0),
	])
	draw_polyline(profile, frame, 5.0, true)

	# Far mesh: verticals sagging toward the bottom seam plus rings.
	for i in 5:
		var t := (float(i) + 1.0) / 6.0
		var top := Vector2(lerpf(-r, r, t), 2.0)
		var bot := Vector2(lerpf(-bottom, bottom, t), depth - 2.0)
		draw_line(top, bot, mesh, 1.6)
	for i in 4:
		var t := (float(i) + 1.0) / 5.0
		var w := lerpf(r * 0.92, bottom, t)
		draw_line(Vector2(-w, depth * t), Vector2(w, depth * t), mesh, 1.6)

	# The rim: hoop tube ends.
	draw_circle(Vector2(-r, 0), 9.0, frame)
	draw_circle(Vector2(r, 0), 9.0, frame)

	# Taut webbing when the lid is up — the full-bounce state, made visible.
	if not _lid.disabled:
		var taut: Color = Palette.SPECTRAL_MINT * Color(1, 1, 1, 0.55)
		for i in 6:
			var t := (float(i) + 0.5) / 6.0
			var x := lerpf(-r * 0.9, r * 0.9, t)
			draw_line(Vector2(x, -4), Vector2(x + 8, 2), taut, 2.0)
		draw_line(Vector2(-r, -6), Vector2(r, -6), taut, 2.5)

	# Pour glow: the mouth confirms the verb in the cleanse colour.
	if _pouring:
		draw_arc(Vector2.ZERO, r * 0.9, PI + 0.35, TAU - 0.35, 20,
			Palette.SPECTRAL_MINT, 3.0)


func _draw_front(canvas: Node2D) -> void:
	var r := NetLabRules.mouth_radius_px()
	var depth := NetLabRules.pouch_depth_px()
	var bottom := r * NetLabRules.POUCH_TAPER
	var mesh: Color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.30)
	for i in 4:
		var t := (float(i) + 1.0) / 5.0
		var top := Vector2(lerpf(-r, r, t), 6.0)
		var bot := Vector2(lerpf(-bottom, bottom, 1.0 - t), depth - 4.0)
		canvas.draw_line(top, bot, mesh, 1.6)
	# Near lip.
	canvas.draw_line(Vector2(-r + 4, 0), Vector2(r - 4, 0),
		Palette.HEARTH_CREAM * Color(1, 1, 1, 0.65), 3.5)
