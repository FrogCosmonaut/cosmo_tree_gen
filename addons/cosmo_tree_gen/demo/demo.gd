# Copyright © 2026 CosmonautFrog - GNU GPL v3 License

@tool
extends MeshInstance3D

@export_tool_button("Generate Icosphere") var gen_icosphere = _generate_icosphere
@export_range(0, 3) var subdivisions: int = 1:
	set(value):
		subdivisions = value
		_generate_icosphere()
@export var seed: int = 42:
	set(value):
		seed = value
		_generate_icosphere()
@export_range(0.0, 0.6) var amplitude: float = 0.4:
	set(value):
		amplitude = value
		_generate_icosphere()
@export_range(0.1, 10.0) var frequency: float = 1.5:
	set(value):
		frequency = value
		_generate_icosphere()
@export var flat_shading: bool = true:
	set(value):
		flat_shading = value
		_generate_icosphere()


func _generate_icosphere() -> void:
	mesh = IcosphereGen.generate_icosphere(subdivisions, seed, amplitude, frequency, flat_shading)
