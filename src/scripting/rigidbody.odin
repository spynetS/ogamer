package scripting;

import b2 "vendor:box2d"
import "../ecs/systems"
import "../types"

// Body_ApplyForceToCenter :: proc "c" (bodyId: BodyId, force: [2]f32, wake: bool) ---
apply_force :: proc(rigid: ^types.RigidBody, force: [2]f32, point:[2]f32={0,0} ) {
    bodyId := systems.body_id_by_rigidbody[rigid];
    b2.Body_ApplyForce(bodyId,force, point, true)
}

// Teleports a body to a world-space pixel position and clears its velocity.
// The physics system only mirrors box2d -> component, never the other way, so
// writing transform.pos alone gets overwritten each step; this pushes the move
// into box2d so it actually sticks (handy for respawns).
set_position :: proc(rigid: ^types.RigidBody, pos: types.Vector2) {
    if !rigid.created do return
    bodyId := systems.body_id_by_rigidbody[rigid];
    t := b2.Body_GetTransform(bodyId)
    b2.Body_SetTransform(bodyId, pos/systems.PIXELS_PER_METER, t.q)
    b2.Body_SetLinearVelocity(bodyId, {0,0})
}





