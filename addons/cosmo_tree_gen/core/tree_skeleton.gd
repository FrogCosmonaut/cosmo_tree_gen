# Copyright © 2026 CosmonautFrog - MIT License

class_name TreeSkeleton  # TODO: be used as `const TreeSkeleton = preload(".../tree_skeleton.gd")`
extends RefCounted
## Grows child branches out of a parent Branch.

## PI * (3 - sqrt(5)), ~137.5° - https://en.wikipedia.org/wiki/Golden_angle
const GOLDEN_ANGLE: float = 2.399963229728653


static func grow_branches(parent: Branch, level: CosmoBranchLevel) -> Array[Branch]:
	var branches: Array[Branch] = []
	var parent_length := parent.get_length()

	for k in level.count:
		var branch_seed := hash([parent.branch_seed, k])
		var rng := RandomNumberGenerator.new()
		rng.seed = branch_seed

		var t := lerpf(level.start, level.end, (k + rng.randf()) / level.count)
		var origin := parent.sample(t)
		var tangent := parent.tangent_at(t)
		var parent_radius := parent.radius_at(t)

		var helper := Vector3.RIGHT if absf(tangent.y) > 0.9 else Vector3.UP
		var azimuth := k * GOLDEN_ANGLE + rng.randf_range(-0.3, 0.3)
		var side := tangent.cross(helper).normalized().rotated(tangent, azimuth)
		var tilt := deg_to_rad(level.angle)
		var dir := tangent * cos(tilt) + side * sin(tilt)

		var step := parent_length * level.length / level.segments
		var r0 := parent_radius * minf(level.radius, 0.8)

		var branch := Branch.new()
		branch.branch_seed = branch_seed
		branch.level = parent.level + 1
		var pos := origin
		for i in level.segments + 1:
			branch.add_point(pos, lerpf(r0, r0 * 0.2, float(i) / level.segments))
			var random := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
			dir = (dir + (Vector3.UP * level.up_force + random * level.gnarl) / level.segments).normalized()
			pos += dir * step
		branches.append(branch)

	return branches
