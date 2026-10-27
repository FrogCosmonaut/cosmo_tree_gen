# Copyright © 2026 CosmonautFrog - MIT License

class_name TrunkGen  # TODO: be used as `const TrunkGen = preload(".../trunk_gen.gd")`
extends RefCounted
## Trunk generator
## References:
## - EZ-Tree author: https://tympanus.net/codrops/2025/01/27/fractals-to-forests-creating-realistic-3d-trees-with-three-js/
## - Coding Train / Dan Shiffman: https://www.youtube.com/watch?v=MwLyeEWnMCY
## - https://algorithmicbotany.org/
## - https://en.wikipedia.org/wiki/L-system

const BASE_RADIAL_SEGMENTS: int = 6
const BASE_HEIGHT_SEGMENTS: int = 3

# TODO: add branches + place the icospheres on the branches
# Ideas: L-Systems / Space colonization algorithm for foliage / branches


static func generate_trunk(
	noise_seed: int,
	quality: int,
	height: float,
	bottom_radius: float,
	top_radius: float,
	lean := Vector3.ZERO,
	wobble: float = 0.0,
	flat_shading: bool = false,
) -> ArrayMesh:
	quality = maxi(quality, 1)
	var radial := BASE_RADIAL_SEGMENTS * quality
	var rings := BASE_HEIGHT_SEGMENTS * quality

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.5

	var vertices := PackedVector3Array()
	for i in rings + 1:
		var t := float(i) / rings
		var center := Vector3(lean.x * t * t, height * t, lean.z * t * t)
		var w := wobble * sin(PI * t)
		center.x += w * noise.get_noise_1d(t * height)
		center.z += w * noise.get_noise_1d(t * height + 100.0)

		var radius := lerpf(bottom_radius, top_radius, t)
		for j in radial:
			var angle := TAU * j / radial
			vertices.push_back(center + Vector3(cos(angle), 0.0, sin(angle)) * radius)

	var indices := PackedInt32Array()
	for i in rings:
		for j in radial:
			var j_next := (j + 1) % radial
			var a := i * radial + j
			var b := i * radial + j_next
			var c := (i + 1) * radial + j
			var d := (i + 1) * radial + j_next
			indices.append_array(PackedInt32Array([d, c, a, d, a, b]))

	return MeshUtils.build_mesh(vertices, indices, flat_shading)
