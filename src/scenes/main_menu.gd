extends Node2D
## Main menu — the first release's one clear action is START GAME.
##
## Structure follows PDF p.7 exactly: a responsive room illustration behind three
## separate UI layers (logo, Ami focal, CTA), with settings kept small and inside
## the safe area. Zones are recomputed on every resize so the composition holds
## from a 16:9 tablet to a 20:9 phone.

const Room2DView := preload("res://src/view/room_2d/room_2d_view.gd")
const Actor2D := preload("res://src/view/room_2d/actor_2d.gd")
const MenuScrim := preload("res://src/ui/menu_scrim.gd")
const SettingsPanel := preload("res://src/ui/settings_panel.gd")

## Ami stands slightly right of centre so the cat tree stays visible behind her.
const AMI_SCALE := 2.9

var _room_view  # Room2DView — untyped so the 2D-only framing knobs resolve
var _scrim: Control
var _wordmark: NNWordmark
var _start: NNButton
var _settings_button: NNButton
var _settings  # SettingsPanel — untyped so its script API resolves at runtime
var _ami_holder: Node2D
var _ami  # Actor2D
var _version: Label
var _t := 0.0


func _ready() -> void:
	GameState.possession = 0.35

	_room_view = Room2DView.new()
	add_child(_room_view)
	_room_view.setup(AmiApartment.build())
	# Frame the flat a little tight and a little high, so it sits behind the logo
	# and *under* Ami's feet rather than floating in the middle of the screen.
	_room_view.fit_zoom_boost = 1.24
	_room_view.fit_offset = Vector2(0, -104)
	_room_view.set_camera_mode(RoomView.CameraMode.FIT)
	_room_view.set_actor_visible(false)

	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)

	_scrim = MenuScrim.new()
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_scrim)

	# Ami, foregrounded and hand-placed rather than left to the room camera —
	# "Ami owns the centre".
	_ami_holder = Node2D.new()
	ui.add_child(_ami_holder)
	_ami = Actor2D.new()
	_ami.scale = Vector2(AMI_SCALE, AMI_SCALE)
	_ami_holder.add_child(_ami)
	_ami.sync(Vector3.ZERO, Vector2(0, 1), false, 0.0)

	_wordmark = NNWordmark.new()
	_wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_wordmark)

	_start = NNButton.new()
	_start.text = "START GAME"
	_start.variant = NNButton.Variant.PRIMARY
	_start.pressed.connect(func(): SceneRouter.goto("room"))
	ui.add_child(_start)

	_settings_button = NNButton.new()
	_settings_button.text = "SETTINGS"
	_settings_button.variant = NNButton.Variant.GHOST
	_settings_button.ears = false
	_settings_button.font_size = int(Tokens.TYPE["meta"]) + 2
	_settings_button.pressed.connect(func(): _settings.show_panel())
	ui.add_child(_settings_button)

	_version = Label.new()
	_version.text = "v%s · PROTOTYPE" % ProjectSettings.get_setting("application/config/version", "0.0.0")
	_version.add_theme_font_override("font", NNFonts.or_default(NNFonts.mono(), self))
	_version.add_theme_font_size_override("font_size", Tokens.TYPE["meta"])
	_version.add_theme_color_override("font_color", Palette.HEARTH_CREAM * Color(1, 1, 1, 0.5))
	_version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_version)

	_settings = SettingsPanel.new()
	ui.add_child(_settings)

	get_viewport().size_changed.connect(_layout)
	_layout()
	_start.grab_focus()


func _process(delta: float) -> void:
	# A breath of idle motion keeps the menu alive without animating anything
	# expensive. Respects the reduce-motion setting.
	if GameState.get_setting("reduce_motion", false):
		return
	_t += delta
	if _ami_holder:
		_ami_holder.position.y += sin(_t * 1.4) * 0.06


func _layout() -> void:
	var vp := get_viewport_rect().size
	var safe := Tokens.safe_rect(vp)

	# Logo zone: 16-32% height, max 54% of screen width.
	var logo := Tokens.zone_rect(Tokens.ZONE_LOGO, vp)
	var logo_w := minf(vp.x * Tokens.LOGO_MAX_WIDTH_RATIO, safe.size.x)
	logo_w = maxf(logo_w, Tokens.LOGO_MIN_WIDTH_PX)
	_wordmark.position = Vector2((vp.x - logo_w) * 0.5, logo.position.y)
	_wordmark.size = Vector2(logo_w, logo.size.y)

	# Focal zone: 32-78%. Ami's feet sit on the lower third of the band.
	var focal := Tokens.zone_rect(Tokens.ZONE_FOCAL, vp)
	_ami_holder.position = Vector2(vp.x * 0.52, focal.position.y + focal.size.y * 0.90)

	# CTA zone: 80-92%, one primary action, 64-88 px tall.
	var cta := Tokens.zone_rect(Tokens.ZONE_CTA, vp)
	var cta_h := clampf(cta.size.y, Tokens.CTA_MIN_HEIGHT, Tokens.CTA_MAX_HEIGHT)
	var cta_w := minf(safe.size.x, 460.0)
	_start.position = Vector2((vp.x - cta_w) * 0.5, cta.position.y)
	_start.custom_minimum_size = Vector2(cta_w, cta_h)
	_start.size = Vector2(cta_w, cta_h)

	# Secondary stays small, separate and inside the safe area.
	var s_size := Vector2(150.0, 46.0)
	_settings_button.position = Vector2((vp.x - s_size.x) * 0.5, cta.position.y + cta_h + 14.0)
	_settings_button.custom_minimum_size = s_size
	_settings_button.size = s_size

	_version.position = Vector2(safe.position.x, safe.end.y - Tokens.TYPE["meta"] - 6.0)

	# _scrim uses full-rect anchors; the viewport resize already sized it.
	_scrim.queue_redraw()
	_wordmark.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _settings.visible:
		SceneRouter.goto("room")
