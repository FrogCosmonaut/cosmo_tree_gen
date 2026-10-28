// Copyright © 2026 CosmonautFrog - MIT License

// Two sided leaf cards that keep the CosmoTreeGen canopy normals on both faces.
shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;
uniform vec3 backlight : source_color = vec3(0.45, 0.5, 0.25);
uniform float ao_light_affect : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = albedo.rgb * tex.rgb;
	ALPHA = albedo.a * tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	AO = COLOR.r;
	AO_LIGHT_AFFECT = ao_light_affect;
	BACKLIGHT = backlight;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
}
