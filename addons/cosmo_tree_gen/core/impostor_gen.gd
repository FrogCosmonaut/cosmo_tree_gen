# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends RefCounted

const MeshUtils := preload("./mesh_utils.gd")
const Settings := preload("./settings.gd")
const TreeBuilder := preload("./tree_builder.gd")

const CAPTURE_SHADER := preload("../shaders/impostor_capture.gdshader")
const STATIC_SHADER := preload("../shaders/impostor_static.gdshader")

enum Output {
	ALBEDO,
	NORMAL,
	MASK,
}

const NODE_NAME: String = "Impostor"
const PADDING_PX: int = 2
const PIXEL_ALIGNMENT: int = 4
const ALPHA_THRESHOLD: float = 0.5
const FLAT_NORMAL := Color(0.5, 0.5, 1.0, 0.0)


static func _create_capture_material(source: Material, is_foliage: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CAPTURE_SHADER
	mat.set_shader_parameter("albedo_texture", MeshUtils.get_albedo_texture(source))
	mat.set_shader_parameter("is_foliage", is_foliage)

	if source is BaseMaterial3D:
		var base := source as BaseMaterial3D
		mat.set_shader_parameter("albedo", base.albedo_color)
		mat.set_shader_parameter("uv_scale", base.uv1_scale)
		mat.set_shader_parameter("uv_offset", base.uv1_offset)
		mat.set_shader_parameter("triplanar", base.uv1_triplanar)
		mat.set_shader_parameter("triplanar_sharpness", base.uv1_triplanar_sharpness)
		if base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			mat.set_shader_parameter("alpha_scissor_threshold", base.alpha_scissor_threshold)
	elif source is ShaderMaterial:
		var shader_mat := source as ShaderMaterial
		mat.set_shader_parameter("albedo", _get_shader_param(shader_mat, &"albedo", Color.WHITE))
		mat.set_shader_parameter(
			"alpha_scissor_threshold", _get_shader_param(shader_mat, &"alpha_scissor_threshold", 0.5)
		)
		mat.set_shader_parameter("ao_strength", _get_shader_param(shader_mat, &"ao_light_affect", 0.0))

	return mat


static func _get_shader_param(
	material: ShaderMaterial, param: StringName, fallback: Variant,
) -> Variant:
	var value: Variant = material.get_shader_parameter(param)
	if value == null:
		value = RenderingServer.shader_get_parameter_default(material.shader.get_rid(), param)
	return fallback if value == null else value


static func _average_color(image: Image) -> Color:
	var small := image.duplicate() as Image
	small.generate_mipmaps()
	var c := small.get_data().slice(-4)
	return Color(c[0], c[1], c[2], 0.0) / maxf(c[3], 1.0)


static func _fill_transparent(image: Image, color: Color) -> Image:
	var out := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(color)
	out.blit_rect_mask(image, image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
	out.fix_alpha_edges()
	return out


static func _write_alpha(image: Image, mask: Image) -> void:
	var data := image.get_data()
	var src := mask.get_data()
	for i in range(3, data.size(), 4):
		data[i] = src[i - 3] if src[i] > 0 else 255

	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)


static func _preserve_coverage(image: Image) -> void:
	var data := image.get_data()
	var cutoff := roundi(ALPHA_THRESHOLD * 255.0)
	var target: float = 0.0
	var mm_count := image.get_mipmap_count()

	for level in image.get_mipmap_count() + 1:
		var start := image.get_mipmap_offset(level)
		var end := image.get_mipmap_offset(level + 1) if level < mm_count else data.size()
		var count := (end - start) / 4.0
		var histogram := PackedInt32Array()
		histogram.resize(256)
		for i in range(start + 3, end, 4):
			histogram[data[i]] += 1

		if level == 0:
			for value in range(cutoff, 256):
				target += histogram[value] / count
			continue

		var alpha: int = 255
		var covered := histogram[alpha]
		while alpha > 1 and covered < target * count:
			alpha -= 1
			covered += histogram[alpha]

		var scale := float(cutoff) / alpha
		for i in range(start + 3, end, 4):
			data[i] = mini(roundi(data[i] * scale), 255)

	var w := image.get_width()
	var h := image.get_height()
	image.set_data(w, h, true, Image.FORMAT_RGBA8, data)


static func _create_texture(image: Image) -> PortableCompressedTexture2D:
	var texture := PortableCompressedTexture2D.new()
	# without keep_compressed_buffer set,
	# PortableCompressedTexture2D would save without data
	texture.keep_compressed_buffer = true
	texture.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_BASIS_UNIVERSAL)
	return texture


