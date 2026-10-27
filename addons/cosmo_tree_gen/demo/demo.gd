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

@export_group("Branches")
@export_range(0, 20) var branch_count: int = 6:
	set(value):
		branch_count = value
		_regenerate()
@export_range(0.0, 1.0) var branch_start: float = 0.4:
	set(value):
		branch_start = value
		_regenerate()
@export_range(0.0, 90.0) var branch_angle: float = 50.0:
	set(value):
		branch_angle = value
		_regenerate()
@export_range(0.05, 1.0) var branch_length: float = 0.4:
	set(value):
		branch_length = value
		_regenerate()
@export_range(0.1, 1.0) var branch_radius: float = 0.6:
	set(value):
		branch_radius = value
		_regenerate()
@export_range(1, 8) var branch_segments: int = 3:
	set(value):
		branch_segments = value
		_regenerate()
@export_range(0.0, 2.0) var branch_gnarl: float = 0.3:
	set(value):
		branch_gnarl = value
		_regenerate()
@export_range(-2.0, 2.0) var branch_up_force: float = 0.5:
	set(value):
		branch_up_force = value
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
	var trunk_radial := TrunkGen.BASE_RADIAL_SEGMENTS * trunk_quality
	var branch_radial := maxi(3, trunk_radial - 2)

	# Trunk
	var trunk := TrunkGen.generate_trunk(
		noise_seed,
		trunk_quality,
		trunk_height,
		trunk_radius_bottom,
		trunk_radius_top,
		lean_vec,
		trunk_wobble,
	)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	MeshUtils.append_tube(
		vertices, indices, trunk.points, trunk.radii, trunk_radial
	)

	# Branches
	var branches := TreeSkeleton.grow_branches(
		trunk,
		branch_count,
		branch_start,
		branch_angle,
		branch_length,
		branch_radius,
		branch_segments,
		branch_gnarl,
		branch_up_force,
	)
	for branch in branches:
		MeshUtils.append_tube(vertices, indices, branch.points, branch.radii, branch_radial)

	# Trunk + Branches mesh
	var trunk_mesh := MeshInstance3D.new()
	trunk_mesh.name = "Trunk"
	trunk_mesh.mesh = MeshUtils.build_mesh(vertices, indices, flat_shading)
	add_child(trunk_mesh)

	# Foliage
	# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
	var foliage_node := Node3D.new()  # TMP: all the icospheres should be joined in a single mesh.
	foliage_node.name = "Foliage"
	for i in branches.size():
		var foliage_mesh := MeshInstance3D.new()
		foliage_mesh.mesh = IcosphereGen.generate_icosphere(
			noise_seed + i,  # Increment seed so each icosphere is unique.
			foliage_subdivisions,
			foliage_amplitude,
			foliage_frequency,
			flat_shading,
		)
		foliage_mesh.position = branches[i].tip()
		foliage_node.add_child(foliage_mesh)
	add_child(foliage_node)
