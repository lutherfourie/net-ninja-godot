extends NNPanel
## The editor's property panel for one PropDef.
##
## Every mutation goes through _change(), which fires `before_change` (the
## editor's undo hook) before touching the prop and `edited` after — so the
## inspector never needs to know undo exists, and the editor never needs to know
## which field moved. `structural` is the coarse signal for changes that need a
## full view rebuild (id renames), not just a redraw.

signal before_change
signal edited
signal structural

const DECALS := ["", "screen", "tower", "keyboard", "window", "door", "books",
	"shelf_books", "lamp", "leaves", "cat", "cat_tree", "cat_chair",
	"shadow_cat", "mug", "cushions", "drawers", "hooks", "toys", "cave"]

const SWATCHES := [
	"8d5c3c", "7d5033", "6b4630", "5f3d29", "5b3a28", "4a3524", "3a2c22",
	"b9ab99", "9b8e7e", "8a7a68", "7d7264", "a3888a", "977d7c", "8e8172",
	"2a2032", "372a42", "3f3348", "35293f", "2b2338", "241d2e", "17131f",
	"52407a", "4a3f63", "4d3f5c", "574170", "20304a", "15121c", "120e1a",
	"f4e7d3", "c9b79c", "e6a45b", "c87985", "8c5bc2", "75d0b1", "d85f57",
	"4e7a52", "59865c",
]

var _target: PropDef
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _empty: Label
var _refreshers: Array[Callable] = []
var _accent_mode := false
var _swatch_label: Label


func _ready() -> void:
	title = "PROP"
	show_shadow = false
	state = NNPanel.State.NEUTRAL

	_empty = Label.new()
	_empty.text = "Nothing selected.\n\nClick a prop to edit it.\nClick again to cycle overlaps."
	_empty.add_theme_font_override("font", NNFonts.or_default(NNFonts.ui(), self))
	_empty.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]))
	_empty.add_theme_color_override("font_color", Palette.HEARTH_CREAM * Color(1, 1, 1, 0.55))
	_empty.position = Vector2(18, 70)
	add_child(_empty)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(12, 62)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	_scroll.add_child(_rows)

	_build_rows()
	set_target(null)
	resized.connect(_relayout)
	_relayout()


func _relayout() -> void:
	_scroll.size = size - Vector2(24, 76)
	_rows.custom_minimum_size = Vector2(_scroll.size.x - 14, 0)


func set_target(p: PropDef) -> void:
	_target = p
	_scroll.visible = p != null
	_empty.visible = p == null
	if p != null:
		refresh()


func refresh() -> void:
	if _target == null:
		return
	for r in _refreshers:
		r.call()


func _change(apply: Callable) -> void:
	if _target == null:
		return
	before_change.emit()
	apply.call()
	refresh()
	edited.emit()


# -- Row construction -----------------------------------------------------------

