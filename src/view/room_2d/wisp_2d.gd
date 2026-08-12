extends Node2D
## A spectral wisp: mint, drifting, harmless-looking.
##
## Mint means "cleansing" in the colour system, so wisps read as residue from a
## previous exorcism rather than as a threat. They are the cheapest way to make a
## still room feel haunted, which is why the concept render has three of them.

const TRAIL := 4

var home := Vector3.ZERO
var drift := Vector3(0.9, 0.55, 0.7)
var speed := 0.55
var phase := 0.0

var _t := 0.0
var _history: Array[Vector2] = []
var _light: PointLight2D


func setup(at: Vector3, seed_phase: float, light_texture: Texture2D) -> void:
	home = at
	phase = seed_phase
	z_index = Iso.depth_to_z_index(Iso.depth(at, Vector3.ONE)) + 4

	_light = PointLight2D.new()
	_light.texture = light_texture
	_light.color = Palette.SPECTRAL_MINT
	_light.energy = 0.7
	_light.texture_scale = 1.1
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(_light)


func _process(delta: float) -> void:
	var rate := 0.25 if GameState.get_setting("reduce_motion", false) else 1.0
	_t += delta * speed * rate

	var p := home + Vector3(
		sin(_t * 1.7 + phase) * drift.x,
		1.0 + sin(_t * 2.3 + phase * 1.7) * drift.y,
		cos(_t * 1.3 + phase * 0.6) * drift.z
	)
	var screen := Iso.to_screen(p)
	_light.position = screen

	_history.push_front(screen)
	if _history.size() > TRAIL * 3:
		_history.resize(TRAIL * 3)
	queue_redraw()


func _draw() -> void:
	if _history.is_empty():
		return
	var head: Vector2 = _history[0]
	# Trail, oldest and smallest first.
	for i in range(mini(TRAIL, _history.size() / 3)):
		var p: Vector2 = _history[i * 3]
		var f := 1.0 - float(i) / float(TRAIL)
		var c: Color = Palette.SPECTRAL_MINT
		c.a = 0.14 * f
		draw_circle(p, 9.0 * f + 2.0, c)
	var glow: Color = Palette.SPECTRAL_MINT
	glow.a = 0.22
	draw_circle(head, 13.0, glow)
	draw_circle(head, 6.5, Palette.SPECTRAL_MINT)
	draw_circle(head + Vector2(-1.5, -2.0), 2.8, Palette.HEARTH_CREAM)
