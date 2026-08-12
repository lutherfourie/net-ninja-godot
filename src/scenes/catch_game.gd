extends Node2D
## One contract: catch the burst, dump it in the can, clear the bar.
##
## Owns the model, the playfield and the HUD, and nothing else. The outcome is
## written back to GameState as a possession swing, so the flat Ami returns to
## has visibly changed either way — winning is not just a number going up.

const Catch2DView := preload("res://src/view/catch_2d/catch_2d_view.gd")
const ContractHUD := preload("res://src/ui/contract_hud.gd")

const WIN_RELIEF := 0.25
const LOSS_TOLL := 0.20

var model: CatchModel

var _view      # Catch2DView
var _hud       # ContractHUD
var _leave: NNButton
var _scrim: ColorRect
var _scrim_edge: ColorRect
var _result
var _result_buttons: Array[NNButton] = []
var _finished := false


func _ready() -> void:
	# The smoke harness pins a seed on the root for deterministic gate runs
	# (net-lab's conformance habit); normal play stays randomized.
	var seed_v := int(get_tree().root.get_meta("nn_rng_seed", 0))
	model = CatchModel.new(CatchRules.first_contract(), seed_v)

	_view = Catch2DView.new()
	add_child(_view)
	_view.setup(model)

	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)

	# The cat owns the top band, and the HUD has to live in front of it. A flat
	# dark plate with one hairline under it keeps both readable without pushing
	# the status bar into the play area, where falling balls would cross it.
	_scrim = ColorRect.new()
	_scrim.color = Color(Palette.MIDNIGHT_INK.r, Palette.MIDNIGHT_INK.g,
		Palette.MIDNIGHT_INK.b, 0.72)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_scrim)

	_scrim_edge = ColorRect.new()
	_scrim_edge.color = Palette.HEARTH_CREAM * Color(1, 1, 1, 0.18)
	_scrim_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_scrim_edge)

	_hud = ContractHUD.new()
	ui.add_child(_hud)

	_leave = NNButton.new()
	_leave.text = "LEAVE"
	_leave.variant = NNButton.Variant.GHOST
	_leave.ears = false
	_leave.font_size = int(Tokens.TYPE["meta"]) + 1
	_leave.pressed.connect(_on_leave)
	ui.add_child(_leave)

	_result = NNPanel.new()
	_result.visible = false
	_result.show_shadow = true
	ui.add_child(_result)

	model.cleansed_changed.connect(func(v: float): _hud.set_cleansed(v))
	model.drops_changed.connect(func(d: int, l: int): _hud.set_drops(d, l))
	model.net_load_changed.connect(func(n: int): _hud.set_load(n, model.rules.net_capacity))
	model.finished.connect(_on_finished)

	get_viewport().size_changed.connect(_layout)
	_layout()
	model.start()
	_hud.set_load(0, model.rules.net_capacity)


func _layout() -> void:
	var vp := get_viewport_rect().size
	var safe := Tokens.safe_rect(vp)

	_hud.position = Vector2(safe.position.x, safe.position.y - 12.0)
	_hud.size = Vector2(safe.size.x - 130.0, 66.0)

	var band_h: float = Playfield.STATUS_BAND
	_scrim.position = Vector2.ZERO
	_scrim.size = Vector2(vp.x, band_h)
	_scrim_edge.position = Vector2(0, band_h)
	_scrim_edge.size = Vector2(vp.x, 2.0)

	_leave.custom_minimum_size = Vector2(112.0, 44.0)
	_leave.size = Vector2(112.0, 44.0)
	_leave.position = Vector2(safe.end.x - 112.0, safe.position.y - 14.0)

	var w := minf(safe.size.x, 500.0)
	var h := 320.0
	_result.position = Vector2((vp.x - w) * 0.5, (vp.y - h) * 0.5)
	_result.size = Vector2(w, h)
	_place_result_buttons(w)


func _place_result_buttons(w: float) -> void:
	var pad: float = Tokens.BUBBLE_PADDING
	var y := 196.0
	for button in _result_buttons:
		button.custom_minimum_size = Vector2(w - pad * 2.0, 56.0)
		button.size = button.custom_minimum_size
		button.position = Vector2(pad, y)
		y += 66.0


func _on_leave() -> void:
	SceneRouter.goto("room")


func _on_finished(won: bool) -> void:
	if _finished:
		return
	_finished = true

	# The flat reflects the outcome. Mint means cleansing; the curse deepens if
	# the contract got away.
	GameState.possession += -WIN_RELIEF if won else LOSS_TOLL

	_result.title = "CONTRACT CLEARED" if won else "CONTRACT LOST"
	_result.state = NNPanel.State.CLEANSED if won else NNPanel.State.DANGER

	var line := Label.new()
	line.text = ("Miso settles. The screen dims to something\nlike an ordinary blue."
		if won else "It got back into the wiring.\nThe flat is worse than you left it.")
	line.add_theme_font_override("font", NNFonts.or_default(NNFonts.ui(), self))
	line.add_theme_font_size_override("font_size", int(Tokens.TYPE["body"]))
	line.add_theme_color_override("font_color", Palette.HEARTH_CREAM * Color(1, 1, 1, 0.82))
	line.position = Vector2(Tokens.BUBBLE_PADDING, 108.0)
	_result.add_child(line)

	var retry := NNButton.new()
	retry.text = "TRY AGAIN"
	retry.variant = NNButton.Variant.PRIMARY
	retry.ears = false
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	_result.add_child(retry)

	var home := NNButton.new()
	home.text = "BACK TO THE FLAT"
	home.variant = NNButton.Variant.SECONDARY
	home.ears = false
	home.font_size = int(Tokens.TYPE["body"])
	home.pressed.connect(_on_leave)
	_result.add_child(home)

	_result_buttons = [retry, home]
	_place_result_buttons(_result.size.x)

	_result.visible = true
	_result.modulate.a = 0.0
	create_tween().tween_property(_result, "modulate:a", 1.0, 0.22)
	retry.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_leave()
