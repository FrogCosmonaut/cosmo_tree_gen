# Copyright © 2026 CosmonautFrog - MIT License

@tool
@icon("../tree.svg")
class_name CosmoTreeGen
extends Node3D

signal generated

const Branch := preload("./branch.gd")
const TrunkGen := preload("./trunk_gen.gd")
const MeshUtils := preload("./mesh_utils.gd")
const TreeSkeleton := preload("./tree_skeleton.gd")
const IcosphereGen := preload("./icosphere_gen.gd")
const LeafGen := preload("./leaf_gen.gd")

const COMBINED_NODE_NAME: String = "CosmoTree"
const TRUNK_NODE_NAME: String = "Trunk"
const TRUNK_SURFACE_NAME: String = "Bark"
const FOLIAGE_NODE_NAME: String = "Foliage"
const FOLIAGE_SURFACE_NAME: String = "Foliage"
const COLLISION_NODE_NAME: String = "Collision"

@export_tool_button("Generate tree", "Reload")
var gen: Callable = generate_tree
@export var auto_generate: bool = true:
	set(value):
		auto_generate = value
		if auto_generate:
			_regenerate()

@export var noise_seed: int = 42:
	set(value):
		noise_seed = value
		_regenerate()

@export_category("Tree Parameters")
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
@export var combine_trunk_and_foliage: bool = true:
	set(value):
		combine_trunk_and_foliage = value
		_regenerate()
@export var flat_shading: bool = false:
	set(value):
		flat_shading = value
		_regenerate()
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

var _applying_preset: bool = false


func _init() -> void:
	name = "CosmoTreeGen"


func _ready() -> void:
	_swap_watch(null, trunk_params)
	_swap_watch(null, foliage_params)
	generate_tree()


func _set_trunk_material(value: Material) -> void:
	trunk_material = value
	_set_surface_material(TRUNK_SURFACE_NAME, trunk_material)


func _set_foliage_material(value: Material) -> void:
	foliage_material = value

	if not _set_surface_material(FOLIAGE_SURFACE_NAME, foliage_material):
		return

	if foliage_params.type == CosmoFoliageParams.Type.ICOSPHERES and foliage_material is StandardMaterial3D:
		if not (foliage_material as StandardMaterial3D).uv1_triplanar:
			push_warning("CosmoTreeGen: foliage_material should use UV1 triplanar!")


func _set_surface_material(surface_name: String, material: Material) -> bool:
	for node_name: String in [COMBINED_NODE_NAME, TRUNK_NODE_NAME, FOLIAGE_NODE_NAME]:
		var mi := get_node_or_null(node_name) as MeshInstance3D
		if mi == null:
			continue
		var mesh := mi.mesh as ArrayMesh
		if mesh == null:
			continue
		var idx := mesh.surface_find_by_name(surface_name)
		if idx != -1:
			mesh.surface_set_material(idx, material)
			return true
	return false


func _apply_materials() -> void:
	_set_trunk_material(trunk_material)
	_set_foliage_material(foliage_material)


func _swap_watch(old: Resource, new: Resource) -> void:
	if old and old.changed.is_connected(_regenerate):
		old.changed.disconnect(_regenerate)
	if new and not new.changed.is_connected(_regenerate):
		new.changed.connect(_regenerate)


func _regenerate() -> void:
	if is_node_ready() and auto_generate and not _applying_preset:
		generate_tree()


func _clear_generated() -> void:
	for node_name: String in [COMBINED_NODE_NAME, TRUNK_NODE_NAME, FOLIAGE_NODE_NAME, COLLISION_NODE_NAME]:
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


func _create_icospheres_mesh(branches: Array[Branch]) -> ArrayMesh:
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
	return MeshUtils.build_mesh(vertices, indices, flat_shading)


