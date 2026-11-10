# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends RefCounted

const SETTINGS_PATH: String = "cosmo_tree_gen"

# generator
const LOD1_RATIO: StringName = &"generator/lod1_ratio"
const LOD2_RATIO: StringName = &"generator/lod2_ratio"
const LOD1_DISTANCE: StringName = &"generator/lod1_distance"
const LOD2_DISTANCE: StringName = &"generator/lod2_distance"
const IMPOSTOR_DISTANCE: StringName = &"generator/impostor_distance"
const LOD_END_DISTANCE: StringName = &"generator/lod_end_distance"

# export
const EXPORT_EXTENSION: StringName = &"export/default_extension"
const EXPORT_INCLUDE_COLLISIONS: StringName = &"export/default_include_collisions"
const EXPORT_IMAGES: StringName = &"export/default_export_images"
const EXPORT_USE_EXTERNAL_MATERIAL: StringName = &"export/default_use_external_material"

# impostor
const IMPOSTOR_RESOLUTION: StringName = &"impostor/resolution"
const IMPOSTOR_AO_STRENGTH: StringName = &"impostor/ao_strength"
const IMPOSTOR_CAST_SHADOW: StringName = &"impostor/cast_shadow"

const SETTINGS: Dictionary = {
	LOD1_RATIO: {
		"value": 0.4,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
	},
	LOD2_RATIO: {
		"value": 0.15,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
	},
	LOD1_DISTANCE: {
		"value": 50.0,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1000.0,0.1,or_greater,suffix:m",
	},
	LOD2_DISTANCE: {
		"value": 100.0,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1000.0,0.1,or_greater,suffix:m",
	},
	IMPOSTOR_DISTANCE: {
		"value": 150.0,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1000.0,0.1,or_greater,suffix:m",
	},
	# 0 keeps the last LOD visible at any distance
	LOD_END_DISTANCE: {
		"value": 0.0,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1000.0,0.1,or_greater,suffix:m",
	},
	EXPORT_EXTENSION: {
		"value": "glb",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "glb,gltf",
	},
	EXPORT_INCLUDE_COLLISIONS: {
		"value": true,
		"type": TYPE_BOOL,
	},
	EXPORT_IMAGES: {
		"value": false,
		"type": TYPE_BOOL,
	},
	EXPORT_USE_EXTERNAL_MATERIAL: {
		"value": true,
		"type": TYPE_BOOL,
	},
	IMPOSTOR_RESOLUTION: {
		"value": 512,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "64,2048,64,or_greater,suffix:px",
	},
	IMPOSTOR_AO_STRENGTH: {
		"value": 0.5,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
	},
	IMPOSTOR_CAST_SHADOW: {
		"value": false,
		"type": TYPE_BOOL,
	},
}


static func setup_settings() -> void:
	for key: String in SETTINGS:
		var setting_config: Dictionary = SETTINGS[key]
		var setting_name: String = "%s/%s" % [SETTINGS_PATH, key]
		var setting_default: Variant = setting_config.get("value")
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, setting_default)
		ProjectSettings.set_initial_value(setting_name, setting_default)
		ProjectSettings.set_as_basic(setting_name, true)
		ProjectSettings.add_property_info({
			"name": setting_name,
			"type": setting_config.get("type"),
			"hint": setting_config.get("hint", PROPERTY_HINT_NONE),
			"hint_string": setting_config.get("hint_string", "")
		})


static func get_setting(key: String, default: Variant) -> Variant:
	if ProjectSettings.has_setting("%s/%s" % [SETTINGS_PATH, key]):
		return ProjectSettings.get_setting("%s/%s" % [SETTINGS_PATH, key])
	else:
		return default
