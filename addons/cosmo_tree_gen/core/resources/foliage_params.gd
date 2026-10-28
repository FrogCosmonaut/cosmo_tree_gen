# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name CosmoFoliageParams
extends Resource

enum FoliageType {
	NONE,
	ICOSPHERES,
}

@export var type: FoliageType = FoliageType.ICOSPHERES:
	set(value):
		type = value
		emit_changed()
@export_range(0.1, 5.0, 0.01) var radius: float = 1.0:
	set(value):
		radius = value
		emit_changed()
@export_range(0.0, 1.0) var length_influence: float = 0.4:
	set(value):
		length_influence = value
		emit_changed()
@export_range(0, 4) var subdivisions: int = 1:
	set(value):
		subdivisions = value
		emit_changed()
@export_range(0.0, 0.6) var amplitude: float = 0.4:
	set(value):
		amplitude = value
		emit_changed()
@export_range(0.1, 10.0) var frequency: float = 1.5:
	set(value):
		frequency = value
		emit_changed()
