class_name NetLabRules
extends Resource
## The net-lab net model, ported constant-for-constant.
##
## Source of truth: net-lab `packages/core/config.ts` + `netCatcher.ts`
## (lutherfourie/net-lab, read 2026-08-12). Every value here carries its original
## key name so a retune in the lab is a mechanical re-read, and drift is a diff.
##
## net-lab world units are a 9:16 portrait: x in [-2.7, 2.7], y in [-4.8, 4.8],
## y-up. Our playfield is 720 x 1280 — the SAME aspect — so one scalar converts:
## 720 / 5.4 = 133.333 px per world unit, y flipped.
##
## What is deliberately NOT ported in this slice: knives/parry/break, charms,
## heaping (flag OFF in the lab), temper, juggle-ladder scoring, tempo director.
## Those are model systems the catch loop's CatchModel doesn't speak yet — see
## docs/NET-LAB-PORT.md for the ledger.

const PPU := 133.333  ## px per net-lab world unit


# -- Follow (netCatcher.step) ---------------------------------------------------
## net.followLerpEmpty/Full are exponential CONVERGENCE RATES (18/6 per second,
## x2 on the pointer path per input.pointerFollowMul). The lab precomputed them
## into per-tick alphas; we drive a RigidBody2D with
##     linear_velocity = (target - position) * rate
## which integrates to the identical exponential — same curve, expressed the way
## a physics engine wants it.
const FOLLOW_RATE_EMPTY := 36.0   # net.followLerpEmpty 18 x pointerFollowMul 2
const FOLLOW_RATE_FULL := 12.0    # net.followLerpFull 6 x pointerFollowMul 2
## Speed caps, load-scaled (physical-port addition): a virtual net could sprint
## any distance without consequence; a real bag doing 2600 px/s slings its haul
## out of the open mouth on the first stop. Empty = fast ninja hands; a full
## bag physically lumbers — the design's own words, made literal.
const SPEED_CAP_EMPTY := 2600.0   # px/s
const SPEED_CAP_FULL := 950.0     # px/s
## weight = fill * sqrt(fill) — "net.weightCurvePow" 1.5 in portable form.

# -- Capacity -------------------------------------------------------------------
const CAPACITY := 6              # net.capacity (raised 5→6, paired with fullBounce)
const FULL_BOUNCE := true        # net.fullBounce.enabled — full net deflects, never dead

# -- Facing (the mouth normal, net-lab y-up convention) --------------------------
const FACING_EASE_ALPHA := 0.09516258196404048   # net.facingEaseAlpha (per tick)
const FACING_SMOOTH_K := 0.35                    # pointer velocity smoothing k
const SELF_RIGHT := true                         # net.facing.weightedSelfRight
const SELF_RIGHT_RATE := 2.2                     # net.facing.selfRightRate (per s at full)
const CLAMP_UP := true                           # net.facing.clampUp — mouth never
	# points below horizontal outside the pour zone; players read a flipped net
	# as a bug, and it makes pour the only emptying verb by construction.
## Raised from the lab's 1.0 for the physical port: in the lab a swinging
## facing was maths (the 120° catch cone still accepted); a physical mouth that
## swings sideways is CLOSED. 3.0 keeps slow repositioning catch-ready while
## committed strokes still whip the mouth around.
const FACING_SPEED_MIN := 3.0                    # wu/s — facing tracks stroke above this
const FACING_SPEED_MIN_POUR := 0.35              # slower gate over the bin with a haul
## net.restPose.mode "level" (the lab's slice-1 opt-in, default "hold" there).
## ON here by physical necessity: our balls are real bodies, so an empty net
## resting mouth-sideways deflects everything — the lab's virtual catches never
## cared. First smoke run proved it: bursts clanked off the bag's flank.
const REST_POSE_LEVEL := true
const REST_POSE_RATE := 2.2                      # net.restPose.rate

# -- Directional catch ----------------------------------------------------------
const CATCH_MIN_SPEED := 0.0     # net.catch.minSpeed — owner call 2026-07-11:
	# no commitment gate; kept as a constant so the gate can return in one edit.
const SPEED_CARRY_SEC := 0.25    # net.catch.speedCarryMs / 1000
const MOUTH_RADIUS_WU := 0.68    # net.catch.mouthRadius
const STRIKE_MAX_Y_WU := 2.0     # net.catch.maxY — anti spawn-camp ceiling

# -- Magnet assist (net.magnet.*, FUN-PASS #3) -----------------------------------
## OFF in the lab (a Feel Claim awaiting playtest). ON here as the physical
## port's cone compensation: the lab's mouth-plane catch accepted a 120° cone
## (net.catch.coneDeg); a physical bag's effective acceptance is nearer 65°.
## The gentle pull toward the mouth restores the forgiveness the geometry took
## away — and reads as the spectral haul being drawn to a charged net.
const MAGNET_ENABLED := true
const MAGNET_RADIUS_WU := 0.9    # net.magnet.radius
const MAGNET_STRENGTH_WU := 7.0  # net.magnet.strength (peak wu/s², fades to 0 at radius)

static func magnet_radius_px() -> float:
	return MAGNET_RADIUS_WU * PPU          # ≈ 120

static func magnet_strength_px() -> float:
	return MAGNET_STRENGTH_WU * PPU        # ≈ 933 px/s²


