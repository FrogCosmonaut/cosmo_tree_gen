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
const LeafGen := preload("./leaf_gen.gd")

const TRUNK_NODE_NAME: String = "Trunk"
const FOLIAGE_NODE_NAME: String = "Foliage"
const COLLISION_NODE_NAME: String = "Collision"

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
@export var flat_shading: bool = false:
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

@export var foliage_params: CosmoFoliageParams = CosmoFoliageParams.new():
	set(value):
		_swap_watch(foliage_params, value)
		foliage_params = value
		_regenerate()

@export_group("Meshes")
@export var create_trunk: bool = true:
	set(value):
		create_trunk = value
		_regenerate()
@export var create_foliage: bool = true:
	set(value):
		create_foliage = value
		_regenerate()

@export_group("Collision")
@export var use_collision: bool = false:
	set(value):
		use_collision = value
		_regenerate()
@export_flags_3d_physics var collision_layer: int = 1:
	set(value):
		collision_layer = value
		_regenerate()
@export_flags_3d_physics var collision_mask: int = 1:
	set(value):
		collision_mask = value
		_regenerate()

@export_group("Materials")
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "BaseMaterial3D,ShaderMaterial")
var trunk_material: Material: set = _set_trunk_material
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "BaseMaterial3D,ShaderMaterial")
var foliage_material: Material: set = _set_foliage_material


func _init() -> void:
	name = "CosmoTreeGen"


func _ready() -> void:
	_swap_watch(null, trunk_params)
	_swap_watch(null, foliage_params)
	generate_tree()


func _set_trunk_material(value: Material) -> void:
	trunk_material = value

	var trunk_mesh := get_node_or_null(TRUNK_NODE_NAME) as MeshInstance3D
	if trunk_mesh == null:
		return

	trunk_mesh.mesh.surface_set_material(0, trunk_material)


func _set_foliage_material(value: Material) -> void:
	foliage_material = value

	var foliage_mesh := get_node_or_null(FOLIAGE_NODE_NAME) as MeshInstance3D
	if foliage_mesh == null:
		return

	foliage_mesh.mesh.surface_set_material(0, foliage_material)
	if foliage_params.type == CosmoFoliageParams.Type.ICOSPHERES and foliage_material is StandardMaterial3D:
		if not (foliage_material as StandardMaterial3D).uv1_triplanar:
			push_warning("CosmoTreeGen: foliage_material should use UV1 triplanar!")


func _apply_materials() -> void:
	_set_trunk_material(trunk_material)
	_set_foliage_material(foliage_material)


func _swap_watch(old: Resource, new: Resource) -> void:
	if old and old.changed.is_connected(_regenerate):
		old.changed.disconnect(_regenerate)
	if new and not new.changed.is_connected(_regenerate):
		new.changed.connect(_regenerate)


func _regenerate() -> void:
	if is_node_ready() and auto_update:
		generate_tree()


func _clear_generated() -> void:
	for node_name: String in [TRUNK_NODE_NAME, FOLIAGE_NODE_NAME, COLLISION_NODE_NAME]:
		var node := get_node_or_null(node_name)
		if node:
			remove_child(node)
			node.free()


func _add_trunk_collision(trunk_vertices: PackedVector3Array) -> void:
	var static_body := StaticBody3D.new()
	static_body.name = COLLISION_NODE_NAME
	static_body.collision_layer = collision_layer
	static_body.collision_mask = collision_mask

	var col_shape := CollisionShape3D.new()
	col_shape.name = "TrunkCollisionShape"

	var convex_shape := ConvexPolygonShape3D.new()
	convex_shape.points = trunk_vertices.duplicate()

	col_shape.shape = convex_shape
	static_body.add_child(col_shape)
	add_child(static_body)


func _add_icospheres(branches: Array[Branch]) -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var trunk := branches[0]
	for branch in branches:
		var length_ratio := branch.get_length() / trunk.get_length()
		var length_influence := lerpf(1.0, length_ratio, foliage_params.icosphere_length_influence)
		IcosphereGen.append_icosphere(
			vertices,
			indices,
			branch.tip(),
			branch.branch_seed,
			foliage_params.icosphere_radius * length_influence,
			foliage_params.icosphere_subdivisions,
			foliage_params.icosphere_amplitude,
			foliage_params.icosphere_frequency,
		)
	var foliage_mesh := MeshInstance3D.new()
	foliage_mesh.name = FOLIAGE_NODE_NAME
	foliage_mesh.mesh = MeshUtils.build_mesh(vertices, indices, flat_shading)
	add_child(foliage_mesh)


func _add_leaves(tips: Array[Branch]) -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	# tips[0] is the trunk, only gets leaves when there are no branches
	var first := 1 if tips.size() > 1 else 0
	for i in range(first, tips.size()):
		LeafGen.append_leaves(vertices, indices, uvs, tips[i], foliage_params)

	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	LeafGen.canopy_shading(vertices, normals, colors, foliage_params)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var foliage_mesh := MeshInstance3D.new()
	foliage_mesh.name = FOLIAGE_NODE_NAME
	foliage_mesh.mesh = mesh
	add_child(foliage_mesh)


func _generate_trunk(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	radial: int,
) -> Branch:
	var trunk := TrunkGen.generate_trunk(noise_seed, trunk_params)
	MeshUtils.append_tube(vertices, indices, uvs, trunk.points, trunk.radii, radial)
	return trunk


## Returns the last level of branches (tips).
func _generate_branches(
	trunk: Branch,
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	radial: int,
) -> Array[Branch]:
	var branches: Array[Branch] = []
	var parents: Array[Branch] = [trunk]
	for level in branch_levels:
		if level == null:
			continue
		var children: Array[Branch] = []
		for parent in parents:
			children.append_array(TreeSkeleton.grow_branches(parent, level))
		branches.append_array(children)
		if children.is_empty():
			break
		parents = children

	for branch in branches:
		MeshUtils.append_tube(vertices, indices, uvs, branch.points, branch.radii, radial)

	if branches.is_empty():
		return []
	return parents


func generate_tree() -> void:
	_clear_generated()

	if trunk_params == null:
		push_warning("CosmoTreeGen: missing 'trunk_params'!")
		return

	var trunk_radial: int = TrunkGen.BASE_RADIAL_SEGMENTS * trunk_params.quality
	var branch_radial: int = maxi(3, trunk_radial - 2)

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()

	# Trunk
	var trunk := _generate_trunk(vertices, indices, uvs, trunk_radial)

	# Trunk collision
	if use_collision:
		_add_trunk_collision(vertices)

	# Branches
	var tips: Array[Branch] = [trunk]
	tips.append_array(_generate_branches(trunk, vertices, indices, uvs, branch_radial))

	# Create trunk + branches mesh
	if create_trunk:
		var trunk_mesh := MeshInstance3D.new()
		trunk_mesh.name = TRUNK_NODE_NAME
		trunk_mesh.mesh = MeshUtils.build_mesh(vertices, indices, flat_shading, uvs)
		add_child(trunk_mesh)

	# Foliage
	if foliage_params != null and create_foliage:
		# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
		match foliage_params.type:
			CosmoFoliageParams.Type.NONE: pass  # TODO: maybe close branch caps?
			CosmoFoliageParams.Type.ICOSPHERES: _add_icospheres(tips)
			CosmoFoliageParams.Type.LEAVES: _add_leaves(tips)

	# Materials
	_apply_materials()
