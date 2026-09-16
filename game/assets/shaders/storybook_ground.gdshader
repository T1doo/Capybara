shader_type canvas_item;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(0.47, 0.56, 0.43, 1.0);
uniform vec4 light_wash : source_color = vec4(0.55, 0.63, 0.47, 1.0);
uniform vec4 deep_wash : source_color = vec4(0.44, 0.54, 0.40, 1.0);
uniform float wash_scale : hint_range(64.0, 512.0) = 240.0;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.045;

varying vec2 world_position;


float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}


float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	vec2 wash_point = world_position / wash_scale;
	float broad = value_noise(wash_point);
	float medium = value_noise(wash_point * 2.17 + vec2(8.4, -3.1));
	float grain = hash21(floor(world_position * 0.33));
	float wash = clamp(broad * 0.72 + medium * 0.28, 0.0, 1.0);
	vec3 painted = mix(deep_wash.rgb, light_wash.rgb, smoothstep(0.12, 0.9, wash));
	painted = mix(painted, base_color.rgb, 0.58);
	painted += (grain - 0.5) * grain_strength;
	COLOR = vec4(painted, 1.0);
}
