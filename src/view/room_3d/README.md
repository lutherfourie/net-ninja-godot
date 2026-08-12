# `room_3d/` — reserved

Empty on purpose.

When the stylized 3D pass begins (Visual Foundation p.12), `room_3d_view.gd` lands
here implementing the same `RoomView` contract as `room_2d/room_2d_view.gd`:

```gdscript
extends RoomView

func setup(room: RoomModel) -> void:
    # SubViewport + orthographic Camera3D at the isometric angle.
    # One MeshInstance3D per PropDef, using prop.origin / prop.size verbatim.
```

`PropDef` and `RoomModel` already speak `Vector3` in Godot's 3D convention, so
nothing in `src/core/` changes — including `rooms/ami_apartment.gd`, which stays
the single description of the flat for both renderers.

Targets from the foundation: stylized low-poly, baked light where possible,
shallow perspective camera to protect portrait readability, 60 fps on mid-range
phones.
