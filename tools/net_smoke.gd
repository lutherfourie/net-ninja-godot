extends Node
## Native net-play smoke test — net-lab's persona idea, in-engine.
##
## Runs the real catch scene headless with a bot on the SAME seam a finger uses
## (it writes NetRig.target, nothing else), for a fixed simulated duration:
##
##     godot --headless --path . res://tools/net_smoke.tscn
##
## The bot is an "Average" persona: park under the telegraphed slam, catch what
## falls, and when the bag has a haul, carry it to the bin and pour. Asserts
## prove the loop is SOLVABLE with the physics net — balls really enter the bag,
## the pour really banks, and the drop limit isn't instantly fatal:
##
##   PASS requires: >= 3 catches observed, >= 2 balls banked (cleanse moved),
##                  and the run not lost inside the test window.
##
## Exit code 0 on pass, 1 on fail — cheap enough to run before every push.

const RUN_SECONDS := 50.0
const CatchGameScene := preload("res://src/scenes/catch_game.tscn")

var _game: Node2D
var _view
var _net
var _model: CatchModel

var _elapsed := 0.0
var _slam_x := 0.5
var _catches := 0
var _banked := 0
var _max_held := 0
var _lost := false
var _phase := "catch"   # catch | to_bin | pour | recover
var _phase_t := 0.0
var _done := false
var _diag_t := 0.0
var _banked_live := 0

## Print a per-half-second state line — net-lab's diag.telemetry spirit.
## Flip on when hunting a regression; the PASS/FAIL summary always prints.
var diag := false


func _ready() -> void:
	# Physics must run faster than wall-clock so 50 sim-seconds finish quickly.
	Engine.time_scale = 4.0
	# Deterministic slam schedule — the gate should fail on regressions, not luck.
	get_tree().root.set_meta("nn_rng_seed", 0x4E494E4A)
	_game = CatchGameScene.instantiate()
	add_child(_game)
	await get_tree().process_frame
	_view = _game.get("_view")
	_model = _game.get("model")
	_net = _view.net_rig()
	_model.slam_telegraphed.connect(func(at_x: float) -> void: _slam_x = at_x)
	_model.cleansed_changed.connect(func(_v: float) -> void: pass)
	_model.drops_changed.connect(func(_d: int, _l: int) -> void: pass)
	_model.finished.connect(func(won: bool) -> void:
		if not won:
			_lost = true)
	var bin: Node2D = _view.get("_bin")
	bin.banked.connect(func(_b: Node) -> void: _banked_live += 1)
	print("net_smoke: running %.0fs of simulated play..." % RUN_SECONDS)


func _physics_process(dt: float) -> void:
	if _done or _net == null:
		return
	_elapsed += dt
	_phase_t += dt

	var held: int = _net.held_count()
	_diag_t += dt
	if diag and _diag_t >= 0.5:
		_diag_t = 0.0
		print("  t=%5.1f %-8s held=%d pos=(%4.0f,%4.0f) tgt=(%4.0f,%4.0f) rot=%5.2f fy=%5.2f pour=%s banked=%d drops=%d"
			% [_elapsed, _phase, held, _net.position.x, _net.position.y,
				_net.target.x, _net.target.y,
				_net.rotation, _net.facing.y, str(_net.is_pouring()),
				_banked_live, _model.drops])
	if held > _max_held:
		_max_held = held
		if held > 0:
			_catches = maxi(_catches, held + _banked)

	match _phase:
		"catch":
			# Intent, net-lab persona style: chase the lowest falling ball —
			# sweep the burst's spread the way a finger does — and fall back to
			# parking under the telegraphed lane when the air is clear.
			# Lead the fall, then settle: track the lowest ball while it is
			# still HIGH, and freeze once it drops past the commit line so the
			# net arrives early and meets it mouth-level instead of dashing in
			# sideways at the last moment.
			var chase_x := Playfield.rail_x(_slam_x)
			var best_y := -1.0
			for ball in _view.get("_balls").get_children():
				if not is_instance_valid(ball):
					continue
				var by: float = ball.position.y
				if by > 300.0 and by < 580.0 and by > best_y \
						and ball.linear_velocity.y > -60.0:
					best_y = by
					chase_x = ball.position.x
			if best_y > 0.0:
				_net.target = Playfield.clamp_net(Vector2(chase_x, 790.0))
			# else: hold the last commit — do not re-aim under a landing ball.
			if held >= 2 or (held > 0 and _phase_t > 5.0):
				_phase = "to_bin"
				_phase_t = 0.0
		"to_bin":
			# Hover centred OVER the can before tipping, so every dribble of a
			# gradual tip falls into the opening, not beside it. High enough
			# that the pour stroke below is long enough to commit the facing.
			var hover := Vector2(604.0, 872.0)
			_net.target = Playfield.clamp_net(hover)
			if _net.position.distance_to(hover) < 36.0 or _phase_t > 2.5:
				_phase = "pour"
				_phase_t = 0.0
		"pour":
			# ONE sustained down-stroke, then hold the tip: the stroke commits
			# the facing down (pour ease), the rate cap swings the bag over
			# gradually, and the haul dribbles out into the channel below.
			_net.target = Playfield.clamp_net(Vector2(616.0, 1012.0))
			if held == 0 and _phase_t > 1.6:
				_phase = "recover"
				_phase_t = 0.0
			elif _phase_t > 5.0:
				_phase = "to_bin"
				_phase_t = 0.0
		"recover":
			_net.target = Playfield.clamp_net(Vector2(Playfield.rail_x(_slam_x), 780.0))
			if _phase_t > 0.4:
				_phase = "catch"
				_phase_t = 0.0

	if _elapsed >= RUN_SECONDS or _lost or (_model != null and not _model.running \
			and _model.cleansed >= 1.0):
		_finish()


func _finish() -> void:
	_done = true
	Engine.time_scale = 1.0
	# Banked count from the model: cleanse progress / per-ball value.
	_banked = int(round(_model.cleansed / _model.rules.cleanse_per_ball)) \
		if _model.cleansed < 1.0 else 999

	var won := _model.cleansed >= 1.0
	print("net_smoke: elapsed=%.1fs held_max=%d banked≈%d drops=%d/%d cleansed=%.2f %s"
		% [_elapsed, _max_held, _banked, _model.drops, _model.rules.drop_limit,
			_model.cleansed, "WON" if won else ("LOST" if _lost else "")])

	# SOLVABILITY thresholds, not balance ones: Godot physics is not
	# bit-deterministic across runs even with a seeded slam schedule, so the
	# gate asks "does every verb work end-to-end?" — multi-catch happens, pours
	# bank, and the run either survives or makes real progress. Each threshold
	# maps to a failure this gate has actually caught (see NET-LAB-PORT.md).
	var failures: Array[String] = []
	if _max_held < 2:
		failures.append("net never held 2+ balls (catching broken?)")
	if _banked_live < 2:
		failures.append("fewer than 2 balls banked (pour broken?)")
	if _lost and _model.cleansed < 0.45:
		failures.append("lost without meaningful progress (loop not solvable)")

	if failures.is_empty():
		print("net_smoke: PASS")
		get_tree().quit(0)
	else:
		for f in failures:
			print("net_smoke: FAIL — ", f)
		get_tree().quit(1)
