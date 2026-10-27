# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends StaticBody3D

@export_tool_button("Generate Tree") var gen: Callable = generate_tree
@export var noise_seed: int = 42:
	set(value):
		noise_seed = value
		_regenerate()
@export var flat_shading: bool = true:
	set(value):
		flat_shading = value
		_regenerate()

@export_group("Trunk")
@export_range(1, 6) var trunk_quality: int = 1:
	set(value):
		trunk_quality = value
		_regenerate()
@export_range(0.0, 25.0, 0.1) var trunk_height: float = 5.0:
	set(value):
		trunk_height = value
		_regenerate()
@export_range(0.0, 5.0, 0.01) var trunk_radius_bottom: float = 0.35:
	set(value):
		trunk_radius_bottom = value
		_regenerate()
@export_range(0.0, 2.5, 0.01) var trunk_radius_top: float = 0.1:
	set(value):
		trunk_radius_top = value
		_regenerate()
@export_range(0.0, 2.0) var trunk_lean: float = 0.6:
	set(value):
		trunk_lean = value
		_regenerate()
@export_range(0.0, 1.0) var trunk_wobble: float = 0.15:
	set(value):
		trunk_wobble = value
		_regenerate()

@export_group("Foliage")
@export_range(0, 4) var foliage_subdivisions: int = 1:
	set(value):
		foliage_subdivisions = value
		_regenerate()
@export_range(0.0, 0.6) var foliage_amplitude: float = 0.4:
	set(value):
		foliage_amplitude = value
		_regenerate()
@export_range(0.1, 10.0) var foliage_frequency: float = 1.5:
	set(value):
		foliage_frequency = value
		_regenerate()


func _ready() -> void:
	generate_tree()


func _regenerate() -> void:
	if is_node_ready():
		generate_tree()


func _clear_generated() -> void:
	for node_name: String in ["Trunk", "Foliage"]:
		var node := get_node_or_null(node_name)
		if node:
			remove_child(node)
			node.free()


func generate_tree() -> void:
	_clear_generated()

	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var angle := rng.randf() * TAU
	var lean_vec := Vector3(cos(angle), 0.0, sin(angle)) * trunk_lean
	var trunk_top := Vector3(lean_vec.x, trunk_height, lean_vec.z)

	var trunk := MeshInstance3D.new()
	trunk.mesh = TrunkGen.generate_trunk(
		noise_seed,
		trunk_quality,
		trunk_height,
		trunk_radius_bottom,
		trunk_radius_top,
		lean_vec,
		trunk_wobble,
		flat_shading,
	)
	add_child(trunk)

	# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
	var foliage := MeshInstance3D.new()
	foliage.mesh = IcosphereGen.generate_icosphere(
		noise_seed,
		foliage_subdivisions,
		foliage_amplitude,
		foliage_frequency,
		flat_shading,
	)
	foliage.position = trunk_top
	add_child(foliage)
