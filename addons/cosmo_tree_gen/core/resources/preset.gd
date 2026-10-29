# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name CosmoTreePreset
extends Resource

@export var trunk_params: CosmoTrunkParams
@export var branch_levels: Array[CosmoBranchLevel]
@export var foliage_params: CosmoFoliageParams

@export var trunk_material: Material
@export var foliage_material: Material

@export var flat_shading: bool = false
@export var create_trunk: bool = true
@export var create_foliage: bool = true


func is_valid() -> bool:
	return trunk_params != null


func get_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if trunk_params == null:
		errors.append("missing trunk_params")
	return errors
