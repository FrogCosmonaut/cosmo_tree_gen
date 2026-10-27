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

	var cyl := TrunkGen.generate_trunk(
		noise_seed,
		trunk_quality,
		trunk_height,
		trunk_radius_bottom,
		trunk_radius_top,
		flat_shading,
	)
	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"
	trunk.mesh = cyl
	trunk.position = Vector3(0.0, trunk_height * 0.5, 0.0)
	add_child(trunk)
	trunk.owner = self

	# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
	var ico := IcosphereGen.generate_icosphere(
		noise_seed,
		foliage_subdivisions,
		foliage_amplitude,
		foliage_frequency,
		flat_shading,
	)
	var foliage := MeshInstance3D.new()
	foliage.name = "Foliage"
	foliage.mesh = ico
	foliage.position = Vector3(0.0, trunk_height, 0.0)
	add_child(foliage)
	foliage.owner = self
