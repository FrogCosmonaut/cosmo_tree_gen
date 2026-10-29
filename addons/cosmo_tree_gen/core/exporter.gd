# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends RefCounted


static func _write_import_materials(path: String, state: GLTFState) -> Error:
	var import := ConfigFile.new()
	import.load(path + ".import")
	import.set_value("remap", "importer", "scene")

	var subresources: Dictionary = import.get_value("params", "_subresources", {})
	var materials: Dictionary = subresources.get("materials", {})

	var json_materials: Array = state.json.get("materials", [])
	var state_materials := state.get_materials()
	for i in json_materials.size():
		var material_path := state_materials[i].resource_path
		# creating a new Resource will create a resource_path like "...::xxxxx"
		# this is a bit hacky, couldn't find another way
		if material_path.is_empty() or material_path.contains("::"):
			continue
		materials[json_materials[i]["name"]] = {
			"use_external/enabled": true,
			"use_external/path": ResourceUID.path_to_uid(material_path),
			"use_external/fallback_path": material_path,
		}

	subresources["materials"] = materials
	import.set_value("params", "_subresources", subresources)
	return import.save(path + ".import")


## experimental
static func export_gltf_instances(path: String, meshes: Array[MeshInstance3D]) -> Error:
	if meshes.is_empty():
		return ERR_UNCONFIGURED
	if (
		path.get_file().get_basename().is_empty()
		or path.get_extension() not in ["gltf", "glb"]
	):
		return ERR_FILE_BAD_PATH

	var exported: Array[MeshInstance3D] = []
	for mesh: MeshInstance3D in meshes:
		exported.append(mesh.duplicate())

	var file_name := path.get_file().get_basename()
	var root := Node3D.new()
	root.name = file_name
	for mesh: MeshInstance3D in exported:
		root.add_child(mesh)
		mesh.owner = root

	var document := GLTFDocument.new()
	document.set_image_format("None")  # TODO: this should also be an option
	# FIXME: without "None", texture images are not being saved properly
	var state := GLTFState.new()
	var err := document.append_from_scene(root, state)
	if err == OK:
		err = document.write_to_filesystem(state, path)
	if err == OK:
		# TODO: make this optional, maybe someone doesn't want "use_external" enabled
		err = _write_import_materials(path, state)

	root.free()
	return err
