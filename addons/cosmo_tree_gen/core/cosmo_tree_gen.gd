# Copyright © 2026 CosmonautFrog - MIT License

@tool
@icon("../tree.svg")
class_name CosmoTreeGen
extends Node3D

signal generated

enum CollisionType {
	## Do not generate collision shapes.
	NONE,
	## Generate one convex collision shape per branch, up to [member collision_level].
	## Curved branches get a looser fit.
	SIMPLE_CONVEX,
	## Generate one convex collision shape per branch segment, up to [member collision_level].
	## More precise than Simple Convex, it's solid so pushes out bodies. Uses more memory than Trimesh.
	MULTIPLE_CONVEX,
	## Generate a single trimesh collision shape, using branch levels up to [member collision_level].
	## The cheapest and closest fit, but hollow and one-sided. Fast or overlapping bodies can pass through it.
	## Doesn't work on a [RigidBody3D]. Avoid this if you want falling trees.
	TRIMESH,
}

enum FoliageCollisionType {
	## Do not generate collision shapes for foliage.
	NONE,
	## Generate one convex collision shape around the whole canopy.
	HULL,
	## Generate one SphereShape3D per branch tip.
	SPHERES,
}

const Settings := preload("./settings.gd")
const Branch := preload("./branch.gd")
const TrunkGen := preload("./trunk_gen.gd")
const MeshUtils := preload("./mesh_utils.gd")
const TreeSkeleton := preload("./tree_skeleton.gd")
const IcosphereGen := preload("./icosphere_gen.gd")
const LeafGen := preload("./leaf_gen.gd")
const CollisionGen := preload("./collision_gen.gd")

const COMBINED_NODE_NAME: String = "CosmoTree"
const TRUNK_NODE_NAME: String = "Trunk"
const TRUNK_SURFACE_NAME: String = "Bark"
const FOLIAGE_NODE_NAME: String = "Foliage"
const FOLIAGE_SURFACE_NAME: String = "Foliage"
const COLLISION_NODE_NAME: String = "Collision"
const FOLIAGE_COLLISION_NODE_NAME: String = "FoliageCollision"
const COLLISION_PREVIEW_NODE_NAME: String = "CollisionPreview"
const COLLISION_RADIAL: int = 6
const LOD_SUFFIXES: Array[String] = ["_LOD0", "_LOD1", "_LOD2"]
const LOD_HYSTERESIS: float = 1.0

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
@export var generate_lod: bool = false:
	set(value):
		generate_lod = value
		_regenerate()
@export_range(0.0, 1.0, 0.01) var lod_trunk_share: float = 0.33:
	set(value):
		lod_trunk_share = value
		_regenerate()
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
## Type of collision to generate for the trunk, root and branches.
@export var collision_type: CollisionType = CollisionType.NONE:
	set(value):
		collision_type = value
		_regenerate()
## Maximum level of branches to create collisions for. [br][br]
## Level 0 generates collisions just for the trunk/s and
## level 1 for trunks, roots and first level of branches.
@export_range(0, 6, 1, "or_greater") var collision_level: int = 0:
	set(value):
		collision_level = value
		_regenerate()
## Cuts the trunk, root and branch collisions at this height, in local space. [br][br]
## Branches starting above it get no collision. 0 means no limit.
@export_range(0.0, 25.0, 0.1, "or_greater", "suffix:m") var collision_max_height: float = 0.0:
	set(value):
		collision_max_height = value
		_regenerate()
## Type of collision to generate for the foliage.
@export var foliage_collision_type: FoliageCollisionType = FoliageCollisionType.NONE:
	set(value):
		foliage_collision_type = value
		_regenerate()
## Draws the collision shapes on top of the tree. Editor only, never exported.
@export var preview_collision: bool = false:
	set(value):
		preview_collision = value
		if is_node_ready():
			_update_collision_preview()
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
	var found: bool = false
	for node_name: String in _get_generated_node_names():
		var mi := get_node_or_null(node_name) as MeshInstance3D
		if mi == null:
			continue
		var mesh := mi.mesh as ArrayMesh
		if mesh == null:
			continue
		var idx := mesh.surface_find_by_name(surface_name)
		if idx != -1:
			mesh.surface_set_material(idx, material)
			found = true

	return found


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


