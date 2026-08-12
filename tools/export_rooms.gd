extends Node
## One-shot exporter: serialize every code-built room to data/rooms/.
##
## Run headless whenever a builder changes, to regenerate the JSON the game and
## the editor actually use:
##
##     godot --headless --path . res://tools/export_rooms.tscn --quit-after 60
##
## A scene rather than a --script MainLoop because the builders lean on the
## Palette autoload, and autoloads only exist in a normal game run.

func _ready() -> void:
	for id in RoomIO.builders().keys():
		var room: RoomModel = RoomIO.builders()[id].call()
		var path := RoomIO.save_room(room)
		if path == "":
			push_error("export_rooms: failed to write '%s'" % id)
		else:
			print("export_rooms: wrote ", path)
	get_tree().quit()
