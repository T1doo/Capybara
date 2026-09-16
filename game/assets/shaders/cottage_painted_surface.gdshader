shader_type canvas_item;
render_mode unshaded;

uniform sampler2D material_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D material_mask : filter_nearest, repeat_disable;
uniform float paint_strength : hint_range(0.0, 1.0) = 1.0;
varying vec4 layer_modulate;

void vertex() {
	layer_modulate = COLOR;
}

vec3 swatch(vec2 local_uv, float panel) {
	// Keep sampling two source texels inside each atlas panel; never repeat across panels.
	vec2 safe_uv = mix(vec2(0.004), vec2(0.996), clamp(local_uv, vec2(0.0), vec2(1.0)));
	return texture(material_atlas, vec2((panel + safe_uv.x) / 3.0, safe_uv.y)).rgb;
}

vec2 quad_uv(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d) {
	vec2 e = b - a;
	vec2 f = d - a;
	vec2 g = a - b + c - d;
	vec2 uv = vec2(0.5);
	// Invert the bilinear map, keeping tile rows aligned with each sloping roof face.
	for (int i = 0; i < 6; i++) {
		vec2 error = a + e*uv.x + f*uv.y + g*uv.x*uv.y - p;
		vec2 du = e + g*uv.y;
		vec2 dv = f + g*uv.x;
		float det = du.x*dv.y - du.y*dv.x;
		if (abs(det) < 0.001) { break; }
		uv -= vec2(error.x*dv.y-error.y*dv.x, du.x*error.y-du.y*error.x) / det;
	}
	return uv;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 mask = texture(material_mask, UV).rgb;
	vec2 p = UV * 1024.0;
	vec3 painted = base.rgb;
	float strength = 0.0;
	if (mask.g > 0.6) {
		vec2 wood_uv = vec2(p.x / 1024.0, p.y / 1024.0);
		if (mask.b > 0.6) { wood_uv = wood_uv.yx; }
		vec3 timber = swatch(wood_uv, 1.0);
		painted = mix(base.rgb, timber, 0.76);
		strength = 1.0;
	} else if (mask.b > 0.6) {
		vec2 roof_uv = quad_uv(p, vec2(348,214), vec2(754,246), vec2(650,539), vec2(121,484));
		float face_boundary = 754.0 - (p.y-246.0)*106.0/280.0;
		if (p.x > face_boundary) {
			roof_uv = quad_uv(p, vec2(754,246), vec2(886,421), vec2(824,464), vec2(648,526));
		}
		painted = swatch(roof_uv, 2.0) * mix(1.08, 0.87, roof_uv.y);
		strength = 1.0;
	} else if (mask.r > 0.6) {
		vec3 plaster = swatch(vec2(p.x / 1024.0, p.y / 1024.0), 0.0);
		painted = mix(base.rgb, plaster, 0.48);
		strength = 1.0;
	}
	// Material sampling never creates opacity outside the source layer or cancels roof fading.
	COLOR = vec4(mix(base.rgb, painted, strength * paint_strength), base.a) * layer_modulate;
}
