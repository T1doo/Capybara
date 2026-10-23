"""Small world-anchored four-foot planner for the v004 representative sample.

Consumes actual Player displacement, including collisions. Rendering is offline;
this is an auditable sample pose plan, not a complete production animation system.
"""

import math

REST = [( .66, .40), (.66, -.40), (-.94, .40), (-.94, -.40)]
PAIRS = [(0, 3), (1, 2)]
AXES = {"down": (0, 1), "down_right": (1, 1), "right": (1, 0), "up_right": (1, -1),
        "up": (0, -1), "up_left": (-1, -1), "left": (-1, 0), "down_left": (-1, 1)}


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def mul(a, value):
    return (a[0] * value, a[1] * value)


def distance(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def rotate(p, angle):
    c, s = math.cos(angle), math.sin(angle)
    return (c * p[0] - s * p[1], s * p[0] + c * p[1])


def transform(matrix, p):
    return (matrix[0][0] * p[0] + matrix[0][1] * p[1], matrix[1][0] * p[0] + matrix[1][1] * p[1])


def inverse(matrix):
    a, b = matrix[0]
    c, d = matrix[1]
    determinant = a * d - b * c
    return ((d / determinant, -b / determinant), (-c / determinant, a / determinant))


def angle_delta(a, b):
    return math.atan2(math.sin(b - a), math.cos(b - a))


def plan(record, projection, height_scale):
    inv = inverse(projection)
    def heading(direction):
        p = transform(inv, AXES[direction])
        return math.atan2(p[1], p[0])
    yaw = heading(record["rows"][0]["facing"])
    actor = tuple(record["rows"][0]["position"])
    feet = [{"p": add(actor, transform(projection, rotate(rest, yaw))), "yaw": yaw,
             "swing": None, "episode": 0} for rest in REST]
    last_pair = 1
    was_moving = False
    cache, lookup, timeline = [], {}, []
    max_reach = 0
    for row in record["rows"]:
        tick, delta = row["tick"], row["delta"]
        actor = tuple(row["position"])
        velocity = mul(row["motion"], 1 / delta)
        moving = math.hypot(*row["motion"]) > .0001
        desired = heading(row["facing"])
        yaw += max(-math.pi * delta, min(math.pi * delta, angle_delta(yaw, desired)))
        neutral = [add(actor, transform(projection, rotate(rest, yaw))) for rest in REST]
        for index, foot in enumerate(feet):
            swing = foot["swing"]
            if swing and tick - swing["start"] >= swing["duration"]:
                foot["p"], foot["yaw"] = swing["to"], swing["to_yaw"]
                foot["swing"] = None
                foot["episode"] += 1
        if not any(foot["swing"] for foot in feet):
            errors = [max(distance(feet[i]["p"], neutral[i]) for i in pair) for pair in PAIRS]
            if moving or max(errors) > .01:
                pair_id = 1 - last_pair if moving else max(range(2), key=lambda i: errors[i])
                duration = 4 if moving and not was_moving else 7
                for index in PAIRS[pair_id]:
                    foot = feet[index]
                    foot["swing"] = {"start": tick, "from": foot["p"], "to": foot["p"],
                                     "from_yaw": foot["yaw"], "to_yaw": yaw, "duration": duration}
                last_pair = pair_id
        local, contacts = [], []
        for index, foot in enumerate(feet):
            swing, lift = foot["swing"], 0.0
            if swing:
                remaining = max(0, swing["duration"] - (tick - swing["start"])) / 60
                landing_yaw = yaw + max(-math.pi * remaining, min(math.pi * remaining, angle_delta(yaw, desired)))
                landing = add(add(actor, mul(velocity, (remaining + .05) if moving else 0)),
                              transform(projection, rotate(REST[index], landing_yaw)))
                swing["to"], swing["to_yaw"] = landing, landing_yaw
                u = min(1, (tick - swing["start"]) / swing["duration"])
                smooth = u * u * (3 - 2 * u)
                p = add(mul(swing["from"], 1 - smooth), mul(swing["to"], smooth))
                foot_yaw = swing["from_yaw"] + angle_delta(swing["from_yaw"], swing["to_yaw"]) * smooth
                lift = 7 * math.sin(math.pi * u) ** 2
            else:
                p, foot_yaw = foot["p"], foot["yaw"]
            model = rotate(transform(inv, (p[0] - actor[0], p[1] - actor[1])), -yaw)
            local.append([round(model[0], 4), round(model[1], 4), round(lift / height_scale, 4),
                          round(angle_delta(yaw, foot_yaw), 5)])
            toe = transform(projection, rotate((.16, 0), foot_yaw))
            contacts.append({"stance": swing is None, "episode": foot["episode"],
                             "sole_world": [p[0] + toe[0], p[1] + toe[1] - .005 * height_scale - lift]})
            max_reach = max(max_reach, distance(p, neutral[index]))
        dip = 0
        for event in record["events"]:
            u = (tick - event["tick"]) / 60 / .9
            if 0 <= u <= 1:
                dip = max(dip, math.sin(math.pi * u) ** 2)
        settled = (not moving and dip == 0 and abs(angle_delta(yaw, desired)) < 1e-6
                   and not any(foot["swing"] for foot in feet)
                   and max(distance(foot["p"], neutral[i]) for i, foot in enumerate(feet)) < .02)
        breathing = round((.5 - .5 * math.cos(2 * math.pi * tick / 120)) * 5) / 5 if settled else 0
        pose = {"yaw": round(math.atan2(math.sin(yaw), math.cos(yaw)), 5),
                "feet": local, "dip": round(dip, 4), "breath": breathing}
        key = repr(pose)
        if key not in lookup:
            lookup[key] = len(cache)
            cache.append(pose)
        timeline.append({"tick": tick, "pose": lookup[key], "position": row["position"],
                         "facing": row["facing"], "contacts": contacts})
        was_moving = moving
    return {"poses": cache, "timeline": timeline, "max_ankle_reach_px": max_reach,
            "projection": projection, "height_scale": height_scale,
            "limits": "recorded 64-second representative path; not all possible input/terrain combinations"}
