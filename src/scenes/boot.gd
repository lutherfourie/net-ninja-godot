extends Node
## Entry point. Warms the palette autoloads, then hands straight to the menu.
##
## Kept as its own scene so future boot work (save load, remote config, a legal
## card) has somewhere to live that is not the menu.

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.MIDNIGHT_INK)
	if not NNFonts.has_brand_fonts():
		print_rich("[color=#e6a45b]Net Ninja:[/color] brand fonts not found in " +
			"assets/fonts/ — falling back to the engine default. " +
			"Run tools/fetch_fonts.ps1 (Windows) or tools/fetch_fonts.sh once.")
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")
