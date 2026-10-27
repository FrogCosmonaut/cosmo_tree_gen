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


static func generate_trunk(
	noise_seed: int,
	quality: int,
	height: float,
	bottom_radius: float,
	top_radius: float,
	lean := Vector3.ZERO,
	wobble: float = 0.0,
) -> Branch:
	quality = maxi(quality, 1)
	var rings := BASE_HEIGHT_SEGMENTS * quality

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.5

	var trunk := Branch.new()
	trunk.branch_seed = noise_seed
	for i in rings + 1:
		var t := float(i) / rings
		var center := Vector3(lean.x * t * t, height * t, lean.z * t * t)
		var w := wobble * sin(PI * t)
		center.x += w * noise.get_noise_1d(t * height)
		center.z += w * noise.get_noise_1d(t * height + 100.0)
		trunk.add_point(center, lerpf(bottom_radius, top_radius, t))
	return trunk
