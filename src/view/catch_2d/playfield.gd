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

## Catch zone: the net rides a horizontal rail; the player only ever drags on X.
const RAIL_Y := 858.0
const NET_MIN_X := 98.0
const NET_MAX_X := 640.0
const NET_HALF_W := 84.0
const NET_DEPTH := 92.0
const NET_WALL := 9.0

## Trash at the edge: the can, and the x past which the net tips into it.
const BIN := Rect2(548.0, 986.0, 152.0, 166.0)
const DUMP_X := 600.0
## How far the net dips as it swings over the can.
const TIP_DROP := 104.0

const FLOOR_Y := 1152.0
const WALL_T := 40.0

## Physics layers. Balls collide with everything; the net and scenery do not
## need to know about each other.
const LAYER_BALL := 1
const LAYER_NET := 2
const LAYER_SOLID := 4


## 0..1 along the rail, for mapping model x to screen x.
static func rail_x(t: float) -> float:
	return lerpf(NET_MIN_X, NET_MAX_X, clampf(t, 0.0, 1.0))


## How far the net has tipped toward the can, 0..1.
static func tip_amount(x: float) -> float:
	if x <= DUMP_X - 70.0:
		return 0.0
	return clampf((x - (DUMP_X - 70.0)) / (NET_MAX_X - (DUMP_X - 70.0)), 0.0, 1.0)
