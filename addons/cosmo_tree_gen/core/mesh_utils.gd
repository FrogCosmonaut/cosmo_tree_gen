# Copyright © 2026 CosmonautFrog - MIT License

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


static func append_tube(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	points: PackedVector3Array,
	radii: PackedFloat32Array,
	radial: int,
) -> void:
	var base := vertices.size()
	var count := points.size()
	var tangent := (points[1] - points[0]).normalized()
	var helper := Vector3.RIGHT if absf(tangent.y) > 0.9 else Vector3.UP
	var normal := tangent.cross(helper).normalized()

	for i in count:
		tangent = (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		normal = (normal - tangent * normal.dot(tangent)).normalized()
		var binormal := normal.cross(tangent)
		for j in radial:
			var angle := TAU * j / radial
			vertices.push_back(points[i] + (normal * cos(angle) + binormal * sin(angle)) * radii[i])

	for i in count - 1:
		for j in radial:
			var j_next := (j + 1) % radial
			var a := base + i * radial + j
			var b := base + i * radial + j_next
			var c := base + (i + 1) * radial + j
			var d := base + (i + 1) * radial + j_next
			indices.append_array(PackedInt32Array([d, c, a, d, a, b]))
