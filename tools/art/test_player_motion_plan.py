"""Small motion-planner regression: a swing target must not chase constant velocity."""

from player_motion_plan import plan, transform, rotate
import math

projection = [[48.0, 48.0], [28.0, -28.0]]
rows = []
for tick in range(40):
    rows.append({"tick": tick, "delta": 1/60, "position": [max(0, tick-4)*4, 0],
                 "motion": [4 if tick >= 5 else 0, 0], "facing": "right"})
result = plan({"rows": rows, "events": []}, projection, 56)
toe_neutral = transform(projection, rotate((.66+.16, .4), math.pi/4))
landings = []
for before, after in zip(result["timeline"], result["timeline"][1:]):
    a, b = before["contacts"][0], after["contacts"][0]
    if not a["stance"] and b["stance"]:
        lead = b["sole_world"][0] - after["position"][0] - toe_neutral[0]
        assert abs(lead - 12.0) < 1e-5, ("landing target chased movement", lead)
        landings.append(lead)
assert len(landings) >= 2
print("MOTION PLANNER REGRESSION PASSED: constant-velocity landing stays fixed through swing;", landings)
