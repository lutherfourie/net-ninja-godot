extends Node2D
## Ami's flat, playable.
##
## The hub proves three things the vertical slice needs: that the room reads at
## phone size, that walking it feels calm rather than fiddly, and that
## interacting with the PC visibly raises possession while petting Miso brings it
## down. Gameplay logic lives in ActorBody/RoomModel; this scene is the glue.

const Room2DView := preload("res://src/view/room_2d/room_2d_view.gd")
const VirtualStick := preload("res://src/ui/virtual_stick.gd")
const InteractPrompt := preload("res://src/ui/interact_prompt.gd")
const CurseMeter := preload("res://src/ui/curse_meter.gd")

var room: RoomModel
var body := ActorBody.new()

var _view: RoomView
var _stick
var _prompt
var _meter
var _toast: Label
var _menu_button: NNButton
var _stick_vector := Vector2.ZERO
var _focus: PropDef = null


func _ready() -> void:
	room = AmiApartment.build()
	body.position = room.spawn

	_view = Room2DView.new()
	add_child(_view)
	_view.setup(room)
	_view.set_camera_mode(RoomView.CameraMode.FOLLOW)
	_view.sync_actor(body.position, body.facing, false, 0.0)

	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)

	_stick = VirtualStick.new()
	_stick.moved.connect(func(v: Vector2): _stick_vector = v)
	ui.add_child(_stick)

	_prompt = InteractPrompt.new()
	_prompt.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_prompt)

	_meter = CurseMeter.new()
	ui.add_child(_meter)

	_toast = Label.new()
	_toast.add_theme_font_override("font", NNFonts.or_default(NNFonts.ui(), self))
	_toast.add_theme_font_size_override("font_size", Tokens.TYPE["body"])
	_toast.add_theme_color_override("font_color", Palette.HEARTH_CREAM)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	ui.add_child(_toast)

	_menu_button = NNButton.new()
	_menu_button.text = "MENU"
	_menu_button.variant = NNButton.Variant.GHOST
	_menu_button.ears = false
	_menu_button.font_size = int(Tokens.TYPE["meta"]) + 1
	_menu_button.pressed.connect(func(): SceneRouter.goto("menu"))
	ui.add_child(_menu_button)

	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vp := get_viewport_rect().size
	var safe := Tokens.safe_rect(vp)
	_stick.size = vp
	_prompt.size = vp
	_meter.position = Vector2(safe.position.x, safe.position.y)
	_meter.size = Vector2(minf(220.0, safe.size.x * 0.55), 40.0)
	_menu_button.custom_minimum_size = Vector2(112.0, 44.0)
	_menu_button.size = Vector2(112.0, 44.0)
	_menu_button.position = Vector2(safe.end.x - 112.0, safe.position.y - 2.0)
	_toast.size = Vector2(safe.size.x, 30.0)
	_toast.position = Vector2(safe.position.x, safe.end.y - 90.0)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length_squared() < 0.01:
		input = _stick_vector
	body.step(delta, input, room)
	_view.sync_actor(body.position, body.facing, body.is_moving(), body.travel)
	_update_focus()


func _update_focus() -> void:
	var found := body.nearest_interactable(room)
	if found == _focus:
		if _focus != null:
			_prompt.track(_screen_anchor(_focus))
		return
	_focus = found
	if _focus == null:
		_view.highlight("")
		_prompt.clear()
	else:
		_view.highlight(_focus.id)
		_prompt.show_for(_focus.interact_label, _screen_anchor(_focus))


## Convert a prop's world anchor into viewport pixels via the room camera.
func _screen_anchor(prop: PropDef) -> Vector2:
	var world_point := _view.prop_anchor(prop.id)
	return _view.get_global_transform_with_canvas() * world_point


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _focus != null:
		_interact(_focus)
	elif event.is_action_pressed("ui_cancel"):
		SceneRouter.goto("menu")
	elif event is InputEventScreenTouch and event.pressed and _focus != null:
		# On touch, tapping anywhere in the top half acts on the focused prop —
		# the bottom half belongs to the thumb stick.
		if event.position.y < get_viewport_rect().size.y * 0.5:
			_interact(_focus)


func _interact(prop: PropDef) -> void:
	match prop.interact_id:
		"pc":
			# The inbox is the contract board. Taking one starts the catch loop;
			# how it ends is what moves possession now.
			_say("New contract. The cursor moves on its own.")
			SceneRouter.goto("catch")
		"cat":
			GameState.possession = GameState.possession - 0.10
			_say("Miso purrs. The shadow on the wall does not.")
		"tea":
			_say("Cold. Two hours cold.")
		"bookshelf":
			_say("\"Feline Possession, Vol. III\" — mostly diagrams.")
		"cat_tree":
			_say("Fresh claw marks. Nobody has been home since Tuesday.")
		"front_door":
			_say("Not yet. Take the contract first.")
		_:
			_say(prop.interact_label)


func _say(line: String) -> void:
	_toast.text = line
	var t := create_tween()
	t.tween_property(_toast, "modulate:a", 1.0, 0.14)
	t.tween_interval(2.6)
	t.tween_property(_toast, "modulate:a", 0.0, 0.4)
