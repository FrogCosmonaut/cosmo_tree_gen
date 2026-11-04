# Copyright © 2026 CosmonautFrog - MIT License

extends RefCounted
## Builds collision shapes from the tree skeleton.

const Branch := preload("./branch.gd")
const MeshUtils := preload("./mesh_utils.gd")
const TrunkGen := preload("./trunk_gen.gd")


static func _convex(points: PackedVector3Array) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape


static func create_shapes(
	type: CosmoTreeGen.CollisionType,
	branches: Array[Branch],
	max_level: int,
	radial: int,
	trunk_params: CosmoTrunkParams,
) -> Array[Shape3D]:
	var shapes: Array[Shape3D] = []
	var faces := PackedVector3Array()

	for branch in branches:
		if branch.level > max_level:
			continue

		var part := branch
		while part != null:
			var ringed: Branch = part.with_base_rings()
			var vertices := PackedVector3Array()
			var indices := PackedInt32Array()
			MeshUtils.append_tube(
				vertices, indices, PackedVector2Array(), ringed.points, ringed.radii, radial,
				part.terminal == null,
			)

			if part.base_rings > 0 and type != CosmoTreeGen.CollisionType.SIMPLE_CONVEX:
				TrunkGen.flare_base(vertices, 0, part, trunk_params)

			match type:
				CosmoTreeGen.CollisionType.SIMPLE_CONVEX:
					shapes.append(_convex(vertices))
				CosmoTreeGen.CollisionType.MULTIPLE_CONVEX:
					# two consecutive rings make a frustum, which is already convex
					var ring := radial + 1
					for i in ringed.points.size() - 1:
						shapes.append(_convex(vertices.slice(i * ring, (i + 2) * ring)))
				CosmoTreeGen.CollisionType.TRIMESH:
					for i in indices:
						faces.push_back(vertices[i])

			part = part.terminal

	if not faces.is_empty():
		var trimesh := ConcavePolygonShape3D.new()
		trimesh.set_faces(faces)
		shapes.append(trimesh)

	return shapes
