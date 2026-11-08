# Batch generation

`demo/batch_generator.tscn` generates tens of trees with a single click: each one gets a random seed
and small variations of its preset (height, lean, branch angles...) and is saved as `<preset>_<seed>.glb`.  

## Using the demo batch generator
1. Open `demo/batch_generator.tscn` and select the `BatchGenerator` node.
1. Add the presets you want to `presets`. It already has `pine.tres` and `ash.tres`.
1. Set `amount`, the number of trees per preset. With 2 presets and an `amount` of 10, you get 20 trees.
1. Choose the folder in `export_dir`. It must exist, otherwise the export fails.
1. Click `Generate` in the inspector.
1. The Output panel prints the progress, the path and the generation time of each tree.

The trees are exported one by one, and each export waits for Godot to import the file, so big batches take a while.  
The file name is the preset file name plus the seed, e.g. `ash.tres` makes `ash_1234.glb`, with `Ash` as the root node.

### Parameters
| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `presets` | Empty | Presets to generate trees from. Each preset gets `amount` trees. It can't have empty slots. |
| `amount` | `1` | Number of trees per preset. |
| `export_dir` | Empty | Folder where the trees are saved. It must exist. |
| `instantiate` | `false` | Adds the generated `CosmoTreeGen` nodes to the scene when the batch ends, in a row 5 m apart and with a random rotation. Save the scene to keep them. |
| `preview` | `false` | Shows each tree in the scene for `preview_time` seconds after exporting it. It makes the batch slower. |
| `preview_time` | `1.0 s` | How long each tree is shown with `preview`. |
| *Generate* | | Button. Starts the batch. It does nothing if a batch is already running. |

Note: the instantiated trees are `CosmoTreeGen` nodes, not the exported files. Use the `.glb` files in your game, see [Getting Started](getting_started.md#next-steps).
Intantiating trees may be useful for fine tuning the ones you didn't like, bad seeds, etc... and re-exported again.

## Using it in your project
1. Copy `demo/batch_generator.gd` to your project.
1. Add a `TreeBatchGenerator` node (Ctrl+A) to any scene, or attach the script to a `Node`.
1. Change the script to your needs: variations, collisions, materials...

## Writing your own batch script
The minimum is: create a `CosmoTreeGen`, apply a preset, generate it, export it and free it.

```gdscript
@tool
extends Node

@export var preset: CosmoTreePreset
@export var amount: int = 10
@export_dir var export_dir: String
@export_tool_button("Generate", "Add") var generate_button: Callable = generate


func generate() -> void:
	for i in amount:
		var tree := CosmoTreeGen.new()
		tree.auto_generate = false
		tree.noise_seed = i
		tree.apply_preset(preset)
		tree.generate()

		tree.name = "MyTree"
		var path: String = "%s/my_tree_%d.glb" % [export_dir, i]
		var err := await tree.export_gltf(path, {"Use External Material": true})
		if err != OK:
			push_error("error exporting %s: %s" % [path, error_string(err)])

		tree.free()
```

- The script must be `@tool`, `export_gltf()` only works in the editor. Outside the editor it returns `ERR_UNAVAILABLE`.
- `apply_preset()` copies the preset, so you can change the parameters of the tree without changing the preset file.
- A tree created with `CosmoTreeGen.new()` isn't built until you call `generate()`. Call it once, after all your changes.
- Turn off `auto_generate`, so the tree is only built when you call `generate()`. Otherwise, if the tree is in the scene, every parameter change rebuilds it.
- `name` is the name of the root node in the exported scene.
- `export_gltf()` must be awaited. The options use the same names as in the export window, see [Exporting from scripts](exporting.md#exporting-from-scripts).
- `free()` the tree when you're done. It's not in the scene, so nothing else will free it.

### Random seeds
`set_random_seed()` sets a random `noise_seed`, but it can be negative. Use `absi()` to avoid file names like `ash_-1234.glb`:

```gdscript
tree.set_random_seed()
tree.noise_seed = absi(tree.noise_seed)
```

## Adding variations
The seed only changes the random values of the tree, the parameters are the same for every tree of a preset.  
To get more different trees, change the parameters after `apply_preset()` and before `generate()`:

```gdscript
tree.apply_preset(preset)

var rng := RandomNumberGenerator.new()
rng.seed = tree.noise_seed

tree.trunk_params.height *= rng.randf_range(0.8, 1.2)
tree.trunk_params.radius_bottom *= rng.randf_range(0.9, 1.1)
tree.trunk_params.lean *= rng.randf_range(0.7, 1.3)

for level: CosmoBranchLevel in tree.branch_levels:
	level.angle *= rng.randf_range(0.9, 1.1)
	level.length *= rng.randf_range(0.9, 1.1)
	level.end = minf(level.end * rng.randf_range(0.9, 1.1), 1.0)

tree.foliage_params.leaf_angle *= rng.randf_range(0.9, 1.1)

tree.generate()
```

Some tips:
- Use a `RandomNumberGenerator` with the tree seed instead of `randf()`. The same preset and seed always make the same tree, so with the file name (`ash_1234.glb`) you can make that tree again.  
  Note: if you change the variations in your script, the same seed will make a different tree.
- Multiply instead of adding. `*= rng.randf_range(0.9, 1.1)` keeps the value close to the preset one and never changes its sign.  
  Adding can end in negative values, e.g. a `lean` of `0.05` plus `-0.1`.
- Parameters from 0 to 1, like `start`, `end` or `leaf_start`, can go over 1 when multiplied. Cap them with `minf(value, 1.0)`.
- Be careful with integers like `count` or `leaf_count`: adding `randi_range(-3, 3)` to a small value can go below the minimum.
- The range of each parameter is in [Parameters](parameters.md).

## Collisions, LODs and materials
Presets don't save `generate_lod` or the collision parameters, so set them in your script.  
You can also give the whole batch your own materials:

```gdscript
tree.apply_preset(preset)

tree.generate_lod = true
tree.collision_type = CosmoTreeGen.CollisionType.TRIMESH
tree.collision_max_height = tree.trunk_params.height * 0.25
tree.foliage_collision_type = CosmoTreeGen.FoliageCollisionType.HULL

tree.trunk_material = preload("res://materials/my_bark.tres")
tree.foliage_material = preload("res://materials/my_leaves.tres")

tree.generate()

var options: Dictionary = {
	"Include Collisions": true,
	"Use External Material": true,
}
var err := await tree.export_gltf(path, options)
```

- Set the materials after `apply_preset()`, it replaces them with the preset ones.
- `collision_max_height` is in meters. If the height changes between trees, use a fraction of `trunk_params.height`, after the variations.
- Collisions are only exported with `"Include Collisions": true`.
- The LOD distances and ratios are the same for the whole batch, they come from the [settings](settings.md).
