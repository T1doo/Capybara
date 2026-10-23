extends Node2D

const GAIT_SCRIPT = preload("res://../tools/art/player_hybrid_gait.gd")
const FACING: Dictionary[StringName, Vector2] = {
	&"down": Vector2.DOWN, &"down_right": Vector2(1, 1), &"right": Vector2.RIGHT, &"up_right": Vector2(1, -1),
	&"up": Vector2.UP, &"up_left": Vector2(-1, -1), &"left": Vector2.LEFT, &"down_left": Vector2(-1, 1)
}

var actor: PlayerCharacter
var manifest: Dictionary
var base: String
var pivot: Vector2
var display_scale: float
var images: Dictionary[String, Dictionary] = {}
var body: Sprite2D
var limbs: Array[MeshInstance2D] = []
var grid_points: Array[PackedVector2Array] = []
var grid_uvs: Array[PackedVector2Array] = []
var grid_indices: Array[PackedInt32Array] = []
var foot_sources: Array[Dictionary] = []
var foot_paths: Array[String] = ["", "", "", ""]
var shadows: Array[Polygon2D] = []
var gait: GAIT_SCRIPT = GAIT_SCRIPT.new()
var state: Dictionary
var body_heading: int = 0
var pickup_elapsed: float = -1.0
var pickup_count: int = 0
var unsupported_pickup_count: int = 0
var texture_bytes: int = 0
var ready_to_animate: bool = false


func configure(player: PlayerCharacter, manifest_path: String) -> Error:
	actor = player
	base = manifest_path.replace("\\", "/").simplify_path().get_base_dir()
	manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest.get("complete", false) or not is_equal_approx(player.scale.x, player.scale.y): return ERR_INVALID_DATA
	pivot = Vector2(manifest["pivot"][0], manifest["pivot"][1])
	display_scale = float(manifest["display_scale"])
	scale = Vector2.ONE * display_scale / actor.scale.x
	position = -pivot * scale
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	process_physics_priority = 100
	for heading: Dictionary in manifest["headings"]:
		for entry: Dictionary in heading["upper"]:
			if not _load_plate(entry): return ERR_INVALID_DATA
		for foot: Dictionary in heading["feet"]:
			if not _load_plate(foot["image"]): return ERR_INVALID_DATA
	for _index in range(4):
		var limb := MeshInstance2D.new()
		add_child(limb)
		limbs.append(limb)
		grid_points.append(PackedVector2Array())
		grid_uvs.append(PackedVector2Array())
		grid_indices.append(PackedInt32Array())
		foot_sources.append({})
		var shadow := Polygon2D.new()
		var shadow_points := PackedVector2Array()
		for point in range(24):
			var angle: float = TAU * point / 24.0
			shadow_points.append(Vector2(cos(angle) * 8, sin(angle) * 3))
		shadow.polygon = shadow_points
		shadow.color = Color(0.12, 0.11, 0.07, 0.16)
		shadow.z_as_relative = false
		shadow.z_index = 49
		actor.get_parent().add_child(shadow)
		shadows.append(shadow)
	body = Sprite2D.new()
	body.centered = false
	add_child(body)
	var p: Array = manifest["projection"]
	gait.configure(Transform2D(Vector2(p[0][0], p[1][0]), Vector2(p[0][1], p[1][1]), Vector2.ZERO),
		float(manifest["height_scale"]), actor.global_position, FACING[actor.get_facing_id()])
	actor.interaction_completed.connect(_on_interaction)
	ready_to_animate = true
	return OK


func _load_plate(entry: Dictionary) -> bool:
	var path: String = base.path_join(entry["path"]).simplify_path()
	if not path.begins_with(base + "/") or FileAccess.get_sha256(path) != entry["sha256"]: return false
	var image := Image.load_from_file(path)
	if image == null or image.get_format() != Image.FORMAT_RGBA8 or image.get_size() != Vector2i(640, 640): return false
	var box: Array = entry["alpha_bbox"]
	var rect := Rect2i(int(box[0]) - 1, int(box[1]) - 1, int(box[2]) - int(box[0]) + 2, int(box[3]) - int(box[1]) + 2)
	if not Rect2i(0, 0, 640, 640).encloses(rect): return false
	# Byte-preserving in-memory crop; source PNG, native scale and pivot stay fixed.
	var cropped: Image = image.get_region(rect)
	texture_bytes += cropped.get_data().size()
	images[entry["path"]] = {"texture": ImageTexture.create_from_image(cropped), "rect": rect}
	return true


