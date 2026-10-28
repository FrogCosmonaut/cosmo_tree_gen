# Copyright © 2026 CosmonautFrog - MIT License

extends RefCounted
## Leaf cards generator: textured quads along a branch, EZ-Tree style.
## References:
## - https://tympanus.net/codrops/2025/01/27/fractals-to-forests-creating-realistic-3d-trees-with-three-js/

const Branch := preload("./branch.gd")
const TreeSkeleton := preload("./tree_skeleton.gd")


static func _append_quad(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	base: Vector3,
	up: Vector3,
	right: Vector3,
) -> void:
	var first := vertices.size()
	var half := right * 0.5
	vertices.append_array(PackedVector3Array([base - half, base + half, base + half + up, base - half + up]))
	uvs.append_array(PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]))
	indices.append_array(PackedInt32Array([first, first + 3, first + 2, first, first + 2, first + 1]))


static func append_leaves(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	uvs: PackedVector2Array,
	branch: Branch,
	params: CosmoFoliageParams,
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([branch.branch_seed, "ayylmao"])
	var tilt := deg_to_rad(params.leaf_angle)

	for k in params.leaf_count:
		var t := lerpf(params.leaf_start, 1.0, (k + rng.randf()) / params.leaf_count)
		var origin := branch.sample(t)
		var tangent := branch.tangent_at(t)

		var helper := Vector3.RIGHT if absf(tangent.y) > 0.9 else Vector3.UP
		var azimuth := k * TreeSkeleton.GOLDEN_ANGLE + rng.randf_range(-0.3, 0.3)
		var side := tangent.cross(helper).normalized().rotated(tangent, azimuth)

		var size := params.leaf_size * (1.0 + rng.randf_range(-1.0, 1.0) * params.leaf_size_variance)
		var up := (tangent * cos(tilt) + side * sin(tilt)) * size
		var right := tangent.cross(side).normalized() * size
		# Both drawn always so toggling leaf_double doesn't reshuffle the other leaves
		var variant := rng.randf()
		var double_variant := rng.randf()
		_append_quad(vertices, indices, uvs, origin, up, right)
		if params.leaf_double:
			var double_right := up.cross(right).normalized() * size
			_append_quad(vertices, indices, uvs, origin, up, double_right)
