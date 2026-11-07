# Getting Started

## Requirements
Godot 4.6+ is required. Developed in 4.6.2.

## Installation
Copy `addons/cosmo_tree_gen/` to your project and activate the plugin, `Project > Project Settings > Plugins`.  
It must be in `res://addons/cosmo_tree_gen/`, otherwise Godot won't find the plugin.  
Once activated, some extra settings will be added to `Project Settings > General > Cosmo Tree Gen`. [More info about settings](settings.md)

## My first tree in 5 minutes
1. Create a new 3D scene or use an existing one.
1. Add a new `CosmoTreeGen` node (Ctrl+A).
1. Once the node is added, you will see a toolbar above the 3D viewport when that node is selected.
1. Click on `Preset > Ash` to load the included "Ash" preset.
1. Tweak the `trunk_params`, `branch_levels` and `foliage_params` in the inspector.  
   For example, change `trunk_params.height` to increase the height of the trunk(s).  
   [More info about what parameters do](parameters.md).
1. Click on `Seed` until you find a tree you like.
1. Optionally, change bark and foliage materials under `Materials`, the addon includes materials, but you can (and should) use yours.  
   Note that if you're using icosphere foliage, you should use a material with UV1 Triplanar activated. Otherwise it will look bad.  
   The included `foliage.tres` already has UV1 Triplanar activated.  
   Leaf cards take the shape of the foliage albedo texture (if `leaf_aspect` is 0), and the bark texture size depends on `texel_density`.
1. You can save the modified params as a new custom preset: `Preset > Save Preset`.
1. Optionally, enable `generate_lod` for LODs and set `collision_type` and/or `foliage_collision_type` for collisions.  
   If none of them are set, "Include Collisions" won't export anything. [More info about LODs](settings.md)
1. Once you're happy with your tree, click `Export glb/glTF`.
1. A save window will pop up, there are three extra options there: "Include Collisions", "Export Images" and "Use External Material". [More info about export options](exporting.md)
1. Save it to the desired folder, and that's all.  
   The tree will appear in the FileSystem already imported. Now you can use the `glb/glTF` as is or as `New Inherited Scene`.  
   If it has LODs, they will swap automatically with the distance.

## Next steps
- You don't need to export the tree, the `CosmoTreeGen` node can be used as is for quick prototyping.  
However, this isn't recommended for production, because the tree is generated every time the scene is loaded, which can slow down loading.  
Also, if you have multiple instances of the same tree with the same seed, their meshes won't be shared, resulting in duplicate draw calls.
- Check the `demo` folder, there are 7 more presets in `demo/extra_presets`.
- Generate tens of trees at once with `demo/batch_generator.tscn`. Copy `batch_generator.gd` to your project and change it to your needs.
- Read more about [parameters](parameters.md), [settings](settings.md) and [exporting](exporting.md).
