class_name Playfield
extends RefCounted
## Screen grammar for the catch loop, in design-space pixels (720 x 1280).
##
## PDF p.11: "Threat above. Catch zone below. Trash at the edge." These constants
## are that sentence, made numeric. Everything else in catch_2d/ reads them, so
## re-proportioning the screen is one file.

const WIDTH := 720.0
const HEIGHT := 1280.0

## Threat: the cat owns the top band and nothing else may live there. The band
## starts below the status plate — a cat whose eyes are behind the HUD is not a
## threat, it is a layout bug.
const CAT_BAND := 342.0
const SPAWN_Y := 352.0
## Where the readable part of the cat lives: head centre and eye line.
const CAT_HEAD_Y := 252.0
const STATUS_BAND := 186.0

## Catch zone: net-lab edition — the net follows the pointer freely inside this
## region. The floor of the region keeps the mouth clear of the bin walls; the
## ceiling enforces net-lab's anti-spawn-camp strike band (net.catch.maxY).
const NET_REGION := Rect2(56.0, 430.0, 608.0, 620.0)
## Kept for the slam-lane mapping (bursts never target the bin column).
const NET_MIN_X := 98.0
const NET_MAX_X := 640.0
const RAIL_Y := 858.0  ## default net resting height

## Trash at the edge: an open-topped can at net-lab's world.binX/binY, sized to
## net-lab's binRadius 0.8 wu (opening ≈ 213 px) — the can's mouth must be at
## least as wide as the net's, or pour spills by construction.
const BIN := Rect2(500.0, 986.0, 200.0, 166.0)

const FLOOR_Y := 1152.0
const WALL_T := 40.0

## Physics layers. Balls collide with everything; the net and scenery do not
## need to know about each other.
const LAYER_BALL := 1
const LAYER_NET := 2
const LAYER_SOLID := 4


## 0..1 along the slam lane, for mapping model x to screen x.
static func rail_x(t: float) -> float:
	return lerpf(NET_MIN_X, NET_MAX_X, clampf(t, 0.0, 1.0))


static func clamp_net(p: Vector2) -> Vector2:
	return Vector2(
		clampf(p.x, NET_REGION.position.x, NET_REGION.end.x),
		clampf(p.y, NET_REGION.position.y, NET_REGION.end.y)
	)
