class_name EnvironmentStyleProfile
extends Resource

@export_range(1.0, 256.0, 1.0) var grid_size: float = 64.0
@export_range(64.0, 256.0, 1.0) var player_display_height: float = 144.0
@export_range(20.0, 50.0, 0.5) var camera_pitch_degrees: float = 35.0
@export var light_direction: Vector2 = Vector2(-1.0, -1.0).normalized()
@export var contact_shadow_offset: Vector2 = Vector2(12.0, 16.0)
@export_range(0.1, 0.8, 0.01) var canopy_faded_alpha: float = 0.34
@export_range(0.0, 1.0, 0.01) var canopy_fade_seconds: float = 0.18

@export_group("Ground")
@export var ground_base: Color = Color("#78906d")
@export var ground_light: Color = Color("#8da079")
@export var ground_deep: Color = Color("#718a67")
@export var path_fill: Color = Color("#c9ad77")
@export var path_edge: Color = Color("#8b7657")

@export_group("Water and shore")
@export var shore_edge: Color = Color("#356f73")
@export var water_base: Color = Color("#5ea7a0")
@export var shallow_glint: Color = Color("#8ec2ae")
@export var shore_highlight: Color = Color("#b5d6bd")
@export_range(4.0, 32.0, 1.0) var shore_band_width: float = 18.0
@export_range(2.0, 16.0, 1.0) var shore_highlight_width: float = 8.0

@export_group("Lighting")
@export var contact_shadow_color: Color = Color(0.15, 0.12, 0.09, 0.24)


func validate() -> StringName:
	if not is_equal_approx(grid_size, 64.0):
		return &"STYLE_GRID_SIZE"
	if player_display_height < 128.0 or player_display_height > 160.0:
		return &"STYLE_PLAYER_SCALE"
	if camera_pitch_degrees < 30.0 or camera_pitch_degrees > 40.0:
		return &"STYLE_CAMERA_PITCH"
	if not light_direction.is_finite() or light_direction.is_zero_approx():
		return &"STYLE_LIGHT_DIRECTION"
	if light_direction.x >= 0.0 or light_direction.y >= 0.0:
		return &"STYLE_LIGHT_NOT_UPPER_LEFT"
	if contact_shadow_offset.x <= 0.0 or contact_shadow_offset.y <= 0.0:
		return &"STYLE_SHADOW_NOT_LOWER_RIGHT"
	if canopy_faded_alpha < 0.25 or canopy_faded_alpha > 0.5:
		return &"STYLE_CANOPY_ALPHA"
	if shore_highlight_width >= shore_band_width:
		return &"STYLE_SHORE_WIDTHS"
	return &""
