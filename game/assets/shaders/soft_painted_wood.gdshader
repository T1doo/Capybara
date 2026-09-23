shader_type canvas_item;
render_mode unshaded;

uniform vec4 wash_color : source_color = vec4(0.53, 0.37, 0.25, 1.0);
uniform float texture_retention : hint_range(0.0, 1.0) = 0.72;

varying vec4 vertex_tint;


void vertex() {
	vertex_tint = COLOR;
}


void fragment() {
	vec4 wood = texture(TEXTURE, UV);
	vec3 softened = mix(wash_color.rgb, wood.rgb, texture_retention);
	COLOR = vec4(softened, wood.a) * vertex_tint;
}
