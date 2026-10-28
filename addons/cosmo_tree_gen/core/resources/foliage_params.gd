# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name CosmoFoliageParams
extends Resource

enum FoliageType {
	NONE,
	ICOSPHERES,
	LEAVES,
}

@export var type: FoliageType = FoliageType.ICOSPHERES:
	set(value):
		type = value
		notify_property_list_changed()
		emit_changed()

# ICOSPHERES
@export_range(0.0, 1.0) var icosphere_length_influence: float = 0.4:
	set(value):
		icosphere_length_influence = value
		emit_changed()
@export_range(0.1, 5.0, 0.01) var icosphere_radius: float = 1.0:
	set(value):
		icosphere_radius = value
		emit_changed()
@export_range(0, 4) var icosphere_subdivisions: int = 1:
	set(value):
		icosphere_subdivisions = value
		emit_changed()
@export_range(0.0, 0.6) var icosphere_amplitude: float = 0.4:
	set(value):
		icosphere_amplitude = value
		emit_changed()
@export_range(0.1, 10.0) var icosphere_frequency: float = 1.5:
	set(value):
		icosphere_frequency = value
		emit_changed()

# LEAVES
@export_range(1, 50) var leaf_count: int = 12:
	set(value):
		leaf_count = value
		emit_changed()
@export_range(0.05, 3.0, 0.01) var leaf_size: float = 0.6:
	set(value):
		leaf_size = value
		emit_changed()
@export_range(0.0, 0.9) var leaf_size_variance: float = 0.3:
	set(value):
		leaf_size_variance = value
		emit_changed()
@export_range(0.0, 1.0) var leaf_start: float = 0.3:
	set(value):
		leaf_start = value
		emit_changed()
@export_range(0.0, 90.0) var leaf_angle: float = 40.0:
	set(value):
		leaf_angle = value
		emit_changed()
@export var leaf_double: bool = true:
	set(value):
		leaf_double = value
		emit_changed()
@export_range(0.0, 1.0) var leaf_canopy_normals: float = 0.8:
	set(value):
		leaf_canopy_normals = value
		emit_changed()
@export_range(0.0, 1.0) var leaf_inner_ao: float = 0.35:
	set(value):
		leaf_inner_ao = value
		emit_changed()


func _validate_property(property: Dictionary) -> void:
	var prop_name := String(property.name)
	var is_leaf := prop_name.begins_with("leaf_")
	var is_icosphere := prop_name.begins_with("icosphere_")
	if (
		(is_leaf and type != FoliageType.LEAVES)
		or (is_icosphere and type != FoliageType.ICOSPHERES)
	):
		property.usage = PROPERTY_USAGE_NO_EDITOR
