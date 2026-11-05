# Exporting

Trees can be exported as `glb` or `glTF`, with LODs and collisions.

## How to export
1. Select a `CosmoTreeGen` node.
1. Click `Export glb/glTF` in the toolbar.
1. Choose the folder and the file name, by default it's the node name in snake_case.  
   The extension can be `.glb` or `.gltf`, the default one can be changed in the [settings](settings.md).
1. Check the export options you want and save.

The tree will appear in the FileSystem already imported. Now you can use it as is or as `New Inherited Scene`.

## Export options
The default value of each option can be changed in the [settings](settings.md).

- *Include Collisions*: Exports the trunk and foliage collisions. Default on.  
  Only works if `collision_type` and/or `foliage_collision_type` are set, otherwise there's nothing to export.
- *Export Images*: Exports the textures inside the glTF. Default off.  
  Note: if both "Export Images" and "Use External Material" are off, the tree will be imported without textures.
- *Use External Material*: The imported tree uses your material files (`.tres`) instead of a copy stored in the glTF. Default on.  
  This is recommended, glTF can't store shaders, so without it the leaves lose the wind sway shader. Also, any change to your materials will apply to all the exported trees.  
  Note: only materials saved as their own file are linked, built-in materials are exported as usual.

## What's exported
The exported scene has the same nodes as the `CosmoTreeGen` node, and the root node takes its name.

- *CosmoTree*: Trunk and foliage combined in one mesh.  
  If `combine_trunk_and_foliage` is off, there are two meshes instead: *Trunk* and *Foliage*.
- *_LOD0*, *_LOD1*, *_LOD2*: If `generate_lod` is on, each mesh has one of these suffixes.
- *Collision* and *FoliageCollision*: If "Include Collisions" is on.

## LODs
If `generate_lod` is on, the exporter also changes the `.import` file of the tree:
- Sets the visibility ranges of each LOD, using the distances from the [settings](settings.md).
- Disables Godot's automatic LOD generation (`meshes/generate_lods`), because it breaks the leaf cards. Don't turn it back on.
- Adds an import script (`lod_post_import.gd`) that restores the `custom_aabb` of the LODs, so they all swap at the same distance.

Note: if you change the LOD settings, you need to export the tree again.

## Exporting from scripts
Trees can also be exported from a `@tool` script with `export_gltf()`. The options use the same names as in the export window:

```gdscript
var tree := CosmoTreeGen.new()
tree.apply_preset(preload("res://addons/cosmo_tree_gen/presets/ash.tres"))
tree.generate()

var options: Dictionary = {
	"Include Collisions": true,
	"Use External Material": true,
}
var err := await tree.export_gltf("res://trees/ash.glb", options)
```

- If you create the tree from code, call `generate()` before exporting.
- Missing options are off, the default values from the settings are only used by the export window.
- It only works in the editor.

See `demo/batch_generator.gd` for a full example.

## Known issues
- *Export Images*: The textures are saved without a name (`.png`).
