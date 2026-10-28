# Copyright © 2026 CosmonautFrog - MIT License

@tool
@icon("../tree.svg")
class_name CosmoTreeGen
extends Node3D

const Branch := preload("./branch.gd")
const TrunkGen := preload("./trunk_gen.gd")
const MeshUtils := preload("./mesh_utils.gd")
const TreeSkeleton := preload("./tree_skeleton.gd")
const IcosphereGen := preload("./icosphere_gen.gd")

@export_tool_button("Generate Tree") var gen: Callable = generate_tree
@export var auto_update: bool = true:
	set(value):
		auto_update = value
		if auto_update:
			_regenerate()
@export var noise_seed: int = 42:
	set(value):
		noise_seed = value
		_regenerate()
@export var flat_shading: bool = true:
	set(value):
		flat_shading = value
		_regenerate()

@export var trunk_params: CosmoTrunkParams = CosmoTrunkParams.new():
	set(value):
		_swap_watch(trunk_params, value)
		trunk_params = value
		_regenerate()

@export var branch_levels: Array[CosmoBranchLevel] = []:
	set(value):
		for level in branch_levels:
			_swap_watch(level, null)
		branch_levels = value
		for level in branch_levels:
			_swap_watch(null, level)
		_regenerate()

@export var foliage: CosmoFoliageParams = CosmoFoliageParams.new():
	set(value):
		_swap_watch(foliage, value)
		foliage = value
		_regenerate()

@export_group("Collision")
@export var use_collision: bool = false:
	set(value):
		use_collision = value
		_regenerate()
@export_flags_3d_physics var collision_layer: int = 1
@export_flags_3d_physics var collision_mask: int = 1


func _init() -> void:
	name = "CosmoTreeGen"


func _ready() -> void:
	_swap_watch(null, trunk_params)
	_swap_watch(null, foliage)
	generate_tree()


func _swap_watch(old: Resource, new: Resource) -> void:
	if old and old.changed.is_connected(_regenerate):
		old.changed.disconnect(_regenerate)
	if new and not new.changed.is_connected(_regenerate):
		new.changed.connect(_regenerate)


func _regenerate() -> void:
	if not auto_update:
		return

	if is_node_ready():
		generate_tree()


func _clear_generated() -> void:
	for node_name: String in ["Trunk", "Foliage", "Collision"]:
		var node := get_node_or_null(node_name)
		if node:
			remove_child(node)
			node.free()


func _add_icospheres(branches: Array[Branch]) -> void:
	# TODO: all the icospheres should be joined in a single mesh.
	var foliage_node := Node3D.new()
	foliage_node.name = "Foliage"
	var trunk := branches[0]
	for branch in branches:
		var length_ratio := branch.get_length() / trunk.get_length()
		var foliage_mesh := MeshInstance3D.new()
		foliage_mesh.mesh = IcosphereGen.generate_icosphere(
			branch.branch_seed,
			foliage.radius * lerpf(1.0, length_ratio, foliage.length_influence),
			foliage.subdivisions,
			foliage.amplitude,
			foliage.frequency,
			flat_shading,
		)
		foliage_mesh.position = branch.tip()
		foliage_node.add_child(foliage_mesh)
	add_child(foliage_node)


func generate_tree() -> void:
	_clear_generated()

	var trunk_radial := TrunkGen.BASE_RADIAL_SEGMENTS * trunk_params.quality
	var branch_radial := maxi(3, trunk_radial - 2)

	# Trunk
	var trunk := TrunkGen.generate_trunk(noise_seed, trunk_params)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	MeshUtils.append_tube(
		vertices, indices, trunk.points, trunk.radii, trunk_radial
	)

	if use_collision:
		var static_body := StaticBody3D.new()
		static_body.name = "Collision"
		static_body.collision_layer = collision_layer
		static_body.collision_mask = collision_mask
		var col_shape := CollisionShape3D.new()
		col_shape.name = "TrunkCollisionShape"
		var convex_shape := ConvexPolygonShape3D.new()
		convex_shape.points = vertices.duplicate()
		col_shape.shape = convex_shape
		static_body.add_child(col_shape)
		add_child(static_body)

	# Branches
	var branches: Array[Branch] = []
	var parents: Array[Branch] = [trunk]
	for level in branch_levels:
		if level == null:
			continue
		var children: Array[Branch] = []
		for parent in parents:
			children.append_array(TreeSkeleton.grow_branches(parent, level))
		branches.append_array(children)
		parents = children

	for branch in branches:
		MeshUtils.append_tube(vertices, indices, branch.points, branch.radii, branch_radial)

	# Trunk + Branches mesh
	var trunk_mesh := MeshInstance3D.new()
	trunk_mesh.name = "Trunk"
	trunk_mesh.mesh = MeshUtils.build_mesh(vertices, indices, flat_shading)
	add_child(trunk_mesh)

	# Foliage
	# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
	var tips: Array[Branch] = [trunk]
	if not branches.is_empty():
		tips.append_array(parents)

	match foliage.type:
		CosmoFoliageParams.FoliageType.NONE: pass  # TODO: maybe close branch caps?
		CosmoFoliageParams.FoliageType.ICOSPHERES: _add_icospheres(tips)
