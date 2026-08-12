extends RigidBody2D
## One captured wisp, mid-fall.
##
## Mint because mint means cleansing: every ball on screen is something Ami is
## about to remove from the world, not something attacking her. Drawn flat with a
## hard rim to sit alongside the pixel baseline (PDF p.13) rather than fighting
## it with soft gradients.

const RIM := Color(0.05, 0.10, 0.09, 0.55)

var radius := 17.0
var settled := false:
	set(value):
		if value == settled:
			return
		settled = value
		queue_redraw()

var _spin := 0.0
var _pop := 0.0


func configure(rules: CatchRules) -> void:
	radius = rules.ball_radius
	gravity_scale = rules.ball_gravity_scale
	linear_damp = 0.22
	angular_damp = 1.6
	contact_monitor = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

	var mat := PhysicsMaterial.new()
	mat.bounce = rules.ball_bounce
	mat.friction = rules.ball_friction
	physics_material_override = mat

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	collision_layer = Playfield.LAYER_BALL
	collision_mask = Playfield.LAYER_BALL | Playfield.LAYER_NET | Playfield.LAYER_SOLID


## Little flash when the ball lands in the net — feedback for a good catch.
func pop() -> void:
	_pop = 1.0
	set_process(true)


func _process(delta: float) -> void:
	_pop = maxf(_pop - delta * 3.2, 0.0)
	queue_redraw()
	if _pop <= 0.0:
		set_process(false)


func _draw() -> void:
	var mint: Color = Palette.SPECTRAL_MINT
	var glow := mint
	glow.a = 0.16 + _pop * 0.30
	draw_circle(Vector2.ZERO, radius * (1.55 + _pop * 0.5), glow)
	draw_circle(Vector2.ZERO, radius, mint.darkened(0.18).lerp(mint, _pop))
	draw_circle(Vector2.ZERO, radius, RIM, false, 2.0)
	# Single highlight, offset up-left, consistent with the room's key light.
	draw_circle(Vector2(-radius * 0.32, -radius * 0.36), radius * 0.26,
		Palette.HEARTH_CREAM * Color(1, 1, 1, 0.85))
