# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name CosmoBranchLevel
extends Resource

@export_range(0, 60) var count: int = 6:
	set(value):
		count = value
		emit_changed()
@export var terminal: bool = false:
	set(value):
		terminal = value
		emit_changed()
@export_range(0.0, 1.0) var start: float = 0.4:
	set(value):
		start = value
		emit_changed()
@export_range(0.0, 1.0) var end: float = 0.9:
	set(value):
		end = value
		emit_changed()
@export_range(0.0, 90.0) var angle: float = 50.0:
	set(value):
		angle = value
		emit_changed()
@export_range(0.05, 1.0) var length: float = 0.4:
	set(value):
		length = value
		emit_changed()
@export var length_curve: Curve:
	set(value):
		if length_curve != null:
			length_curve.changed.disconnect(emit_changed)
		length_curve = value
		if length_curve != null:
			length_curve.changed.connect(emit_changed)
		emit_changed()
@export_range(0.1, 1.0) var radius: float = 0.6:
	set(value):
		radius = value
		emit_changed()
@export_range(1, 8) var segments: int = 3:
	set(value):
		segments = value
		emit_changed()
@export_range(0.0, 2.0) var gnarl: float = 0.3:
	set(value):
		gnarl = value
		emit_changed()
@export_range(-2.0, 2.0) var up_force: float = 0.5:
	set(value):
		up_force = value
		emit_changed()
