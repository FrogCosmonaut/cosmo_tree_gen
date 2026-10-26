# Copyright © 2026 CosmonautFrog - GNU GPL v3 License

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


# TODO: instead of a CylinderMesh, build it procedurally.
# L-Systems / Space colonization algorithm
static func generate_trunk(
	quality: int,
	height: float,
	bottom_radius: float,
	top_radius: float,
	flat_shading: bool = false,
) -> Mesh:
	quality = maxi(quality, 1)
	var radial := BASE_RADIAL_SEGMENTS * quality
	var rings := BASE_HEIGHT_SEGMENTS * quality

	var cyl := CylinderMesh.new()
	cyl.height = height
	cyl.bottom_radius = bottom_radius
	cyl.top_radius = top_radius
	cyl.radial_segments = radial
	cyl.rings = rings
	cyl.cap_bottom = false
	cyl.cap_top = false
	if flat_shading:
		return MeshUtils.flatten_mesh(cyl)
	return cyl
