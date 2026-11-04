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

const TreeBuilder := preload("./tree_builder.gd")
const Settings := preload("./settings.gd")

const COMBINED_NODE_NAME: String = "CosmoTree"
const TRUNK_NODE_NAME: String = "Trunk"
const FOLIAGE_NODE_NAME: String = "Foliage"
const PART_NODE_NAMES: Dictionary[TreeBuilder.Part, String] = {
	TreeBuilder.Part.COMBINED: COMBINED_NODE_NAME,
	TreeBuilder.Part.TRUNK: TRUNK_NODE_NAME,
	TreeBuilder.Part.FOLIAGE: FOLIAGE_NODE_NAME,
}
const COLLISION_NODE_NAME: String = "Collision"
const FOLIAGE_COLLISION_NODE_NAME: String = "FoliageCollision"
const COLLISION_PREVIEW_NODE_NAME: String = "CollisionPreview"
const LOD_SUFFIXES: Array[String] = ["_LOD0", "_LOD1", "_LOD2"]
const LOD_HYSTERESIS: float = 1.0

@export_tool_button("Generate tree", "Reload")
var generate_button: Callable = generate
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
		for body in get_collisions():
			body.collision_layer = collision_layer
@export_flags_3d_physics var collision_mask: int = 1:
	set(value):
		collision_mask = value
		for body in get_collisions():
			body.collision_mask = collision_mask

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
	generate()


func _set_trunk_material(value: Material) -> void:
	trunk_material = value
	_set_surface_material(TreeBuilder.TRUNK_SURFACE_NAME, trunk_material)


func _set_foliage_material(value: Material) -> void:
	foliage_material = value

	if not _set_surface_material(TreeBuilder.FOLIAGE_SURFACE_NAME, foliage_material):
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
		generate()


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


func _add_collision(node_name: String, collision: TreeBuilder.Collision) -> void:
	if collision.shapes.is_empty():
		return

	var static_body := StaticBody3D.new()
	static_body.name = node_name
	static_body.collision_layer = collision_layer
	static_body.collision_mask = collision_mask

	for i in collision.shapes.size():
		var col_shape := CollisionShape3D.new()
		col_shape.name = "CollisionShape%d" % i
		col_shape.shape = collision.shapes[i]
		col_shape.transform = collision.transforms[i]
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


func _add_mesh_instance(node_name: String, mesh: ArrayMesh) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	add_child(mi)


## Godot measures the ranges from the center of the AABB. Sharing `bounds` makes all
## the meshes of a tree swap LOD at once, with no gaps between them.
func _setup_lod_ranges(bounds: AABB) -> void:
	var lod1: float = Settings.get_setting(Settings.LOD1_DISTANCE, 50.0)
	var lod2: float = Settings.get_setting(Settings.LOD2_DISTANCE, 100.0)
	var end: float = Settings.get_setting(Settings.LOD_END_DISTANCE, 0.0)
	var distances: Array[float] = [0.0, lod1, lod2, end]

	for lod in LOD_SUFFIXES.size():
		for mi in get_meshes(lod):
			mi.visibility_range_begin = distances[lod]
			mi.visibility_range_begin_margin = LOD_HYSTERESIS
			mi.visibility_range_end = distances[lod + 1]
			mi.visibility_range_end_margin = LOD_HYSTERESIS
			mi.custom_aabb = bounds


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


func generate() -> void:
	_clear_generated()
	var result := TreeBuilder.build(self)

	var has_lods := result.lods.size() > 1
	for lod in result.lods.size():
		var suffix: String = LOD_SUFFIXES[lod] if has_lods else ""
		var meshes := result.lods[lod].meshes
		for part: TreeBuilder.Part in meshes:
			_add_mesh_instance(PART_NODE_NAMES[part] + suffix, meshes[part])

	if has_lods:
		_setup_lod_ranges(result.bounds)

	_add_collision(COLLISION_NODE_NAME, result.collision)
	_add_collision(FOLIAGE_COLLISION_NODE_NAME, result.foliage_collision)

	_apply_materials()
	_update_collision_preview()

	generated.emit()
