# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name TreeBatchGenerator
extends Node
## Example of a batch generator based on a preset.
## Usage: be careful when modifying values, avoid negative numbers.
## It's best to multiply by 0.9-1.1 existing ranges instead of adding/subtracting.

@export var presets: Array[CosmoTreePreset]
@export var amount: int = 1
@export_dir var export_dir: String
@export var instantiate: bool = false
@export var preview: bool = false
@export var preview_time: float = 1.0
@export_tool_button("Generate", "Add") var generate_button: Callable = generate

var _generating: bool = false
var _rng: RandomNumberGenerator


func _instantiate(trees: Array[CosmoTreeGen]) -> void:
	var pos_x: float = 0.0
	for tree: CosmoTreeGen in trees:
		add_child(tree, true)
		tree.owner = get_tree().edited_scene_root
		tree.position.x = pos_x
		tree.rotate_y(randf_range(0, TAU))
		pos_x += 5.0


func generate() -> void:
	if _generating:
		return

	if presets.is_empty() or presets.has(null):
		push_error("TreeBatchGenerator: presets is empty or has empty slots!")
		return

	if export_dir.is_empty():
		push_error("TreeBatchGenerator: export_dir is empty!")
		return

	_generating = true
	var trees: Array[CosmoTreeGen] = []

	var options: Dictionary = {
		"Use External Material": true,
		"Include Collisions": true,
	}

	_rng = RandomNumberGenerator.new()

	var i: int = 0
	for preset in presets:
		for x in amount:
			var s := Time.get_ticks_usec()
			var tree := CosmoTreeGen.new()
			tree.auto_generate = false
			tree.set_random_seed()

			# avoid negative values in filepath e.g.: (ash_-1234.glb)
			tree.noise_seed = absi(tree.noise_seed)

			_rng.seed = tree.noise_seed

			tree.apply_preset(preset)

			tree.trunk_params.height *= _rng.randf_range(0.8, 1.2)
			tree.trunk_params.radius_bottom *= _rng.randf_range(0.9, 1.1)
			tree.trunk_params.flare += _rng.randf_range(-0.05, 0.05)
			# example: this could potentially end up in negative lean in some presets
			#tree.trunk_params.lean += _rng.randf_range(-0.1, 0.1)
			# best to use *= randf_range
			tree.trunk_params.lean *= _rng.randf_range(0.7, 1.3)
			#tree.trunk_params.wobble = _rng.randf_range(1.5, 2.75)

			for level: CosmoBranchLevel in tree.branch_levels:
				level.count += _rng.randi_range(-1, 1)
				level.start *= _rng.randf_range(0.9, 1.1)
				level.end = minf(level.end * _rng.randf_range(0.9, 1.1), 1.0)
				level.angle *= _rng.randf_range(0.9, 1.1)
				level.length *= _rng.randf_range(0.9, 1.1)
				level.radius *= _rng.randf_range(0.9, 1.1)
				level.gnarl *= _rng.randf_range(0.9, 1.1)
				level.up_force *= _rng.randf_range(0.9, 1.1)

			tree.foliage_params.leaf_count += _rng.randi_range(-3, 3)
			tree.foliage_params.leaf_size += _rng.randf_range(-0.05, 0.05)
			tree.foliage_params.leaf_start = minf(
				tree.foliage_params.leaf_start * _rng.randf_range(0.9, 1.1), 1.0
			)
			tree.foliage_params.leaf_angle *= _rng.randf_range(0.9, 1.1)

			tree.collision_type = CosmoTreeGen.CollisionType.TRIMESH
			# trunk collision would cover 25% of the trunk height
			tree.collision_max_height = tree.trunk_params.height * 0.25
			#tree.collision_level = 2
			tree.foliage_collision_type = CosmoTreeGen.FoliageCollisionType.HULL

			# you can also change the materials
			#tree.trunk_material = preload("res://test/bark_4k.tres")
			#tree.foliage_material = preload("res://test/foliage_test.tres")

			tree.generate()
			var elapsed := (Time.get_ticks_usec() - s) / 1000.0

			var preset_name: String = preset.resource_path.get_file().get_basename()
			tree.name = preset_name.capitalize()
			var out_path: String = "%s/%s_%d.glb" % [export_dir, preset_name, tree.noise_seed]

			var err := await tree.export_gltf(out_path, options)

			if preview:
				add_child(tree)
				await get_tree().create_timer(preview_time).timeout
				remove_child(tree)

			if instantiate:
				trees.append(tree)
			else:
				tree.free()

			i += 1
			var progress: String = "%d/%d" % [i, amount * presets.size()]

			if err != OK:
				push_error("[%s] error generating tree: %s" % [progress, error_string(err)])
				continue

			print("[%s] generated %s and saved to: '%s' - took: %.2fms" % [
				progress, preset_name, out_path, elapsed
			])

	if instantiate:
		_instantiate(trees)

	_generating = false
