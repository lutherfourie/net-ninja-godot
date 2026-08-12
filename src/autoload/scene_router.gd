extends Node
## Scene transitions with a short cross-fade.
##
## Kept as an autoload so scenes never reach into each other. The fade colour is
## MIDNIGHT_INK, which keeps the "cozy dark" base consistent between screens.

const ROUTES := {
	"menu": "res://src/scenes/main_menu.tscn",
	"room": "res://src/scenes/room_hub.tscn",
	"catch": "res://src/scenes/catch_game.tscn",
	"editor": "res://src/scenes/room_editor.tscn",
}

const FADE_TIME := 0.28

var _overlay: ColorRect
var _busy := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Palette.MIDNIGHT_INK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	layer.add_child(_overlay)


func goto(route: String) -> void:
	if _busy:
		return
	if not ROUTES.has(route):
		push_error("SceneRouter: unknown route '%s'" % route)
		return
	_busy = true

	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_TIME)
	await tween.finished

	var err := get_tree().change_scene_to_file(ROUTES[route])
	if err != OK:
		push_error("SceneRouter: failed to load '%s' (%d)" % [ROUTES[route], err])

	# Let the new scene build itself before we reveal it.
	await get_tree().process_frame

	var out := create_tween()
	out.tween_property(_overlay, "modulate:a", 0.0, FADE_TIME)
	await out.finished
	_busy = false
