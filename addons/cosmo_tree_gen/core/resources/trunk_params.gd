# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name CosmoTrunkParams
extends Resource

@export_range(1, 6) var quality: int = 1:
	set(value):
		quality = value
		emit_changed()
@export_range(0.0, 25.0, 0.1) var height: float = 5.0:
	set(value):
		height = value
		emit_changed()
@export_range(0.0, 5.0, 0.01) var radius_bottom: float = 0.35:
	set(value):
		radius_bottom = value
		emit_changed()
@export_range(0.0, 2.5, 0.01) var radius_top: float = 0.1:
	set(value):
		radius_top = value
		emit_changed()
@export_range(0.0, 2.0) var lean: float = 0.6:
	set(value):
		lean = value
		emit_changed()
@export_range(0.0, 1.0) var wobble: float = 0.15:
	set(value):
		wobble = value
		emit_changed()


func get_lean_vec(angle: float) -> Vector3:
	return Vector3(cos(angle), 0.0, sin(angle)) * lean
