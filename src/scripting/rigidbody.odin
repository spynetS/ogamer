package scripting;

import b2 "vendor:box2d"
import "../ecs/systems"
import "../types"

// Body_ApplyForceToCenter :: proc "c" (bodyId: BodyId, force: [2]f32, wake: bool) ---
apply_force :: proc(rigid: ^types.RigidBody, force: [2]f32) {
    bodyId := systems.body_id_by_rigidbody[rigid];
    b2.Body_ApplyForceToCenter(bodyId, force, true);
}





