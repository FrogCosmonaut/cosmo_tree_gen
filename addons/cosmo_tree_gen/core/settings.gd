# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends RefCounted

const SETTINGS_PATH: String = "cosmo_tree_gen"

const EXPORT_EXTENSION: StringName = &"export/default_extension"
const EXPORT_INCLUDE_COLLISIONS: StringName = &"export/default_include_collisions"
const EXPORT_IMAGES: StringName = &"export/default_export_images"
const EXPORT_USE_EXTERNAL_MATERIAL: StringName = &"export/default_use_external_material"

const SETTINGS: Dictionary = {
	EXPORT_EXTENSION: {
		"value": "glb",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "glb,gltf"
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
