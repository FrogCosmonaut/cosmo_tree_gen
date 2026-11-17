# Settings

There are a few options to customize the addon behaviour.  
They're on `Project Settings > General > Cosmo Tree Gen`.  

## Cosmo Tree Gen > Generator
These settings control the automatic LODs and apply to every tree in the project.  
They only have an effect on trees with `generate_lod` enabled, except `lod_end_distance`, 
which also applies to trees exported with an impostor.

Trees don't update by themselves when you change a setting: press **Generate tree** on each
`CosmoTreeGen` node to apply it. Trees you already exported need to be exported again.  

| Setting | Default | Description |
| ------- | ------- | ----------- |
| `lod1_ratio` | `0.4` | Triangle budget for LOD1, as a fraction of LOD0's triangles (trunk + foliage). |
| `lod2_ratio` | `0.15` | Triangle budget for LOD2, as a fraction of LOD0's triangles. |
| `lod1_distance` | `50 m` | Distance at which LOD0 switches to LOD1. |
| `lod2_distance` | `100 m` | Distance at which LOD1 switches to LOD2. |
| `lod_end_distance` | `0 m` | Distance at which the last LOD stops being drawn: the impostor if the tree was exported with one, otherwise LOD2. `0` keeps it visible at any distance. |

### How the triangle budget works
Each LOD gets a budget of `LOD0 triangles × ratio`. The trunk takes its share first, and the
foliage gets what's left. For example, for LOD1 with the default settings:

1. **Budget**: a tree with 3,500 trunk triangles and 6,500 foliage triangles has 10,000 in total, so LOD1 gets 10,000 × 0.4 = 4,000.
1. **Trunk**: it's simplified to `budget × lod_trunk_share`. With the default share of 0.33, that's 4,000 * 0.33 = 1,300 triangles.
1. **Foliage**: it gets the remaining ~2,700 triangles.
   - Leaf cards aren't simplified. Some cards are dropped and the remaining ones are scaled up, so the canopy keeps its size and shape.
   - Icospheres are simplified like the trunk.

`lod_trunk_share` is set per tree on the `CosmoTreeGen` node and is saved in presets.  
Raise it to keep more trunk detail, lower it to keep more leaves.  

If the foliage needs less than what's left, the trunk keeps the rest of the budget.  
A tree without foliage spends the whole budget on the trunk.  

### Example with the default settings
- LOD0: Will be visible from 0 to 50 meters.
- LOD1: Will be visible from 50 to 100 meters.
- LOD2: Will be visible from 100 meters to infinity, or to 150 meters if the tree is exported with an impostor.
- Impostor: Will be visible from 150 meters to infinity.

Note: This addon sets the `custom_aabb` of each LOD so the transition between them is as seamless as possible.  
It uses a Post Import script on the exported trees to achieve it: `lod_post_import.gd`.  

See [Visibility ranges (HLOD)](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html) for more info amout how LOD works.  

## Cosmo Tree Gen > Export

These are the starting values of the export dialog. You can still change them on each export.
See [Exporting](exporting.md) for what each option does.

| Setting | Default | Description |
| ------- | ------- | ----------- |
| `default_extension` | `glb` | File extension suggested in the export dialog: `glb` or `gltf`. |
| `default_include_collisions` | `true` | Starting value of *Include Collisions*. |
| `default_export_images` | `false` | Starting value of *Export Images*. |
| `default_use_external_material` | `true` | Starting value of *Use External Material*. |
| `default_impostor` | `Static` | Starting value of *Impostor*: None, Static or Octahedral. |

## Cosmo Tree Gen > Impostor

Used when a tree is exported with *Impostor* set to *Static* or *Octahedral*. The changes apply the next time you export the tree.

| Setting | Default | Description |
| ------- | ------- | ----------- |
| `impostor_distance` | `150.0` | Distance at which the last LOD switches to the impostor: LOD2, or the tree itself if it has no LODs. With LODs it must be greater than `lod2_distance`, otherwise the export prints a warning. |
| `static_resolution` | `512` | *Static*: Longest side of the textures, the other side follows the tree proportions. Halving it uses about 4 times less memory. |
| `octahedral_frames` | `12` | *Octahedral*: Views per side of the atlas, 12 * 12 = 144 views. More views make the change between angles smoother, but each view gets fewer pixels. |
| `octahedral_resolution` | `1024` | *Octahedral*: Size of the atlas. Each view gets `octahedral_resolution / octahedral_frames` pixels, 84 px with the default values. Halving it uses about 4 times less memory. |
| `cast_shadow` | `false` | Whether the impostor casts shadows. Off by default: the *Static* shadow turns when the camera moves, and the *Octahedral* one also darkens the impostor itself. |

Note: `DirectionalLight3D` only draws shadows up to its `directional_shadow_max_distance` (100 m by default), so with the default `impostor_distance` the impostor shadow won't show even with `cast_shadow` on.
Note: with the default values, a *Static* impostor uses about 0.5 MB of video memory and an *Octahedral* one about 2.7 MB
