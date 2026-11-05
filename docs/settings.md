# Settings

There are a few options to customize the addon behaviour.  
They're on `Project Settings > General > Cosmo Tree Gen`.  

## Cosmo Tree Gen > Generator
These settings control the automatic LODs and apply to every tree in the project.  
They only have an effect on trees with `generate_lod` enabled. 

Trees don't update by themselves when you change a setting: press **Generate tree** on each
`CosmoTreeGen` node to apply it. Trees you already exported need to be exported again.  

| Setting | Default | Description |
| ------- | ------- | ----------- |
| `lod1_ratio` | `0.4` | Triangle budget for LOD1, as a fraction of LOD0's triangles (trunk + foliage). |
| `lod2_ratio` | `0.15` | Triangle budget for LOD2, as a fraction of LOD0's triangles. |
| `lod1_distance` | `50 m` | Distance at which LOD0 switches to LOD1. |
| `lod2_distance` | `100 m` | Distance at which LOD1 switches to LOD2. |
| `lod_end_distance` | `0 m` | Distance at which LOD2 stops being drawn. `0` keeps it visible at any distance. |

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
- LOD2: Will be visible from 100 meters to infinity.

Note: This addon sets the `custom_aabb` of each LOD so the transition between them is as seamless as possible. It uses a Post Import script on the exported trees to achieve it: `lod_post_import.gd`.  
Note: LOD3 / impostor is planned to be implemented with an billboard/octahedral impostor. See more about that [here](https://cosmonautfrog.es/blog/asset-optimization-in-godot/).  

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