func _get_generated_node_names() -> Array[String]:
	var out: Array[String] = [COLLISION_NODE_NAME, FOLIAGE_COLLISION_NODE_NAME, COLLISION_PREVIEW_NODE_NAME]

	for node_name: String in [COMBINED_NODE_NAME, TRUNK_NODE_NAME, FOLIAGE_NODE_NAME]:
		out.append(node_name)
		for suffix in LOD_SUFFIXES:
			out.append(node_name + suffix)

	return out


func _clear_generated() -> void:
	for node_name: String in _get_generated_node_names():
		var node := get_node_or_null(node_name)
		if node:
			remove_child(node)
			node.free()


## `positions` is optional, one per shape.
func _add_collision(
	shapes: Array[Shape3D],
	node_name: String,
	positions: PackedVector3Array = PackedVector3Array(),
) -> void:
	if shapes.is_empty():
		return

	var static_body := StaticBody3D.new()
	static_body.name = node_name
	static_body.collision_layer = collision_layer
	static_body.collision_mask = collision_mask

	for i in shapes.size():
		var col_shape := CollisionShape3D.new()
		col_shape.name = "CollisionShape%d" % i
		col_shape.shape = shapes[i]
		if not positions.is_empty():
			col_shape.position = positions[i]
		static_body.add_child(col_shape)

	add_child(static_body)


func _update_collision_preview() -> void:
	var old := get_node_or_null(COLLISION_PREVIEW_NODE_NAME)
	if old:
		remove_child(old)
		old.free()

	var cols := get_collisions()
	if not Engine.is_editor_hint() or not preview_collision or cols.is_empty():
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	for col in cols:
		for col_shape: CollisionShape3D in col.get_children():
			# surface 0 is the wireframe, 1 the fill, so draw only surface 0
			st.append_from(col_shape.shape.get_debug_mesh(), 0, col_shape.transform)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	material.albedo_color = ProjectSettings.get_setting("debug/shapes/collision/shape_color")

	var mi := MeshInstance3D.new()
	mi.name = COLLISION_PREVIEW_NODE_NAME
	mi.mesh = st.commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Fills `sphere_centers` and `sphere_radii` with one sphere per icosphere.
