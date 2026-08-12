extends Control
## Thumb stick for touch, drawn in the cozy language rather than the usual
## translucent grey donut. Appears where the thumb lands, fades when released.

signal moved(vector: Vector2)

const RADIUS := 78.0
const DEADZONE := 0.14

## Mouse drag stands in for touch on machines without a touchscreen, but only if
## something asks for it — otherwise the stick swallows desktop clicks and draws
## a stray amber ring every time you click the room.
var allow_mouse := false

var _touch_index := -1
var _origin := Vector2.ZERO
var _current := Vector2.ZERO
var _alpha := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	allow_mouse = DisplayServer.is_touchscreen_available()
	set_process(true)


func value() -> Vector2:
	if _touch_index == -1:
		return Vector2.ZERO
	var delta := (_current - _origin) / RADIUS
	if delta.length() < DEADZONE:
		return Vector2.ZERO
	return delta.limit_length(1.0)


func _process(delta: float) -> void:
	var target := 1.0 if _touch_index != -1 else 0.0
	var next := move_toward(_alpha, target, delta * 5.0)
	if not is_equal_approx(next, _alpha):
		_alpha = next
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_current = event.position
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			moved.emit(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_current = event.position
		moved.emit(value())
		queue_redraw()
	elif allow_mouse and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_index = 0
			_origin = event.position
			_current = event.position
		else:
			_touch_index = -1
			moved.emit(Vector2.ZERO)
		queue_redraw()
	elif allow_mouse and event is InputEventMouseMotion and _touch_index == 0:
		_current = event.position
		moved.emit(value())
		queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var ring: Color = Palette.HEARTH_CREAM
	ring.a = 0.22 * _alpha
	draw_arc(_origin, RADIUS, 0, TAU, 40, ring, 3.0, true)

	var knob_at := _origin + (_current - _origin).limit_length(RADIUS)
	var knob: Color = Palette.WARM_AMBER
	knob.a = 0.85 * _alpha
	draw_circle(knob_at, 26.0, Color(knob.r, knob.g, knob.b, 0.22 * _alpha))
	draw_circle(knob_at, 17.0, knob)