func _build_rows() -> void:
	_id_row()
	_cycle_row("KIND", func() -> String: return str(PropDef.Kind.keys()[_target.kind]),
		func(dir: int) -> void:
			var n: int = PropDef.Kind.size()
			_target.kind = ((int(_target.kind) + dir + n) % n) as PropDef.Kind)
	_cycle_row("DECAL", func() -> String: return "—" if _target.decal == "" else _target.decal,
		func(dir: int) -> void:
			var i := DECALS.find(_target.decal)
			_target.decal = DECALS[(i + dir + DECALS.size()) % DECALS.size()])

	_header("PLACEMENT")
	_stepper("POS X", 0.1, func() -> float: return _target.origin.x,
		func(v: float) -> void: _target.origin.x = v)
	_stepper("POS Y", 0.1, func() -> float: return _target.origin.y,
		func(v: float) -> void: _target.origin.y = maxf(v, 0.0))
	_stepper("POS Z", 0.1, func() -> float: return _target.origin.z,
		func(v: float) -> void: _target.origin.z = v)
	_stepper("SIZE X", 0.1, func() -> float: return _target.size.x,
		func(v: float) -> void: _target.size.x = maxf(v, 0.1))
	_stepper("SIZE Y", 0.1, func() -> float: return _target.size.y,
		func(v: float) -> void: _target.size.y = maxf(v, 0.05))
	_stepper("SIZE Z", 0.1, func() -> float: return _target.size.z,
		func(v: float) -> void: _target.size.z = maxf(v, 0.1))

	_toggle_row("BLOCKS", func() -> bool: return _target.blocks,
		func() -> void: _target.blocks = not _target.blocks)
	_toggle_row("POSSESSED", func() -> bool: return _target.reacts_to_possession,
		func() -> void: _target.reacts_to_possession = not _target.reacts_to_possession)

	_header("COLOUR")
	_swatch_target_row()
	_swatch_grid()

	_header("LIGHT")
	_light_presets()
	_stepper("ENERGY", 0.1, func() -> float: return _target.light_energy,
		func(v: float) -> void: _target.light_energy = maxf(v, 0.0))
	_stepper("RADIUS", 0.2, func() -> float: return _target.light_scale,
		func(v: float) -> void: _target.light_scale = maxf(v, 0.2))
	_stepper("OFF X", 0.1, func() -> float: return _target.light_offset.x,
		func(v: float) -> void: _target.light_offset.x = v)
	_stepper("OFF Y", 0.1, func() -> float: return _target.light_offset.y,
		func(v: float) -> void: _target.light_offset.y = v)
	_stepper("OFF Z", 0.1, func() -> float: return _target.light_offset.z,
		func(v: float) -> void: _target.light_offset.z = v)

	_header("INTERACT")
	_text_row("id", func() -> String: return _target.interact_id,
		func(t: String) -> void: _target.interact_id = t)
	_text_row("label", func() -> String: return _target.interact_label,
		func(t: String) -> void: _target.interact_label = t)
	_stepper("RADIUS", 0.1, func() -> float: return _target.interact_radius,
		func(v: float) -> void: _target.interact_radius = maxf(v, 0.2))


func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", NNFonts.or_default(NNFonts.mono(), self))
	l.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]) - 1)
	l.add_theme_color_override("font_color", Palette.WARM_AMBER * Color(1, 1, 1, 0.8))
	_rows.add_child(l)


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", NNFonts.or_default(NNFonts.ui(), self))
	l.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]))
	l.add_theme_color_override("font_color", Palette.HEARTH_CREAM * Color(1, 1, 1, 0.8))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _mini(text: String, on_press: Callable) -> NNButton:
	var b := NNButton.new()
	b.text = text
	b.variant = NNButton.Variant.GHOST
	b.ears = false
	b.font_size = int(Tokens.TYPE["meta"])
	b.custom_minimum_size = Vector2(30, 28)
	b.pressed.connect(on_press)
	return b


func _id_row() -> void:
	var row := HBoxContainer.new()
	row.add_child(_label("id"))
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(150, 28)
	edit.text_submitted.connect(func(t: String) -> void:
		if _target == null or t == "" or t == _target.id:
			return
		before_change.emit()
		_target.id = t
		structural.emit())
	row.add_child(edit)
	_rows.add_child(row)
	_refreshers.append(func() -> void:
		if not edit.has_focus():
			edit.text = _target.id)


func _stepper(label: String, step: float, getter: Callable, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(label))
	var value := Label.new()
	value.add_theme_font_override("font", NNFonts.or_default(NNFonts.mono(), self))
	value.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]))
	value.add_theme_color_override("font_color", Palette.HEARTH_CREAM)
	value.custom_minimum_size = Vector2(52, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_mini("−", func() -> void:
		_change(func() -> void: setter.call(snappedf(float(getter.call()) - step, 0.01)))))
	row.add_child(value)
	row.add_child(_mini("+", func() -> void:
		_change(func() -> void: setter.call(snappedf(float(getter.call()) + step, 0.01)))))
	_rows.add_child(row)
	_refreshers.append(func() -> void: value.text = String.num(float(getter.call()), 2))


