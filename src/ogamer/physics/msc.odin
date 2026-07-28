package ogamer_physics;

import b2 "vendor:box2d"
import "core:math"

get_rot :: proc (rot: f32) -> b2.Rot {
    rot := rot * math.RAD_PER_DEG
    return b2.Rot({s=math.sin(rot), c=math.cos(rot)})
}

// TODO add
// 1. apply force
