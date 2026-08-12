extends Node
## Tiny run-time state holder for the prototype.
##
## Deliberately thin: the prototype only needs enough state to prove the menu ->
## room flow and the "possession is environmental" mood switch. Anything that
## needs to survive a session belongs in a saved Resource later.

signal possession_changed(level: float)
signal setting_changed(key: String, value: Variant)

## 0.0 = the house reads as purely cozy. 1.0 = fully cursed (violet PC bloom,
## harder cat shadow, more wisps). The room view listens to this.
var possession: float = 0.35:
	set(value):
		var v := clampf(value, 0.0, 1.0)
		if is_equal_approx(v, possession):
			return
		possession = v
		possession_changed.emit(v)

var settings := {
	"reduce_motion": false,   ## Accessibility: damps wisp drift and screen shake
	"high_contrast": false,   ## Boosts text/panel separation
	"master_volume": 0.8,
	"show_debug": false,
}


func set_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		push_warning("Unknown setting: %s" % key)
		return
	if settings[key] == value:
		return
	settings[key] = value
	setting_changed.emit(key, value)


func get_setting(key: String, fallback: Variant = null) -> Variant:
	return settings.get(key, fallback)
