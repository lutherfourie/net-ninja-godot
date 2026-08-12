class_name RoomView
extends Node2D
## Contract every room renderer must satisfy.
##
## The room hub and the main menu only ever talk to this interface, so swapping
## Room2DView for a future Room3DView is a one-line change in the scene file.
## (Node2D is the base today because the 2D view ships first; a 3D view would sit
## behind a SubViewport presented through a Node2D wrapper implementing the same
## methods. See docs/ARCHITECTURE.md.)

enum CameraMode {
	FIT,     ## Frame the whole room — used by the menu backdrop
	FOLLOW,  ## Track the actor — used in the hub
}


## Build the renderer for a room. Safe to call more than once.
func setup(_room: RoomModel) -> void:
	push_error("RoomView.setup() not implemented by %s" % get_script().resource_path)


## Push the actor's world state for this frame.
func sync_actor(_position: Vector3, _facing: Vector2, _moving: bool, _travel: float) -> void:
	pass


func set_camera_mode(_mode: CameraMode) -> void:
	pass


## Menus reuse the room as a backdrop without the player standing in it.
func set_actor_visible(_v: bool) -> void:
	pass


## Highlight (or clear, with an empty id) the currently interactable prop.
func highlight(_prop_id: String) -> void:
	pass


## World position of a named prop's centre, e.g. for placing a UI prompt.
func prop_anchor(_prop_id: String) -> Vector2:
	return Vector2.ZERO


## Project a world point into this view's canvas space.
func project(world: Vector3) -> Vector2:
	return Iso.to_screen(world)