func _cycle_row(label: String, getter: Callable, advance: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(label))
	var value := Label.new()
	value.add_theme_font_override("font", NNFonts.or_default(NNFonts.mono(), self))
	value.add_theme_font_size_override("font_size", int(Tokens.TYPE["meta"]))
	value.add_theme_color_override("font_color", Palette.SPECTRAL_MINT)
	value.custom_minimum_size = Vector2(96, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_mini("<", func() -> void: _change(func() -> void: advance.call(-1))))
	row.add_child(value)
	row.add_child(_mini(">", func() -> void: _change(func() -> void: advance.call(1))))
	_rows.add_child(row)
	_refreshers.append(func() -> void: value.text = str(getter.call()))


func _toggle_row(label: String, getter: Callable, flip: Callable) -> void:
	var b := NNButton.new()
	b.variant = NNButton.Variant.GHOST
	b.ears = false
	b.font_size = int(Tokens.TYPE["meta"])
	b.custom_minimum_size = Vector2(0, 30)
	b.pressed.connect(func() -> void: _change(flip))
	_rows.add_child(b)
	_refreshers.append(func() -> void:
		b.text = "%s  %s" % [label, "ON" if bool(getter.call()) else "OFF"])


func _text_row(label: String, getter: Callable, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(label))
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(150, 28)
	edit.text_changed.connect(func(t: String) -> void:
		if _target != null:
			setter.call(t)
			edited.emit())
	row.add_child(edit)
	_rows.add_child(row)
	_refreshers.append(func() -> void:
		if not edit.has_focus():
			edit.text = str(getter.call()))


func _swatch_target_row() -> void:
	var b := NNButton.new()
	b.variant = NNButton.Variant.GHOST
	b.ears = false
	b.font_size = int(Tokens.TYPE["meta"])
	b.custom_minimum_size = Vector2(0, 30)
	b.pressed.connect(func() -> void:
		_accent_mode = not _accent_mode
		refresh())
	_rows.add_child(b)
	_refreshers.append(func() -> void:
		b.text = "PAINTING: %s" % ("ACCENT" if _accent_mode else "BASE"))


func _swatch_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for hex in SWATCHES:
		var c := Color(hex)
		var cell := ColorRect.new()
		cell.color = c
		cell.custom_minimum_size = Vector2(24, 24)
		cell.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed \
					and e.button_index == MOUSE_BUTTON_LEFT:
				_change(func() -> void:
					if _accent_mode:
						_target.accent_color = c
					else:
						_target.base_color = c))
		grid.add_child(cell)
	# A "clear accent" cell.
	var none := ColorRect.new()
	none.color = Color(0.1, 0.08, 0.13)
	none.custom_minimum_size = Vector2(24, 24)
	var x := Label.new()
	x.text = "×"
	x.position = Vector2(7, 1)
	none.add_child(x)
	none.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_change(func() -> void: _target.accent_color = Color(0, 0, 0, 0)))
	grid.add_child(none)
	_rows.add_child(grid)


func _light_presets() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var presets := [
		["OFF", Color(0, 0, 0, 0), 0.0],
		["AMB", Palette.WARM_AMBER, 0.9],
		["VIO", Palette.POSSESSED_VIOLET, 1.0],
		["MNT", Palette.SPECTRAL_MINT, 0.7],
		["BLU", Color("6f8fc4"), 0.5],
	]
	for preset in presets:
		var name_text: String = preset[0]
		var col: Color = preset[1]
		var energy: float = preset[2]
		var b := _mini(name_text, func() -> void:
			_change(func() -> void:
				_target.light_color = col
				_target.light_energy = energy
				if _target.light_scale <= 0.2:
					_target.light_scale = 3.0))
		b.custom_minimum_size = Vector2(48, 28)
		row.add_child(b)
	_rows.add_child(row)
