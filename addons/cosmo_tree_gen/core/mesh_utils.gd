# Copyright © 2026 CosmonautFrog - MIT License

class_name MeshUtils  # TODO: be used as `const MeshUtils = preload(".../mesh_utils.gd")`
extends RefCounted
## Shared helpers


static func smooth_normals(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())

	for t in range(0, indices.size(), 3):
		var a := indices[t]
		var b := indices[t + 1]
		var c := indices[t + 2]
		var face := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
		normals[a] += face
		normals[b] += face
		normals[c] += face

	for i in normals.size():
		normals[i] = normals[i].normalized()
	return normals


static func fill_flat(
	arrays: Array,
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs := PackedVector2Array(),
) -> void:
	var count := indices.size()
	var has_uvs := not uvs.is_empty()
	var flat_vertices := PackedVector3Array()
	var flat_normals := PackedVector3Array()
	var flat_uvs := PackedVector2Array()
	flat_vertices.resize(count)
	flat_normals.resize(count)
	if has_uvs:
		flat_uvs.resize(count)

	for t in range(0, count, 3):
		var a := vertices[indices[t]]
		var b := vertices[indices[t + 1]]
		var c := vertices[indices[t + 2]]
		var normal := (c - a).cross(b - a).normalized()
		for k in 3:
			flat_vertices[t + k] = vertices[indices[t + k]]
			flat_normals[t + k] = normal
			if has_uvs:
				flat_uvs[t + k] = uvs[indices[t + k]]

	arrays[Mesh.ARRAY_VERTEX] = flat_vertices
	arrays[Mesh.ARRAY_NORMAL] = flat_normals
	if has_uvs:
		arrays[Mesh.ARRAY_TEX_UV] = flat_uvs


static func build_mesh(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	flat_shading: bool,
	uvs := PackedVector2Array(),
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	if flat_shading:
		fill_flat(arrays, vertices, indices, uvs)
	else:
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = smooth_normals(vertices, indices)
		arrays[Mesh.ARRAY_INDEX] = indices
		if not uvs.is_empty():
			arrays[Mesh.ARRAY_TEX_UV] = uvs

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func flatten_mesh(mesh: Mesh) -> ArrayMesh:
	var src := mesh.surface_get_arrays(0)
	var uvs = src[Mesh.ARRAY_TEX_UV]
	var result := build_mesh(
		src[Mesh.ARRAY_VERTEX],
		src[Mesh.ARRAY_INDEX],
		true,
		uvs if uvs != null else PackedVector2Array(),
	)
	result.surface_set_material(0, mesh.surface_get_material(0))
	return result
