# Copyright © 2026 CosmonautFrog - MIT License

extends RefCounted
## Shared helpers.


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

	# Weld vertices sharing a position (UV seams) so they get the same normal
	var welded := {}
	for i in vertices.size():
		welded[vertices[i]] = welded.get(vertices[i], Vector3.ZERO) + normals[i]

	for i in normals.size():
		normals[i] = welded[vertices[i]].normalized()
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
	uvs: PackedVector2Array,
	points: PackedVector3Array,
	radii: PackedFloat32Array,
	radial: int,
) -> void:
	var base := vertices.size()
	var count := points.size()
	var ring := radial + 1  # extra vertex per ring for the UV seam
	var tangent := (points[1] - points[0]).normalized()
	var helper := Vector3.RIGHT if absf(tangent.y) > 0.9 else Vector3.UP
	var normal := tangent.cross(helper).normalized()
	# One texture repeat per base circumference along the tube, square texels at the base
	var v_scale := 1.0 / (TAU * maxf(radii[0], 0.001))
	var length := 0.0

	for i in count:
		tangent = (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		normal = (normal - tangent * normal.dot(tangent)).normalized()
		var binormal := normal.cross(tangent)
		if i > 0:
			length += points[i].distance_to(points[i - 1])
		# u and v decrease so the texture is upright and not mirrored seen from outside
		var v := -length * v_scale
		var first := vertices.size()
		for j in radial:
			var angle := TAU * j / radial
			vertices.push_back(points[i] + (normal * cos(angle) + binormal * sin(angle)) * radii[i])
			uvs.push_back(Vector2(1.0 - float(j) / radial, v))
		vertices.push_back(vertices[first])
		uvs.push_back(Vector2(0.0, v))

	for i in count - 1:
		for j in radial:
			var a := base + i * ring + j
			var b := a + 1
			var c := a + ring
			var d := c + 1
			indices.append_array(PackedInt32Array([d, c, a, d, a, b]))


static func combine_meshes(array_meshes: Array[ArrayMesh]) -> ArrayMesh:
	# could use SurfaceTool but couldn't find out how to maintain separated materials
	var out := ArrayMesh.new()

	for am: ArrayMesh in array_meshes:
		for i in range(am.get_surface_count()):
			out.add_surface_from_arrays(
				am.surface_get_primitive_type(i),
				am.surface_get_arrays(i)
			)
			var new_idx := out.get_surface_count() - 1
			out.surface_set_name(new_idx, am.surface_get_name(i))
			out.surface_set_material(new_idx, am.surface_get_material(i))

	return out
