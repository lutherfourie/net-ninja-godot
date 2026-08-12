extends Control
## Settings stay "small, separate and inside safe area" (PDF p.7) — so this is an
## overlay, never a second primary action on the menu.

signal closed

const ROW_H := 62.0

var _panel: NNPanel
var _rows: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	var backdrop := ColorRect.new()
	backdrop.color = Color(Palette.MIDNIGHT_INK.r, Palette.MIDNIGHT_INK.g,
		Palette.MIDNIGHT_INK.b, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_panel = NNPanel.new()
	_panel.title = "SETTINGS"
	_panel.state = NNPanel.State.NEUTRAL
	add_child(_panel)

	_add_toggle("Reduce motion", "reduce_motion")
	_add_toggle("High contrast", "high_contrast")
	_add_slider("Curse level", "possession")

	var close := NNButton.new()
	close.text = "CLOSE"
	close.variant = NNButton.Variant.SECONDARY
	close.ears = false
	close.font_size = int(Tokens.TYPE["body"])
	close.pressed.connect(func(): hide_panel())
	_panel.add_child(close)
	_rows.append({"node": close, "kind": "button"})

	get_viewport().size_changed.connect(_layout)
	_layout()


func show_panel() -> void:
	visible = true
	_layout()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.16)


func hide_panel() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.14)
	await t.finished
	visible = false
	closed.emit()


func _add_toggle(label: String, key: String) -> void:
	var button := NNButton.new()
	button.variant = NNButton.Variant.GHOST
	button.ears = false
	button.font_size = int(Tokens.TYPE["body"])
	button.text = _toggle_text(label, GameState.get_setting(key, false))
	button.pressed.connect(func():
		var next := not bool(GameState.get_setting(key, false))
		GameState.set_setting(key, next)
		button.text = _toggle_text(label, next)
	)
	_panel.add_child(button)
	_rows.append({"node": button, "kind": "row"})


func _toggle_text(label: String, on: bool) -> String:
	return "%s   %s" % [label.to_upper(), "ON" if on else "OFF"]


## Dev affordance: drives GameState.possession so the room's cursed cues can be
## eyeballed without playing to that point.
func _add_slider(label: String, _key: String) -> void:
	var holder := VBoxContainer.new()
	var text := Label.new()
	text.text = label.to_upper()
	text.add_theme_font_override("font", NNFonts.or_default(NNFonts.ui(), self))
	text.add_theme_font_size_override("font_size", Tokens.TYPE["meta"])
	text.add_theme_color_override("font_color", Palette.HEARTH_CREAM)
	holder.add_child(text)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = GameState.possession
	slider.custom_minimum_size = Vector2(0, 26)
	slider.value_changed.connect(func(v: float): GameState.possession = v)
	holder.add_child(slider)

	_panel.add_child(holder)
	_rows.append({"node": holder, "kind": "row"})


func _layout() -> void:
	if _panel == null:
		return
	var vp := get_viewport_rect().size
	var safe := Tokens.safe_rect(vp)
	var w := minf(safe.size.x, 520.0)
	var h := ROW_H * _rows.size() + 150.0
	_panel.position = Vector2((vp.x - w) * 0.5, (vp.y - h) * 0.5)
	_panel.size = Vector2(w, h)

	var y := 96.0
	var pad: float = Tokens.BUBBLE_PADDING
	for row in _rows:
		var node: Control = row["node"]
		node.position = Vector2(pad, y)
		node.size = Vector2(w - pad * 2.0, ROW_H - 12.0)
		node.custom_minimum_size = node.size
		y += ROW_H
