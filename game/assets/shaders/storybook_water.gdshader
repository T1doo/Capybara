shader_type canvas_item;
render_mode unshaded;

uniform vec4 shallow_color : source_color = vec4(0.57, 0.80, 0.72, 1.0);
uniform vec4 mid_color : source_color = vec4(0.31, 0.64, 0.63, 1.0);
uniform vec4 deep_color : source_color = vec4(0.17, 0.42, 0.47, 1.0);
uniform vec4 glint_color : source_color = vec4(0.78, 0.91, 0.82, 1.0);
uniform float motion_strength : hint_range(0.0, 1.0) = 1.0;
uniform float contrast_strength : hint_range(0.0, 1.0) = 0.0;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.32;
uniform float overlay_alpha : hint_range(0.0, 1.0) = 0.30;

varying vec2 world_position;


float soft_wave(vec2 point, float time_offset) {
	float long_wave = sin(point.x * 0.013 + point.y * 0.006 + time_offset);
	float cross_wave = sin(point.x * -0.008 + point.y * 0.017 - time_offset * 0.73);
	return long_wave * 0.62 + cross_wave * 0.38;
}


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	float animated_time = TIME * flow_speed * motion_strength;
	float broad = soft_wave(world_position, animated_time);
	float detail = soft_wave(world_position * 1.41 + vec2(37.0, -19.0), animated_time * 1.37);
	float wash = smoothstep(-0.95, 0.95, broad * 0.74 + detail * 0.26);
	vec3 painted_water = mix(deep_color.rgb, mid_color.rgb, wash);
	painted_water = mix(painted_water, shallow_color.rgb, smoothstep(0.34, 0.92, wash) * 0.42);
	float glint = smoothstep(0.91, 0.99, sin(world_position.x * 0.026 - world_position.y * 0.011 + animated_time));
	painted_water = mix(painted_water, glint_color.rgb, glint * (0.16 + contrast_strength * 0.18));
	painted_water = mix(painted_water, (painted_water - vec3(0.5)) * 1.32 + vec3(0.5), contrast_strength * 0.42);
	COLOR = vec4(painted_water, overlay_alpha);
}
