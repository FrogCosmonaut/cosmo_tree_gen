# Exporting

Trees can be exported as `glb` or `glTF`, with LODs, impostor and collisions.

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
- *Use External Material*: The imported tree uses your material files (`.tres`)  
  instead of a copy stored in the glTF. Default on.  
  This is recommended, glTF can't store shaders, so without it the leaves lose the wind sway shader.  
  Also, any change to your materials will apply to all the exported trees.  
  Note: only materials saved as their own file are linked, built-in materials are exported as usual.
- *Impostor*: Bakes a billboard of the tree and adds it as the last LOD. Default *Static*.
  - *None*: No impostor will be generated.
  - *Static*: A quad that turns around its vertical axis to face the camera, with one view of the tree captured from the front.
  - *Octahedral*: A quad that faces the camera from any angle and blends between views of the tree captured from the side to straight above (144 with the default settings).  
    It looks right from every side and from above, but uses more memory, see the [settings](settings.md#cosmo-tree-gen--impostor).

  Its material is saved next to the glTF as `<file>_impostor.res`, and it's always linked as an external material,  
  even with "Use External Material" off.

## What's exported
The exported scene has the same nodes as the `CosmoTreeGen` node, and the root node takes its name.

- *CosmoTree*: Trunk and foliage combined in one mesh.  
  If `combine_trunk_and_foliage` is off, there are two meshes instead: *Trunk* and *Foliage*.
- *_LOD0*, *_LOD1*, *_LOD2*: If `generate_lod` is on, each mesh has one of these suffixes.
- *Impostor_LOD3*: If "Impostor" isn't None, the impostor is generated during the export.
- *Collision* and *FoliageCollision*: If "Include Collisions" is on.

## LODs and impostor
If `generate_lod` or *Impostor* isn't None, the exporter also changes the `.import` file of the tree:
- Sets the visibility ranges of each LOD and the impostor, using the distances from the [settings](settings.md#example-with-the-default-settings).  
  With an impostor, the last LOD (LOD2, or the tree itself if it has no LODs) ends at `impostor_distance`.
- Sets the `cast_shadow` of the impostor from the settings.
- Disables Godot's automatic LOD generation (`meshes/generate_lods`), because it breaks the leaf cards. Don't turn it back on.
- Adds an import script (`lod_post_import.gd`) that restores the `custom_aabb` of the LODs, so they all swap at the same distance.  
  With an impostor, the box is wider, so the billboard isn't cut at the screen edges when it turns.

Note: if you change the LOD or impostor settings, you need to export the tree again.  
Note: the impostor is baked on every export. With *Use External Material*, changes to your materials reach the exported LODs, but not the impostor: it keeps what it was baked with until you export again.  

## Exporting from scripts
Trees can also be exported from a `@tool` script with `export_gltf()`. The options use the same names as in the export window:

```gdscript
var tree := CosmoTreeGen.new()
tree.apply_preset(preload("res://addons/cosmo_tree_gen/presets/ash.tres"))
tree.generate()

var options: Dictionary = {
	"Include Collisions": true,
	"Use External Material": true,
	"Impostor": 2,
}
var err := await tree.export_gltf("res://trees/ash.glb", options)
```

- If you create the tree from code, call `generate()` before exporting.
- `"Impostor"` takes the index of the option: `0` None, `1` Static, `2` Octahedral.
- Missing options are off, the default values from the settings are only used by the export window.
- It only works in the editor.

See `demo/batch_generator.gd` for a full example.

Note: the impostor material uses `impostor_static.gdshader` or `impostor_octahedral.gdshader` from `addons/cosmo_tree_gen/shaders/`, copy them or keep the addon in your project.

## Known issues / Limitations
- *Export Images*: The textures are saved without a name (`.png`).
- *Impostor*: It has no wind.
- *Impostor* - *Static*: It's a single view of the tree, captured from the front (+Z).  
  It looks the same from every side, and like a thin card when seen from above.
- *Impostor* - *Octahedral*: With `cast_shadow` on, its shadow on the ground follows the shape of the tree,  
  but the impostor also shadows itself and part of the canopy turns dark.
- *Impostor*: Exporting again with *None* doesn't delete the old `<file>_impostor.res`.
