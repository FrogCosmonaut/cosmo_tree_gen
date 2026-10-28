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


static func generate_trunk(noise_seed: int, params: CosmoTrunkParams) -> Branch:
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var angle := rng.randf() * TAU
	var lean_vec := params.get_lean_vec(angle)

	var quality := maxi(params.quality, 1)
	var rings := BASE_HEIGHT_SEGMENTS * params.quality

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
	return trunk
