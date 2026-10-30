# Copyright © 2026 CosmonautFrog - MIT License

extends RefCounted
## Trunk generator
## References:
## - EZ-Tree author: https://tympanus.net/codrops/2025/01/27/fractals-to-forests-creating-realistic-3d-trees-with-three-js/
## - Coding Train / Dan Shiffman: https://www.youtube.com/watch?v=MwLyeEWnMCY
## - https://algorithmicbotany.org/
## - https://en.wikipedia.org/wiki/L-system

const Branch := preload("./branch.gd")

const BASE_RADIAL_SEGMENTS: int = 6
const BASE_HEIGHT_SEGMENTS: int = 3
const FLARE_RINGS: int = 4


static func generate_trunk(noise_seed: int, params: CosmoTrunkParams) -> Branch:
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var angle := rng.randf() * TAU
	var lean_vec := params.get_lean_vec(angle)

	var quality := maxi(params.quality, 1)
	var rings := BASE_HEIGHT_SEGMENTS * quality

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.5

	var trunk := Branch.new()
	trunk.branch_seed = noise_seed
	for i in rings + 1:
		var t := float(i) / rings
		var center := Vector3(lean_vec.x * t * t, params.height * t, lean_vec.z * t * t)
		var w := params.wobble * sin(PI * t)
		center.x += w * noise.get_noise_1d(t * params.height)
		center.z += w * noise.get_noise_1d(t * params.height + 100.0)
		trunk.add_point(center, lerpf(params.radius_bottom, params.radius_top, t))

	trunk.base_rings = FLARE_RINGS if params.flare > 0.0 else 0
	trunk.sink_depth = params.sink_depth
	return trunk


static func flare_base(
	vertices: PackedVector3Array,
	first: int,
	noise_seed: int,
	params: CosmoTrunkParams,
) -> void:
	if params.flare <= 0.0:
		return

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 1.0
	var reach := params.height * params.flare_height

	for i in range(first, vertices.size()):
		var s := minf(1.0 - vertices[i].y / reach, 1.0)
		if s <= 0.0:
			continue

		# sampled on a unit circle so it wraps around the trunk without a seam
		var lobe := noise.get_noise_2dv(Vector2(vertices[i].x, vertices[i].z).normalized())
		var grow := 1.0 + params.flare * s * s * s * (1.0 + 2.0 * params.flare_lobes * lobe)
		vertices[i].x *= grow
		vertices[i].z *= grow
