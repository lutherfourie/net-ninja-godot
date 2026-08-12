class_name CatchRules
extends Resource
## Every number that decides how a contract feels, in one place.
##
## Difficulty is data, not code: a harder cat is a different CatchRules, not a
## different CatchModel. Values ramp from `_start` to `_end` as the cleanse bar
## fills, so pressure rises exactly as the player gets closer to winning.

@export_group("Slam cadence")
## Seconds between paw slams at 0% and 100% cleansed.
@export var slam_interval_start: float = 2.8
@export var slam_interval_end: float = 1.3
## Balls per burst at 0% and 100% cleansed.
@export var balls_per_slam_start: int = 2
@export var balls_per_slam_end: int = 5
## Delay between the paw lifting and the balls appearing — the telegraph.
@export var slam_telegraph: float = 0.52

@export_group("Pressure")
## Drop limit is the failure pressure (PDF p.11). Nothing else can lose a run.
@export var drop_limit: int = 15
## How much of the bar one dumped ball is worth. 0.055 ≈ 18 balls to clear.
@export var cleanse_per_ball: float = 0.055
## Soft cap: the net physically overflows past this, it is not enforced in code.
@export var net_capacity: int = 9

@export_group("Feel")
@export var ball_gravity_scale: float = 0.72
@export var ball_bounce: float = 0.12
@export var ball_friction: float = 0.75
@export var ball_radius: float = 17.0
## Horizontal spread of a burst, either side of the paw. Kept just inside the
## net mouth, so a well-placed net can take a whole burst — the skill is in
## reading the telegraph, not in being lucky.
@export var burst_spread: float = 58.0
@export var burst_impulse: float = 88.0


## The starting contract: forgiving enough to learn the drag, mean enough by the
## end that the last three balls matter.
static func first_contract() -> CatchRules:
	return CatchRules.new()
