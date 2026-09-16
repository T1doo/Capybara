shader_type canvas_item;

uniform vec2 crown_radius = vec2(148.0, 116.0);
uniform float painted_contrast = 0.70;
varying vec2 local_point;
varying vec4 vertex_tint;

void vertex() {
	local_point = VERTEX / crown_radius;
	vertex_tint = COLOR;
}

void fragment() {
	vec4 modulation = vertex_tint;
	vec4 painted = texture(TEXTURE, UV);
	vec3 foliage = mix(vec3(0.39, 0.49, 0.27), painted.rgb, painted_contrast);
	float shade = 1.0 - 0.13 * clamp(dot(local_point, vec2(0.55, 0.65)), -0.7, 1.0);
	COLOR = vec4(foliage * shade * modulation.rgb, painted.a * modulation.a);
}