static func bake(tree: CosmoTreeGen) -> MeshInstance3D:
	var sources := tree.get_meshes(0)
	var bounds := AABB()
	for mi: MeshInstance3D in sources:
		bounds = bounds.merge(mi.get_aabb())

	var resolution: int = Settings.get_setting(Settings.IMPOSTOR_RESOLUTION, 512)
	var half_width := maxf(-bounds.position.x, bounds.end.x)
	var depth := maxf(-bounds.position.z, bounds.end.z)
	var texel := maxf(2.0 * half_width, bounds.size.y) / (resolution - 2 * PADDING_PX)

	var content_size := Vector2(2.0 * half_width, bounds.size.y)
	var content_pixels := content_size / texel
	var padding_pixels := Vector2.ONE * (2.0 * PADDING_PX)
	var required_pixels := content_pixels + padding_pixels
	var aligned_pixels := (required_pixels / PIXEL_ALIGNMENT).ceil() * PIXEL_ALIGNMENT
	var pixels := Vector2i(aligned_pixels)

	var size := Vector2(pixels) * texel
	var center := Vector3(0.0, bounds.get_center().y, 0.0)

	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = size.y
	camera.position = center + Vector3(0.0, 0.0, depth + 1.0)
	camera.far = 2.0 * depth + 2.0
	viewport.add_child(camera)

	var materials: Array[ShaderMaterial] = []
	for src: MeshInstance3D in sources:
		var mesh := src.mesh as ArrayMesh
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		for s in mesh.get_surface_count():
			var is_foliage := mesh.surface_get_name(s) == TreeBuilder.FOLIAGE_SURFACE_NAME
			var mat := _create_capture_material(src.get_active_material(s), is_foliage)
			mi.set_surface_override_material(s, mat)
			materials.append(mat)
		viewport.add_child(mi)

	# TODO: could also be Engine.get_main_loop().root, check what's better
	# e.g.: if tree generation is done in another main screen or from scripting.
	# EditorInterface.get_editor_main_screen()... test it
	# (Engine.get_main_loop() as SceneTree).root.add_child(viewport)
	tree.get_tree().root.add_child(viewport)
	var images: Array[Image] = []
	for output: Output in Output.values():
		for mat in materials:
			mat.set_shader_parameter("output", output)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		images.append(viewport.get_texture().get_image())
	viewport.queue_free()

	var normal := images[Output.NORMAL]
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		normal.srgb_to_linear()
	normal = _fill_transparent(normal, FLAT_NORMAL)
	_write_alpha(normal, images[Output.MASK])
	normal.generate_mipmaps()

	var albedo := _fill_transparent(images[Output.ALBEDO], _average_color(images[Output.ALBEDO]))
	albedo.generate_mipmaps()
	_preserve_coverage(albedo)

	var material := ShaderMaterial.new()
	material.shader = STATIC_SHADER
	material.set_shader_parameter("albedo_texture", _create_texture(albedo))
	material.set_shader_parameter("normal_texture", _create_texture(normal))
	if tree.foliage_material is ShaderMaterial:
		material.set_shader_parameter(
			"backlight", _get_shader_param(tree.foliage_material as ShaderMaterial, &"backlight", Color.BLACK)
		)

	var quad := QuadMesh.new()
	quad.size = size
	quad.center_offset = center
	quad.material = material

	var impostor := MeshInstance3D.new()
	impostor.name = NODE_NAME
	impostor.mesh = quad
	return impostor
