class_name CatchRules
extends Resource
## Every number that decides how a contract feels, in one place.
##
## Difficulty is data, not code: a harder cat is a different CatchRules, not a
## different CatchModel. Values ramp from `_start` to `_end` as the cleanse bar
## fills, so pressure rises exactly as the player gets closer to winning.

@export_group("Slam cadence")
## Seconds between paw slams at 0% and 100% cleansed. The tempo director in
## CatchModel shapes this live (x0.62 mastery .. x1.35 after drops).
@export var slam_interval_start: float = 3.0
@export var slam_interval_end: float = 1.5
## Balls per burst at 0% and 100% cleansed.
@export var balls_per_slam_start: int = 2
@export var balls_per_slam_end: int = 5
## Delay between the paw lifting and the balls appearing — the telegraph.
## net-lab telegraph.base (clamp 0.32..1.15); the faster net-lab gravity pays
## the reaction budget back.
@export var slam_telegraph: float = 0.38

@export_group("Pressure")
## Drop limit is the failure pressure (PDF p.11). Nothing else can lose a run.
## Sized against the pour economy: a bin trip costs roughly one burst of
## coverage, and clearing takes ~4 trips, so the budget allows ~4 imperfect
## trips plus change.
@export var drop_limit: int = 18
## How much of the bar one banked ball is worth. 0.075 ≈ 14 balls to clear.
@export var cleanse_per_ball: float = 0.075
## net-lab net.capacity: at this count the lid engages (full bounce).
@export var net_capacity: int = 6

@export_group("Feel")
## net-lab world.fallGravity -9.5 wu/s² through NetLabRules.gravity_scale().
@export var ball_gravity_scale: float = 1.29
@export var ball_bounce: float = 0.18
@export var ball_friction: float = 0.65
## net-lab world.itemRadius 0.22 wu.
@export var ball_radius: float = 29.0
## Horizontal spread of a burst, either side of the paw. Kept just inside the
## net mouth, so a well-placed net can take a whole burst — the skill is in
## reading the telegraph, not in being lucky.
@export var burst_spread: float = 58.0
@export var burst_impulse: float = 88.0


## The starting contract: forgiving enough to learn the drag, mean enough by the
## end that the last three balls matter.
static func first_contract() -> CatchRules:
	return CatchRules.new()
