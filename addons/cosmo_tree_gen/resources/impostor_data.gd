# Copyright © 2026 CosmonautFrog - MIT License

@tool
class_name CosmoImpostorData
extends Resource

@export var type: CosmoTreeGen.ImpostorType = CosmoTreeGen.ImpostorType.STATIC
@export var albedo_texture: Texture2D
@export var normal_texture: Texture2D
@export var size: Vector2
@export var center: Vector3
@export var mesh: Mesh
@export var source_hash: int


func is_valid() -> bool:
	return (
		mesh != null
		and albedo_texture != null
		and normal_texture != null
		and size.x > 0.0
		and size.y > 0.0
	)


func get_aabb() -> AABB:
	var r := size.x / 2
	return AABB(
		Vector3(-r, center.y - size.y / 2, -r),
		Vector3(2 * r, size.y, 2 * r)
	)