func _create_icospheres_mesh(
	branches: Array[Branch],
	sphere_centers: PackedVector3Array,
	sphere_radii: PackedFloat32Array,
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var trunk := branches[0]
	for branch in branches:
		if branch.is_broken:
			continue

		var length_ratio := branch.get_length() / trunk.get_length()
		var length_influence := lerpf(1.0, length_ratio, foliage_params.icosphere_length_influence)
		var radius := foliage_params.icosphere_radius * length_influence
		IcosphereGen.append_icosphere(
			vertices,
			indices,
			branch.tip(),
			branch.branch_seed,
			radius,
			foliage_params.icosphere_subdivisions,
			foliage_params.icosphere_amplitude,
			foliage_params.icosphere_frequency,
		)
		# the noise displaces it +-amplitude, so the base radius is the average fit
		sphere_centers.append(branch.tip())
		sphere_radii.append(radius)

	return MeshUtils.build_mesh(vertices, indices, false)


## Fills `sphere_centers` and `sphere_radii` with one sphere per tip leaf cluster.
func _create_leaves_mesh(
	tips: Array[Branch],
	trunk_count: int,
	sphere_centers: PackedVector3Array,
	sphere_radii: PackedFloat32Array,
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()

	# tips starts with the trunks, they only get leaves when there are no branches
	var first := trunk_count if tips.size() > trunk_count else 0
	var longest := 0.0
	for i in range(first, tips.size()):
		longest = maxf(longest, tips[i].get_length())
	for i in range(first, tips.size()):
		var length_ratio := tips[i].get_length() / longest
		var length_influence := lerpf(1.0, length_ratio, foliage_params.leaf_length_influence)
		var tip_first := vertices.size()
		LeafGen.append_leaves(vertices, indices, uvs, tips[i], foliage_params, length_influence)

		# broken tips get no leaves
		if vertices.size() == tip_first:
			continue
		var bounds := AABB(vertices[tip_first], Vector3.ZERO)
		for k in range(tip_first, vertices.size()):
			bounds = bounds.expand(vertices[k])
		sphere_centers.append(bounds.get_center())
		# average of the half extents, the corners of the box are mostly empty
		sphere_radii.append((bounds.size.x + bounds.size.y + bounds.size.z) / 6.0)

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


func _create_lod(trunk_mesh: ArrayMesh, foliage_mesh: ArrayMesh, ratio: float) -> Array[ArrayMesh]:
	var trunk_tris := MeshUtils.count_triangles(trunk_mesh)
	var foliage_tris := MeshUtils.count_triangles(foliage_mesh)
	var budget := (trunk_tris + foliage_tris) * ratio

	var trunk: ArrayMesh
	if trunk_mesh != null:
		trunk = MeshUtils.simplify(trunk_mesh, maxf(budget * lod_trunk_share, budget - foliage_tris))

	var foliage: ArrayMesh
	if foliage_mesh != null:
		var remaining := budget - MeshUtils.count_triangles(trunk)
		if foliage_params.type == CosmoFoliageParams.Type.LEAVES:
			foliage = MeshUtils.generate_leaves_lod(foliage_params, foliage_mesh, remaining / foliage_tris)
		else:
			foliage = MeshUtils.simplify(foliage_mesh, remaining)

	return [trunk, foliage]


func _setup_lod_ranges() -> void:
	var lod1: float = Settings.get_setting(Settings.LOD1_DISTANCE, 50.0)
	var lod2: float = Settings.get_setting(Settings.LOD2_DISTANCE, 100.0)
	var end: float = Settings.get_setting(Settings.LOD_END_DISTANCE, 0.0)
	var distances: Array[float] = [0.0, lod1, lod2, end]

	# Godot measures the ranges from the center of the AABB. Sharing it makes all
	# the meshes of a tree swap LOD at once, with no gaps between them.
	var bounds := AABB()
	for mi in get_meshes():
		bounds = bounds.merge(mi.mesh.get_aabb())

	for lod in LOD_SUFFIXES.size():
		for mi in get_meshes(lod):
			mi.visibility_range_begin = distances[lod]
			mi.visibility_range_begin_margin = LOD_HYSTERESIS
			mi.visibility_range_end = distances[lod + 1]
			mi.visibility_range_end_margin = LOD_HYSTERESIS
			mi.custom_aabb = bounds


## Meshes a branch and its terminal branches as one seamless tube.
func _append_branch_tube(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	branch: Branch,
	radial: int,
) -> void:
	var ringed: Branch = branch.with_base_rings()
	var points: PackedVector3Array = ringed.points
	var radii: PackedFloat32Array = ringed.radii

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
## Fills `roots` with the trunk roots, they are not part of the returned branches.
func _generate_branches(
	trunks: Array[Branch],
	roots: Array[Branch],
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	trunk_radial: int,
	branch_radial: int,
) -> Array[Branch]:
	var branches: Array[Branch] = []
	var parents: Array[Branch] = trunks
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
	for trunk in trunks:
		var trunk_first := vertices.size()
		_append_branch_tube(vertices, indices, uvs, trunk, trunk_radial)
		TrunkGen.flare_base(vertices, trunk_first, trunk, trunk_params)
	for branch in branches:
		if not branch.is_terminal:
			_append_branch_tube(vertices, indices, uvs, branch, branch_radial)

	# roots are not added to `branches`, so they get no foliage
	if trunk_params.roots != null:
		for trunk in trunks:
			for root in TreeSkeleton.grow_branches(trunk, trunk_params.roots):
				roots.append(root)
				_append_branch_tube(vertices, indices, uvs, root, branch_radial)

	return branches


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
	lod_trunk_share = p.lod_trunk_share
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
	preset.lod_trunk_share = lod_trunk_share
	preset.trunk_material = trunk_material
	preset.foliage_material = foliage_material
	return preset


## Returns the meshes of a LOD, or all the LODs if is negative.
func get_meshes(lod: int = -1) -> Array[MeshInstance3D]:
	var suffixes: Array[String] = []
	if lod <= 0:
		suffixes.append("")
	for i in LOD_SUFFIXES.size():
		if lod < 0 or lod == i:
			suffixes.append(LOD_SUFFIXES[i])

	var meshes: Array[MeshInstance3D]
	for suffix in suffixes:
		for node_name: String in [COMBINED_NODE_NAME, TRUNK_NODE_NAME, FOLIAGE_NODE_NAME]:
			var node := get_node_or_null(node_name + suffix) as MeshInstance3D
			if node != null:
				meshes.append(node)

	return meshes


func get_collisions() -> Array[StaticBody3D]:
	var out: Array[StaticBody3D]

	var col_node := get_node_or_null(COLLISION_NODE_NAME)
	if col_node != null:
		out.append(col_node)

	var foliage_col_node := get_node_or_null(FOLIAGE_COLLISION_NODE_NAME)
	if foliage_col_node != null:
		out.append(foliage_col_node)

	return out


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

	# Trunks
	var trunks: Array[Branch] = TrunkGen.generate_trunk(noise_seed, trunk_params)

	# Branches
	var roots: Array[Branch] = []
	var branches: Array[Branch] = _generate_branches(
		trunks, roots, vertices, indices, uvs, trunk_radial, branch_radial
	)

	# Trunk collisions
	if collision_type != CollisionType.NONE:
		var collision_branches: Array[Branch] = trunks.duplicate()
		collision_branches.append_array(branches)
		collision_branches.append_array(roots)
		var max_height := collision_max_height if collision_max_height > 0.0 else INF
		var shapes := CollisionGen.create_shapes(
			collision_type, collision_branches, collision_level, max_height, COLLISION_RADIAL,
			trunk_params,
		)
		_add_collision(shapes, COLLISION_NODE_NAME)

	var tips: Array[Branch] = trunks.duplicate()
	if not branches.is_empty():
		var last_level: int = branches.back().level
		tips.append_array(branches.filter(
			func(b: Branch) -> bool:
				return b.level == last_level
		))

	var trunk_mesh: ArrayMesh
	if create_trunk:
		trunk_mesh = MeshUtils.build_mesh(vertices, indices, false, uvs)
		trunk_mesh.surface_set_name(0, TRUNK_SURFACE_NAME)

	# Foliage
	var foliage_mesh: ArrayMesh
	var sphere_centers := PackedVector3Array()
	var sphere_radii := PackedFloat32Array()
	if foliage_params != null and create_foliage:
		# TODO: add different types of foliage, E.G.: dead trees, pines, etc...
		match foliage_params.type:
			CosmoFoliageParams.Type.NONE: pass
			CosmoFoliageParams.Type.ICOSPHERES:
				foliage_mesh = _create_icospheres_mesh(tips, sphere_centers, sphere_radii)
			CosmoFoliageParams.Type.LEAVES:
				foliage_mesh = _create_leaves_mesh(tips, trunks.size(), sphere_centers, sphere_radii)

		if foliage_mesh != null:
			foliage_mesh.surface_set_name(0, FOLIAGE_SURFACE_NAME)

	# Foliage collisions
	if foliage_collision_type != FoliageCollisionType.NONE and foliage_mesh != null:
		var col_shapes := CollisionGen.create_foliage_shapes(
			foliage_collision_type, foliage_mesh, sphere_radii
		)
		var positions := PackedVector3Array()
		if foliage_collision_type == FoliageCollisionType.SPHERES:
			positions = sphere_centers
		_add_collision(col_shapes, FOLIAGE_COLLISION_NODE_NAME, positions)

	# LODs
	var levels: Array[Array] = [[trunk_mesh, foliage_mesh]]
	if generate_lod:
		var lod1_ratio: float = Settings.get_setting(Settings.LOD1_RATIO, 0.4)
		var lod2_ratio: float = Settings.get_setting(Settings.LOD2_RATIO, 0.15)
		levels.append(_create_lod(trunk_mesh, foliage_mesh, lod1_ratio))
		levels.append(_create_lod(trunk_mesh, foliage_mesh, lod2_ratio))

	if flat_shading:
		for level: Array in levels:
			if level[0] != null:
				level[0] = MeshUtils.flatten_mesh(level[0])
			if level[1] != null and foliage_params.type == CosmoFoliageParams.Type.ICOSPHERES:
				level[1] = MeshUtils.flatten_mesh(level[1])

	# Create MeshInstance3Ds
	for lod in levels.size():
		var suffix: String = LOD_SUFFIXES[lod] if generate_lod else ""
		var nodes := {TRUNK_NODE_NAME: levels[lod][0], FOLIAGE_NODE_NAME: levels[lod][1]}
		if combine_trunk_and_foliage:
			var parts: Array[ArrayMesh] = [levels[lod][0], levels[lod][1]]
			parts = parts.filter(func(x) -> bool: return x != null)
			nodes = {COMBINED_NODE_NAME: MeshUtils.combine_meshes(parts) if not parts.is_empty() else null}

		for node_name: String in nodes:
			if nodes[node_name] != null:
				_add_mesh_instance(node_name + suffix, nodes[node_name])

	if generate_lod:
		_setup_lod_ranges()

	# Materials
	_apply_materials()

	_update_collision_preview()
	generated.emit()
