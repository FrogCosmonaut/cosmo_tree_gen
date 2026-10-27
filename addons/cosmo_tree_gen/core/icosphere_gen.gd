# Copyright © 2026 CosmonautFrog - MIT License

class_name IcosphereGen  # TODO: be used as `const IcosphereGen = preload(".../icosphere_gen.gd")`
extends RefCounted
## Icosphere generator
## All the math's from:
## - https://blog.lslabs.dev/posts/generating_icosphere_with_code
## - https://schneide.blog/2016/07/15/generating-an-icosphere-in-c/

## (1 + sqrt(5)) / 2 - https://en.wikipedia.org/wiki/Golden_ratio
const T: float = 1.618033988749895


static func _subdivide(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	levels: int,
) -> PackedInt32Array:
	var mid := PackedInt32Array([0, 0, 0])  # ab, bc, ca

	for level in levels:
		var cache := {}
		var new_indices := PackedInt32Array()
		new_indices.resize(indices.size() * 4)
		var n := 0

		for t in range(0, indices.size(), 3):
			for e in 3:
				var p := indices[t + e]
				var q := indices[t + (e + 1) % 3]
				var key := (mini(p, q) << 32) | maxi(p, q)
				var m: int = cache.get(key, -1)
				if m == -1:
					m = vertices.size()
					vertices.push_back((vertices[p] + vertices[q]).normalized())
					cache[key] = m
				mid[e] = m

			var a := indices[t]
			var b := indices[t + 1]
			var c := indices[t + 2]
			var ab := mid[0]
			var bc := mid[1]
			var ca := mid[2]

			new_indices[n] = a
			new_indices[n + 1] = ab
			new_indices[n + 2] = ca
			new_indices[n + 3] = b
			new_indices[n + 4] = bc
			new_indices[n + 5] = ab
			new_indices[n + 6] = c
			new_indices[n + 7] = ca
			new_indices[n + 8] = bc
			new_indices[n + 9] = ab
			new_indices[n + 10] = bc
			new_indices[n + 11] = ca
			n += 12

		indices = new_indices

	return indices


static func _displace(
	vertices: PackedVector3Array,
	noise_seed: int,
	amplitude: float,
	frequency: float,
) -> void:
	if is_zero_approx(amplitude):
		return

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency

	for i in vertices.size():
		var dir := vertices[i]
		vertices[i] = dir * (1.0 + amplitude * noise.get_noise_3dv(dir))


static func generate_icosphere(
	noise_seed: int = 0,
	subdivisions: int = 0,
	amplitude: float = 0.0,
	frequency: float = 1.5,
	flat_shading: bool = false,
) -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(-1, T, 0), Vector3(1, T, 0), Vector3(-1, -T, 0), Vector3(1, -T, 0),
		Vector3(0, -1, T), Vector3(0, 1, T), Vector3(0, -1, -T), Vector3(0, 1, -T),
		Vector3(T, 0, -1), Vector3(T, 0, 1), Vector3(-T, 0, -1), Vector3(-T, 0, 1),
	])
	for i in vertices.size():
		vertices[i] = vertices[i].normalized()

	var indices := PackedInt32Array([
		0, 5, 11, 0, 1, 5, 0, 7, 1, 0, 10, 7, 0, 11, 10,
		1, 9, 5, 5, 4, 11, 11, 2, 10, 10, 6, 7, 7, 8, 1,
		3, 4, 9, 3, 2, 4, 3, 6, 2, 3, 8, 6, 3, 9, 8,
		4, 5, 9, 2, 11, 4, 6, 10, 2, 8, 7, 6, 9, 1, 8,
	])

	indices = _subdivide(vertices, indices, subdivisions)
	_displace(vertices, noise_seed, amplitude, frequency)
	return MeshUtils.build_mesh(vertices, indices, flat_shading)
