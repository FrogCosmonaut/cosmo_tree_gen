# Copyright © 2026 CosmonautFrog - MIT License

extends RefCounted
## Builds collision shapes from the tree skeleton.

const Branch := preload("./branch.gd")
const MeshUtils := preload("./mesh_utils.gd")


static func _convex(points: PackedVector3Array) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape


static func create_shapes(
	type: CosmoTreeGen.CollisionType,
	branches: Array[Branch],
	max_level: int,
	radial: int,
) -> Array[Shape3D]:
	var shapes: Array[Shape3D] = []
	var faces := PackedVector3Array()

	for branch in branches:
		if branch.level > max_level:
			continue

		var vertices := PackedVector3Array()
		var indices := PackedInt32Array()
		MeshUtils.append_tube(vertices, indices, PackedVector2Array(), branch.points, branch.radii, radial)

		match type:
			CosmoTreeGen.CollisionType.SIMPLE_CONVEX:
				shapes.append(_convex(vertices))
			CosmoTreeGen.CollisionType.MULTIPLE_CONVEX:
				# two consecutive rings make a frustum, which is already convex
				var ring := radial + 1
				for i in branch.points.size() - 1:
					shapes.append(_convex(vertices.slice(i * ring, (i + 2) * ring)))
			CosmoTreeGen.CollisionType.TRIMESH:
				for i in indices:
					faces.push_back(vertices[i])

	if not faces.is_empty():
		var trimesh := ConcavePolygonShape3D.new()
		trimesh.set_faces(faces)
		shapes.append(trimesh)

	return shapes