func _physics_process(delta: float) -> void:
	if not ready_to_animate: return
	state = gait.advance(actor.global_position, FACING[actor.get_facing_id()], delta)
	body_heading = _heading(float(state["yaw"]))
	var view: Dictionary = manifest["headings"][body_heading]
	var key: int = 0
	if pickup_elapsed >= 0:
		pickup_elapsed += delta
		if pickup_elapsed > 0.9:
			pickup_elapsed = -1
		else:
			key = roundi(pow(sin(PI * pickup_elapsed / 0.9), 2) * 4)
	key = mini(key, view["upper"].size() - 1)
	var upper: Dictionary = images[view["upper"][key]["path"]]
	var rect: Rect2i = upper["rect"]
	var breath_scale: float = 1.0 + float(state["breath"]) * 0.006 if key == 0 else 1.0
	body.texture = upper["texture"]
	body.scale = Vector2(1, breath_scale)
	body.position = Vector2(rect.position.x, pivot.y + (rect.position.y - pivot.y) * breath_scale)
	for index in range(4):
		var foot: Dictionary = state["feet"][index]
		var source: Dictionary = manifest["headings"][_heading(float(foot["yaw"]))]["feet"][index]
		if foot_paths[index] != source["image"]["path"]:
			foot_paths[index] = source["image"]["path"]
			foot_sources[index] = source
			limbs[index].texture = images[foot_paths[index]]["texture"]
			_make_grid(index)
		_deform(index, foot, float(view["yaw"]))
		shadows[index].global_position = foot["sole"] + Vector2(0, float(foot["lift"]))
		shadows[index].modulate.a = 1.0 / (1.0 + float(foot["lift"]) * 0.15)


func _heading(yaw: float) -> int:
	var closest: int = 0
	var minimum: float = INF
	for index in range(manifest["headings"].size()):
		var difference: float = yaw - float(manifest["headings"][index]["yaw"])
		var distance: float = absf(atan2(sin(difference), cos(difference)))
		if distance < minimum:
			minimum = distance
			closest = index
	return closest


func _make_grid(index: int) -> void:
	var rect: Rect2i = images[foot_paths[index]]["rect"]
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for y in range(9):
		for x in range(7):
			var point: Vector2 = Vector2(rect.position) + Vector2(rect.size) * Vector2(x / 6.0, y / 8.0)
			points.append(point)
			uv.append((point - Vector2(rect.position)) / Vector2(rect.size))
	for y in range(8):
		for x in range(6):
			var start: int = y * 7 + x
			indices.append_array(PackedInt32Array([start, start + 1, start + 8, start, start + 8, start + 7]))
	grid_points[index] = points
	grid_uvs[index] = uv
	grid_indices[index] = indices


func _deform(index: int, foot: Dictionary, draw_yaw: float) -> void:
	var source: Dictionary = foot_sources[index]
	var hip := Vector2(source["hip"][0], source["hip"][1])
	var sole := Vector2(source["sole"][0], source["sole"][1])
	var hip_target: Vector2 = pivot + (gait.projection * GAIT_SCRIPT.REST[index].rotated(draw_yaw)
		- Vector2(0, 0.48 * gait.height_scale)) / display_scale
	var sole_target: Vector2 = pivot + (Vector2(foot["sole"]) - actor.global_position) / display_scale
	var axis: Vector2 = sole - hip
	var vertices := PackedVector3Array()
	for point: Vector2 in grid_points[index]:
		var weight: float = smoothstep(0, 0.6, (point - hip).dot(axis) / axis.length_squared())
		var moved: Vector2 = point + (hip_target - hip).lerp(sole_target - sole, weight)
		vertices.append(Vector3(moved.x, moved.y, 0))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = grid_uvs[index]
	arrays[Mesh.ARRAY_INDEX] = grid_indices[index]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	limbs[index].mesh = mesh


# Read actual draw vertices/UV triangles, not the gait's requested contact point.
func sample_drawn_soles() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(4):
		var source: Dictionary = foot_sources[index]
		var rect: Rect2i = images[foot_paths[index]]["rect"]
		var uv_point: Vector2 = (Vector2(source["sole"][0], source["sole"][1]) - Vector2(rect.position)) / Vector2(rect.size)
		var arrays: Array = limbs[index].mesh.surface_get_arrays(0)
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var measured: Vector2 = Vector2.INF
		for at in range(0, indices.size(), 3):
			var a: int = indices[at]
			var b: int = indices[at + 1]
			var c: int = indices[at + 2]
			var denominator: float = (uv[b] - uv[a]).cross(uv[c] - uv[a])
			var v: float = (uv_point - uv[a]).cross(uv[c] - uv[a]) / denominator
			var w: float = (uv[b] - uv[a]).cross(uv_point - uv[a]) / denominator
			var u: float = 1.0 - v - w
			if minf(u, minf(v, w)) >= -0.00001:
				var p: Vector3 = vertices[a] * u + vertices[b] * v + vertices[c] * w
				measured = limbs[index].to_global(Vector2(p.x, p.y))
				break
		result.append(measured)
	return result


func _on_interaction(result: InteractionResult) -> void:
	if not result.is_success(): return
	pickup_count += 1
	pickup_elapsed = 0
	if body_heading != 0: unsupported_pickup_count += 1


func _exit_tree() -> void:
	for shadow: Polygon2D in shadows:
		if is_instance_valid(shadow): shadow.queue_free()
