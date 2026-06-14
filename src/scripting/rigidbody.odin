package scripting;

import b2 "vendor:box2d"
import "../ecs"

// Body_ApplyForceToCenter :: proc "c" (bodyId: BodyId, force: [2]f32, wake: bool) ---
apply_force :: proc(rigid: ^ecs.RigidBody, force: [2]f32) {
    bodyId := ecs.body_id[rigid];
    b2.Body_ApplyForceToCenter(bodyId, force, true);
}
