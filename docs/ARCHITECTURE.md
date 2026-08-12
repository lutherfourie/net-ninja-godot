# Architecture

## The one rule

**World data never knows how it is drawn.**

Everything in `src/core/` is expressed in world units on a right-handed 3D axis —
`+X` right, `+Y` up, `+Z` toward the camera, exactly Godot's 3D convention. No
file in `src/core/` imports a renderer, references a pixel, or extends `Node2D`.

That is what makes "2D now, 3D-ready" a real property rather than a hope. When
the stylized 3D pass from the visual foundation (p.12) begins, a `Room3DView`
reads the same `RoomModel`, spawns `MeshInstance3D` per `PropDef`, and the room
layout file does not change by a single line.

## Layers

```
┌──────────────────────────────────────────────────────────────┐
│  src/scenes/     main_menu.gd · room_hub.gd · boot.gd        │
│                  owns input, flow, interaction outcomes       │
└───────────────┬──────────────────────────┬───────────────────┘
                │ RoomView interface       │ tokens + palette
┌───────────────▼──────────────┐  ┌────────▼───────────────────┐
│  src/view/                   │  │  src/ui/                   │
│  room_view.gd    (contract)  │  │  nn_button · nn_panel      │
│  room_2d/        (renderer)  │  │  wordmark · ruined_shape   │
│  room_3d/        (later)     │  │  virtual_stick · prompts   │
└───────────────┬──────────────┘  └────────────────────────────┘
                │ reads, never writes
┌───────────────▼──────────────────────────────────────────────┐
│  src/core/     iso.gd · prop_def.gd · room_model.gd          │
│                actor_body.gd · rooms/ami_apartment.gd         │
│                pure data + maths, no nodes                    │
└──────────────────────────────────────────────────────────────┘
```

### `src/core/`

| File | Job |
| --- | --- |
| `iso.gd` | The projection. `to_screen`, `to_ground`, face polygons, depth keys. The *only* place the 2:1 dimetric constants exist. |
| `prop_def.gd` | One piece of furniture: origin, size, colour, blocking, interaction, attached light, decal name. A `Resource`, so props can move to the inspector later without a rewrite. |
| `room_model.gd` | A space: bounds, spawn, walkable rects, props, ambient tint. Answers `is_walkable`, `blockers`, `interactables`. |
| `actor_body.gd` | Character motion. Axis-separated AABB-vs-circle against `room.blockers()`. No physics server — a room of boxes does not need one, and skipping it keeps touch input immediate. |
| `rooms/ami_apartment.gd` | The flat, laid out from the concept render. Read it top to bottom and you walk the room clockwise. |

### `src/view/`

`room_view.gd` declares the contract every renderer implements: `setup`,
`sync_actor`, `set_camera_mode`, `set_actor_visible`, `highlight`, `prop_anchor`,
`project`. Scenes only ever call those seven methods.

`room_2d/` is the shipping renderer. Notable choices:

- **Painter's algorithm over `y_sort_enabled`.** Depth is `(x+sx) + (z+sz) + y/2`,
  quantised into `z_index`. Godot's Y-sort assumes a top-down 2D world; our sort
  key is derived from the same 3D coordinates the 3D view would use, so ordering
  stays consistent across renderers.
- **Walls and floors are pinned below everything** (`z_index` −3000/−2500) instead
  of participating in depth sorting. A wall spanning the whole room has a huge
  depth key and would otherwise paint over furniture at the near end.
- **Real 2D lights.** A `CanvasModulate` takes the canvas to night; `PointLight2D`
  pools add it back — amber for lamps, violet for the PC, cool blue at the window,
  mint on the wisps. This is how "warm pools of baked light" and "possession is
  environmental" get expressed without any baked textures.
- **The floor is one node, not one node per plank.** A room is a few hundred
  triangles; the win is in draw calls, not node count.

### `src/ui/`

`ruined_shape.gd` is the shared silhouette: chamfered body, cat-ear peaks returned
*separately* so every polygon handed to the renderer stays convex. Buttons, panels,
prompts, badges and the curse meter all build from it, which is why they read as
one family.

`tokens.gd` holds every layout number from the visual foundation. `_layout()`
methods recompute from viewport size on `size_changed`, so the menu composition is
correct on any aspect ratio rather than only at 720 × 1280.

## Adding a room

```gdscript
var room := RoomModel.new()
room.walk_rects = [Rect2(0.5, 0.5, 12, 9)]
room.spawn = Vector3(4, 0, 4)
room.add(PropDef.make({
    "id": "bed", "origin": Vector3(1, 0, 1), "size": Vector3(2, 0.8, 3),
    "base_color": Color("6d4630"), "kind": PropDef.Kind.SOFT,
    "interact_id": "sleep", "interact_label": "Sleep it off",
}))
```

No scene file, no sprite, no renderer knowledge.

## When the 3D view arrives

1. Add `src/view/room_3d/room_3d_view.gd` implementing `RoomView`, wrapping a
   `SubViewport` with an orthographic `Camera3D` at the isometric angle.
2. Map `PropDef.Kind` to meshes the way `prop_2d.gd` maps it to polygons.
3. Swap the `preload` in `main_menu.gd` / `room_hub.gd`.

Nothing in `src/core/` moves. That is the whole design.
