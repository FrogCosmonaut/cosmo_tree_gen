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


static func _canopy_direction(p: Vector3, radii: Vector3) -> Vector3:
	var outward := (p / radii).normalized()
	return Vector3.UP.lerp(outward, smoothstep(0.0, 0.5, p.length())).normalized()


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


## Blends the card normals towards an ellipsoid around all the leaves, so
## is lit as one rounded volume (like EZ-Tree "rounded normals", but for the whole thing).
## Also fakes AO in the vertex color, darker int the center.
static func canopy_shading(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	colors: PackedColorArray,
	params: CosmoFoliageParams,
) -> void:
	var bounds := AABB(vertices[0], Vector3.ZERO)
	for v in vertices:
		bounds = bounds.expand(v)
	var center := bounds.get_center()
	var radii := (bounds.size * 0.5).max(Vector3.ONE * 0.01)

	normals.resize(vertices.size())
	colors.resize(vertices.size())
	# 4 vertices per card, see _append_quad
	for q in range(0, vertices.size(), 4):
		var card := (vertices[q + 1] - vertices[q]).cross(vertices[q + 3] - vertices[q]).normalized()
		var mid := (vertices[q] + vertices[q + 2]) * 0.5
		if card.dot(_canopy_direction((mid - center) / radii, radii)) < 0.0:
			card = -card
		for k in 4:
			var p := (vertices[q + k] - center) / radii
			normals[q + k] = card.lerp(_canopy_direction(p, radii), params.leaf_canopy_normals).normalized()
			var ao := lerpf(params.leaf_inner_ao, 1.0, minf(p.length(), 1.0))
			colors[q + k] = Color(ao, ao, ao)
