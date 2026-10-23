extends RefCounted

# Candidate locomotion state, driven only by observed Player motion. No input
# schedule, recorded positions, or rendered frame-bank indices are accepted.
const REST: Array[Vector2] = [Vector2(0.66, 0.40), Vector2(0.66, -0.40), Vector2(-0.94, 0.40), Vector2(-0.94, -0.40)]
const PAIRS: Array[Vector2i] = [Vector2i(0, 3), Vector2i(1, 2)]

class Foot extends RefCounted:
	var anchor: Vector2
	var yaw: float
	var swinging: bool = false
	var elapsed: float = 0.0
	var duration: float = 0.0
	var start: Vector2
	var target: Vector2
	var start_yaw: float = 0.0
	var target_yaw: float = 0.0
	var episode: int = 0

var projection: Transform2D
var inverse_projection: Transform2D
var height_scale: float
var yaw: float = 0.0
var previous_position: Vector2
var feet: Array[Foot] = []
var last_pair: int = 1
var was_moving: bool = false
var elapsed: float = 0.0
var reset_count: int = 0
var maximum_reach_px: float = 0.0


func configure(matrix: Transform2D, vertical_scale: float, position: Vector2, facing: Vector2) -> void:
	projection = matrix
	inverse_projection = matrix.affine_inverse()
	height_scale = vertical_scale
	reset(position, facing)


func reset(position: Vector2, facing: Vector2) -> void:
	yaw = (inverse_projection * facing).angle()
	previous_position = position
	feet.clear()
	for rest: Vector2 in REST:
		var foot := Foot.new()
		foot.anchor = position + projection * rest.rotated(yaw)
		foot.yaw = yaw
		feet.append(foot)
	last_pair = 1
	was_moving = false
	reset_count += 1


func advance(position: Vector2, facing: Vector2, delta: float) -> Dictionary:
	assert(delta > 0.0 and not facing.is_zero_approx())
	if position.distance_to(previous_position) > 96.0:
		reset(position, facing) # Scene/load discontinuity, never move the Player itself.
	var motion: Vector2 = position - previous_position
	previous_position = position
	elapsed += delta
	var velocity: Vector2 = motion / delta
	var moving: bool = motion.length() > 0.0001
	var desired: float = (inverse_projection * facing).angle()
	var turn: float = clampf(_angle_delta(yaw, desired), -PI * delta, PI * delta)
	var previous_yaw: float = yaw
	yaw += turn
	var neutral: Array[Vector2] = []
	var neutral_speed: float = 240.0
	for rest: Vector2 in REST:
		neutral.append(position + projection * rest.rotated(yaw))
		var turn_velocity: Vector2 = projection * (rest.rotated(yaw) - rest.rotated(previous_yaw)) / delta
		neutral_speed = maxf(neutral_speed, (velocity + turn_velocity).length())
	var any_swing: bool = false
	for foot: Foot in feet:
		if foot.swinging:
			foot.elapsed += delta
			if foot.elapsed + 0.0000001 >= foot.duration:
				foot.anchor = foot.target
				foot.yaw = foot.target_yaw
				foot.swinging = false
				foot.episode += 1
		any_swing = any_swing or foot.swinging
	if not any_swing:
		var errors: Array[float] = []
		for pair: Vector2i in PAIRS:
			errors.append(maxf(feet[pair.x].anchor.distance_to(neutral[pair.x]), feet[pair.y].anchor.distance_to(neutral[pair.y])))
		if moving or maxf(errors[0], errors[1]) > 0.01:
			var pair_id: int = 1 - last_pair if moving else (0 if errors[0] >= errors[1] else 1)
			for index: int in [PAIRS[pair_id].x, PAIRS[pair_id].y]:
				var foot: Foot = feet[index]
				foot.swinging = true
				foot.elapsed = 0.0
				# Shorter steps during moving turns keep the hip from outrunning a
				# planted foot. Gameplay speed/collision remain owned by Player.
				foot.duration = clampf(28.0 / neutral_speed, 4.0 / 60.0, 7.0 / 60.0)
				if moving and not was_moving: foot.duration = 4.0 / 60.0
				foot.start = foot.anchor
				foot.target = foot.anchor
				foot.start_yaw = foot.yaw
				foot.target_yaw = yaw
			last_pair = pair_id
	var contacts: Array[Dictionary] = []
	var maximum_error: float = 0.0
	var settled: bool = true
	for index in range(4):
		var foot: Foot = feet[index]
		var point: Vector2 = foot.anchor
		var foot_yaw: float = foot.yaw
		var lift: float = 0.0
		if foot.swinging:
			var remaining: float = maxf(0.0, foot.duration - foot.elapsed)
			var horizon: float = remaining + foot.duration * 0.5 if moving else remaining
			var landing_yaw: float = yaw + clampf(_angle_delta(yaw, desired), -PI * horizon, PI * horizon)
			foot.target = position + velocity * (horizon if moving else 0.0) + projection * REST[index].rotated(landing_yaw)
			foot.target_yaw = landing_yaw
			var u: float = minf(1.0, foot.elapsed / foot.duration)
			var weight: float = u * u * (3.0 - 2.0 * u)
			point = foot.start.lerp(foot.target, weight)
			foot_yaw = foot.start_yaw + _angle_delta(foot.start_yaw, foot.target_yaw) * weight
			lift = 7.0 * pow(sin(PI * u), 2)
		var reach: float = point.distance_to(neutral[index])
		maximum_reach_px = maxf(maximum_reach_px, reach)
		maximum_error = maxf(maximum_error, reach)
		settled = settled and not foot.swinging
		var toe: Vector2 = projection * Vector2(0.16, 0).rotated(foot_yaw)
		contacts.append({"ankle": point, "yaw": foot_yaw, "lift": lift, "stance": not foot.swinging,
			"episode": foot.episode, "sole": point + toe - Vector2(0, 0.005 * height_scale + lift)})
	settled = settled and not moving and absf(_angle_delta(yaw, desired)) < 0.00001 and maximum_error < 0.02
	was_moving = moving
	return {"yaw": yaw, "feet": contacts, "moving": moving, "settled": settled,
		"breath": (0.5 - 0.5 * cos(PI * elapsed)) if settled else 0.0}


static func _angle_delta(from: float, to: float) -> float:
	return atan2(sin(to - from), cos(to - from))