func _create_leaves_mesh(tips: Array[Branch]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	# tips[0] is the trunk, only gets leaves when there are no branches
	var first := 1 if tips.size() > 1 else 0
	var longest := 0.0
	for i in range(first, tips.size()):
		longest = maxf(longest, tips[i].get_length())
	for i in range(first, tips.size()):
		var length_ratio := tips[i].get_length() / longest
		var length_influence := lerpf(1.0, length_ratio, foliage_params.leaf_length_influence)
		LeafGen.append_leaves(vertices, indices, uvs, tips[i], foliage_params, length_influence)

	if vertices.is_empty():
		return null

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
	return mesh


func _add_mesh_instance(node_name: String, mesh: ArrayMesh) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	add_child(mi)


## Meshes a branch and its terminal branches as one seamless tube.
func _append_branch_tube(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	branch: Branch,
	radial: int,
) -> void:
	var points := branch.points.duplicate()
	var radii := branch.radii.duplicate()

	# bunched towards the ground, where the flare changes the most
	for k in branch.base_rings:
		var s := pow(float(k + 1) / (branch.base_rings + 1), 2.0)
		points.insert(k + 1, branch.points[0].lerp(branch.points[1], s))
		radii.insert(k + 1, lerpf(branch.radii[0], branch.radii[1], s))

	if branch.sink_depth > 0.0:
		points.insert(0, branch.points[0] + Vector3.DOWN * branch.sink_depth)
		radii.insert(0, branch.radii[0])

	var terminal := branch.terminal
	while terminal != null:
		# Its first point is the tip it grows from
		points.append_array(terminal.points.slice(1))
		radii.append_array(terminal.radii.slice(1))
		terminal = terminal.terminal
	MeshUtils.append_tube(vertices, indices, uvs, points, radii, radial, true)


## Grows all the branch levels, then meshes them along with the trunk.
## Returns the last level of branches (tips).
func _generate_branches(
	trunk: Branch,
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	trunk_radial: int,
	branch_radial: int,
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

	# terminal branches are meshed inside the tube of the branch they continue
	var trunk_first := vertices.size()
	_append_branch_tube(vertices, indices, uvs, trunk, trunk_radial)
	TrunkGen.flare_base(vertices, trunk_first, noise_seed, trunk_params)
	for branch in branches:
		if not branch.is_terminal:
			_append_branch_tube(vertices, indices, uvs, branch, branch_radial)

	# roots are not added to `branches`, so they get no foliage
	if trunk_params.roots != null:
		for root in TreeSkeleton.grow_branches(trunk, trunk_params.roots):
			_append_branch_tube(vertices, indices, uvs, root, branch_radial)

	if branches.is_empty():
		return []
	return parents


func apply_preset(preset: CosmoTreePreset) -> void:
	# deep copy, so editing the tree doesn't edit the preset file
	var p := preset.duplicate(true) as CosmoTreePreset

	_applying_preset = true
	trunk_params = p.trunk_params
	branch_levels = p.branch_levels
	foliage_params = p.foliage_params
	combine_trunk_and_foliage = p.combine_trunk_and_foliage
	flat_shading = p.flat_shading
	create_trunk = p.create_trunk
	create_foliage = p.create_foliage
	trunk_material = p.trunk_material
	foliage_material = p.foliage_material
	_applying_preset = false
	_regenerate()


func to_preset() -> CosmoTreePreset:
	var preset := CosmoTreePreset.new()
	preset.trunk_params = trunk_params
	preset.branch_levels = branch_levels
	preset.foliage_params = foliage_params
	preset.combine_trunk_and_foliage = combine_trunk_and_foliage
	preset.flat_shading = flat_shading
	preset.create_trunk = create_trunk
	preset.create_foliage = create_foliage
	preset.trunk_material = trunk_material
	preset.foliage_material = foliage_material
	return preset


func get_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D]
	for node_name: String in [COMBINED_NODE_NAME, TRUNK_NODE_NAME, FOLIAGE_NODE_NAME]:
		var node := get_node_or_null(node_name) as MeshInstance3D
		if node != null:
			meshes.append(node)
	return meshes


func set_random_seed() -> void:
	noise_seed = randi_range(-2147483648, 2147483647)


func generate_tree() -> void:
	_clear_generated()

	if trunk_params == null:
		push_warning("CosmoTreeGen: missing 'trunk_params'!")
		generated.emit()
		return

	var trunk_radial: int = TrunkGen.BASE_RADIAL_SEGMENTS * trunk_params.quality
	var branch_radial: int = maxi(3, trunk_radial - 2)

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()

	# Trunk
	var trunk := TrunkGen.generate_trunk(noise_seed, trunk_params)

	# Trunk collision, without the terminal branches
	if use_collision:
		var trunk_vertices := PackedVector3Array()
		MeshUtils.append_tube(
			trunk_vertices,
			PackedInt32Array(),
			PackedVector2Array(),
			trunk.points,
			trunk.radii,
			trunk_radial,
		)
		_add_trunk_collision(trunk_vertices)

	# Branches
	var tips: Array[Branch] = [trunk]
	tips.append_array(_generate_branches(trunk, vertices, indices, uvs, trunk_radial, branch_radial))

	var trunk_mesh: ArrayMesh
	if create_trunk:
		trunk_mesh = MeshUtils.build_mesh(vertices, indices, flat_shading, uvs)
		trunk_mesh.surface_set_name(0, TRUNK_SURFACE_NAME)

	# Foliage
	var foliage_mesh: ArrayMesh
	if foliage_params != null and create_foliage:
		# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
		match foliage_params.type:
			CosmoFoliageParams.Type.NONE: pass
			CosmoFoliageParams.Type.ICOSPHERES: foliage_mesh = _create_icospheres_mesh(tips)
			CosmoFoliageParams.Type.LEAVES: foliage_mesh = _create_leaves_mesh(tips)

		if foliage_mesh != null:
			foliage_mesh.surface_set_name(0, FOLIAGE_SURFACE_NAME)

	# Create MeshInstance3Ds
	if combine_trunk_and_foliage:
		var parts: Array[ArrayMesh] = [trunk_mesh, foliage_mesh]
		parts = parts.filter(func(x) -> bool: return x != null)
		if not parts.is_empty():
			var combined_mesh: ArrayMesh = MeshUtils.combine_meshes(parts)
			_add_mesh_instance(COMBINED_NODE_NAME, combined_mesh)
	else:
		if trunk_mesh != null:
			_add_mesh_instance(TRUNK_NODE_NAME, trunk_mesh)
		if foliage_mesh != null:
			_add_mesh_instance(FOLIAGE_NODE_NAME, foliage_mesh)

	# Materials
	_apply_materials()
	generated.emit()
