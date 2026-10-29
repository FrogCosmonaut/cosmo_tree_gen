# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends RefCounted


## experimental
static func export_gltf(path: String, meshes: Array[ArrayMesh]) -> Error:
	if meshes.is_empty():
		return ERR_UNCONFIGURED
	if (
		path.get_file().get_basename().is_empty()
		or path.get_extension() not in ["gltf", "glb"]
	):
		return ERR_FILE_BAD_PATH

	var exported: Array[ArrayMesh] = []
	for mesh: ArrayMesh in meshes:
		exported.append(mesh.duplicate())

	for am: ArrayMesh in exported:
		for i in am.get_surface_count():
			var material := am.surface_get_material(i)
			if material != null:
				material = material.duplicate()
				# TODO: nothing calls surface_set_name so this is wrong
				material.resource_name = am.surface_get_name(i)
				am.surface_set_material(i, material)

	var file_name := path.get_file().get_basename()
	var root := Node3D.new()
	root.name = file_name
	for i in exported.size():
		var node := MeshInstance3D.new()
		# TODO: get "Trunk"/"Foliage" to set names properly
		node.name = "%s%d" % [file_name.to_pascal_case(), i]
		node.mesh = exported[i]
		root.add_child(node)
		node.owner = root

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var err := document.append_from_scene(root, state)
	if err == OK:
		err = document.write_to_filesystem(state, path)

	root.free()
	return err