# -- Rim ------------------------------------------------------------------------
const RIM_TUBE_WU := 0.05        # net.rim.tube (visual; the collider is thicker
	# for CCD safety — Godot's solver owns the bounce, see net_rig.gd)
const RIM_BOUNCE := 0.55         # expresses net.rim.bounceSpeed 3.2 / velTransfer
	# 0.45 as a PhysicsMaterial restitution; the kinematic body supplies the
	# stroke-velocity transfer natively.

# -- Pour (the only emptying verb) ----------------------------------------------
const POUR_DOWN_SPEED := 0.6     # net.pour.downSpeed (wu/s, empty)
const POUR_DOWN_SPEED_FULL := 0.28  # net.pour.downSpeedFull (heavy net strokes slower)
const POUR_HEIGHT_ABOVE_WU := 5.5   # net.pour.heightAbove
const POUR_FACE_DOWN_Y := -0.15  # net.pour.faceDownY (facing y at/below = tipped)
const POUR_STROKE_TIP_Y := -0.12 # net.pour.strokeTipY (stroke-direction fallback)
const POUR_FACING_EASE := 0.2591817793182821  # net.pour.facingEaseAlpha
const POUR_X_CAPTURE := 1.0      # net.pour.xCapture (fraction of binRadius)

## Physical-port addition (no lab counterpart needed there: held items were
## virtual). A real bag swung through 180° in a few ticks SLINGS its haul — the
## second smoke run sprayed six balls across the floor. Capping the mouth's
## angular rate makes tipping a gradual, readable motion: balls dribble out
## instead of launching. This is the p.12 "restrained damping" rule expressing
## itself in rotation.
const TIP_RATE_MAX := 6.0        # rad/s, stroke-tracking facing
const TIP_RATE_POUR := 3.0       # rad/s over the bin with a haul — pour speed

# -- World ----------------------------------------------------------------------
const BIN_X_WU := 2.1            # world.binX
const BIN_Y_WU := -3.0           # world.binY
const BIN_RADIUS_WU := 0.8       # world.binRadius
const FALL_GRAVITY_WU := 9.5     # |world.fallGravity| — pace pass, snappier falls
const WALL_RESTITUTION := 0.7    # world.wallRestitution — walls bounce items back in
const ITEM_RADIUS_WU := 0.22     # world.itemRadius

# -- Input ----------------------------------------------------------------------
const TOUCH_OFFSET_Y_WU := 1.15  # input.touchOffsetY — net rides above the finger

# -- Ceremony (adopted into CatchRules; recorded here for provenance) ------------
const TELEGRAPH_BASE := 0.38     # telegraph.base (clamp 0.32..1.15)

# -- Rig visual proportions (net.rig.*, view-only in the lab too) ----------------
const POUCH_DEPTH_WU := 1.1      # net.rig.pouchDepth
const POUCH_TAPER := 0.45        # net.rig.taper


# -- Derived pixel values --------------------------------------------------------

static func mouth_radius_px() -> float:
	return MOUTH_RADIUS_WU * PPU          # ≈ 90.7

static func item_radius_px() -> float:
	return ITEM_RADIUS_WU * PPU           # ≈ 29.3

static func pouch_depth_px() -> float:
	# Deepened past the lab's visual 1.1 wu so capacity-6 physically fits;
	# the lab never had to hold real bodies in the bag.
	return POUCH_DEPTH_WU * PPU * 1.18    # ≈ 173

static func strike_y_px() -> float:
	return (4.8 - STRIKE_MAX_Y_WU) * PPU  # ≈ 373 from top

static func bin_centre_px() -> Vector2:
	return Vector2((BIN_X_WU + 2.7) * PPU, (4.8 - BIN_Y_WU) * PPU)  # ≈ (640, 1040)

static func bin_radius_px() -> float:
	return BIN_RADIUS_WU * PPU            # ≈ 106.7

static func pour_height_px() -> float:
	return POUR_HEIGHT_ABOVE_WU * PPU     # ≈ 733

static func gravity_scale() -> float:
	# Godot's 2D default gravity is 980 px/s²; the lab wants 9.5 wu/s².
	return FALL_GRAVITY_WU * PPU / 980.0  # ≈ 1.29

static func touch_offset_px() -> float:
	return TOUCH_OFFSET_Y_WU * PPU        # ≈ 153


## Fill-weighted follow rate — netCatcher.step()'s alpha curve as a rate.
static func follow_rate(held: int) -> float:
	var fill := clampf(float(held) / float(CAPACITY), 0.0, 1.0)
	var weight := fill * sqrt(fill)
	return lerpf(FOLLOW_RATE_EMPTY, FOLLOW_RATE_FULL, weight)


static func speed_cap(held: int) -> float:
	var fill := clampf(float(held) / float(CAPACITY), 0.0, 1.0)
	var weight := fill * sqrt(fill)
	return lerpf(SPEED_CAP_EMPTY, SPEED_CAP_FULL, weight)


## Fill-lerped pour down-stroke gate (wu/s) — tryPour's downGate.
static func pour_down_gate(held: int) -> float:
	var fill := clampf(float(held) / float(CAPACITY), 0.0, 1.0)
	var weight := fill * sqrt(fill)
	return lerpf(POUR_DOWN_SPEED, POUR_DOWN_SPEED_FULL, weight)
