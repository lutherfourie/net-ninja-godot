class_name CatchModel
extends RefCounted
## The catch loop's rules, with no physics and no pixels in sight.
##
## A deliberate note on the boundary, because it is different from the room's:
## ball collision genuinely belongs to the physics engine — "spectral balls fall,
## collide and visibly stack inside the net" (PDF p.11) is a simulation result,
## and hand-rolling sphere stacking would be worse in every way. So the split
## here is *rules vs simulation* rather than *data vs rendering*. This class owns
## cadence, difficulty ramp, scoring, the drop limit and the win/lose decision;
## the view owns bodies, contacts and presentation. A 3D catch view (p.12, soft
## cloth net and stacked spheres) reuses this file untouched.

signal slam_telegraphed(at_x: float)     ## Paw lifts. Eyes flash. Nothing spawns yet.
signal slam_landed(count: int, at_x: float)
signal cleansed_changed(value: float)
signal drops_changed(drops: int, limit: int)
signal net_load_changed(load: int)
signal finished(won: bool)

var rules: CatchRules

var cleansed := 0.0
var drops := 0
var net_load := 0
var running := false

## net-lab tempoDirector.ts (M1 flow-channel DDA): "cat agitation" reads clean
## play and compresses the gap between slams; a drop eases it. Neutral flow maps
## to x1.0, so this is pacing SHAPE, not a global speed change — and the ease
## side is the structural anti-death-spiral.
var intensity := 0.35                 # tempo.baseline is also the start value
const TEMPO_BASELINE := 0.35
const TEMPO_COMPRESS_THR := 0.6       # tempo.compressThreshold — deadband above baseline
const TEMPO_RISE_CATCH := 0.05        # tempo.risePerCatch
const TEMPO_RISE_DUMP := 0.04         # tempo.risePerDump (per banked ball)
const TEMPO_DROP_MISS := 0.30         # tempo.dropPerMiss
const TEMPO_REBOUND := 0.06           # tempo.reboundPerSec
const TEMPO_GAP_MIN := 0.62           # tempo.gapCompressMin
const TEMPO_GAP_MAX := 1.35           # tempo.gapEaseMax

var _next_slam := 1.1
var _telegraph_left := -1.0
var _pending_x := 0.5
var _rng := RandomNumberGenerator.new()


func _init(contract: CatchRules = null, rng_seed: int = 0) -> void:
	rules = contract if contract != null else CatchRules.first_contract()
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()


func start() -> void:
	running = true
	cleansed = 0.0
	drops = 0
	net_load = 0
	_next_slam = 1.1
	_telegraph_left = -1.0
	cleansed_changed.emit(cleansed)
	drops_changed.emit(drops, rules.drop_limit)


func tick(delta: float) -> void:
	if not running:
		return

	if _telegraph_left > 0.0:
		_telegraph_left -= delta
		if _telegraph_left <= 0.0:
			slam_landed.emit(_burst_size(), _pending_x)
		return

	# Tempo rebounds toward baseline when nothing happens.
	intensity = clampf(move_toward(intensity, TEMPO_BASELINE, TEMPO_REBOUND * delta), 0.0, 1.0)

	_next_slam -= delta
	if _next_slam <= 0.0:
		# Never slam into the bin lane — the can is protected, not a target
		# (0.68 keeps the burst spread clear of the widened net-lab bin).
		_pending_x = _rng.randf_range(0.12, 0.68)
		_telegraph_left = rules.slam_telegraph
		_next_slam = _interval()
		slam_telegraphed.emit(_pending_x)


## Seconds to the next slam: cleanse ramp shaped by the tempo director's gap
## multiplier (compress for mastery, ease after drops).
func _interval() -> float:
	return lerpf(rules.slam_interval_start, rules.slam_interval_end, cleansed) * _gap_mult()


func _gap_mult() -> float:
	if intensity >= TEMPO_COMPRESS_THR:
		return lerpf(1.0, TEMPO_GAP_MIN,
			(intensity - TEMPO_COMPRESS_THR) / (1.0 - TEMPO_COMPRESS_THR))
	if intensity < TEMPO_BASELINE:
		return lerpf(TEMPO_GAP_MAX, 1.0, intensity / TEMPO_BASELINE)
	return 1.0  # neutral deadband — coping-normally play keeps current pacing


func _burst_size() -> int:
	var n := lerpf(float(rules.balls_per_slam_start), float(rules.balls_per_slam_end), cleansed)
	# Round stochastically so the ramp is felt gradually rather than as a step.
	return int(floorf(n) + (1 if _rng.randf() < fposmod(n, 1.0) else 0))


func report_net_load(count: int) -> void:
	if count == net_load:
		return
	if count > net_load:
		# A rising load is a clean catch — heat the tempo.
		intensity = clampf(intensity + TEMPO_RISE_CATCH * (count - net_load), 0.0, 1.0)
	net_load = count
	net_load_changed.emit(count)


func register_drop() -> void:
	if not running:
		return
	drops += 1
	intensity = clampf(intensity - TEMPO_DROP_MISS, 0.0, 1.0)
	drops_changed.emit(drops, rules.drop_limit)
	if drops >= rules.drop_limit:
		_finish(false)


## Returns the bar progress actually gained, so the view can size its burst.
## Called per banked ball since the net-lab port — the view owns net-load
## reporting, so no zeroing happens here.
func register_dump(count: int) -> float:
	if not running or count <= 0:
		return 0.0
	var before := cleansed
	cleansed = clampf(cleansed + count * rules.cleanse_per_ball, 0.0, 1.0)
	intensity = clampf(intensity + TEMPO_RISE_DUMP * count, 0.0, 1.0)
	cleansed_changed.emit(cleansed)
	if cleansed >= 1.0:
		_finish(true)
	return cleansed - before


func remaining_drops() -> int:
	return maxi(rules.drop_limit - drops, 0)


func _finish(won: bool) -> void:
	if not running:
		return
	running = false
	finished.emit(won)
