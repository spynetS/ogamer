package systems;

import "core:fmt"
import "core:math"
import b2 "vendor:box2d"

import storage "../storage"
import rn "../../renderer"
import io "../../io/"
import "../../types"
import ecs "../"
import es "../../event-system"

RENDER :: true
PIXELS_PER_METER :: 50.0 // to sync better box2d physics with pixels

// TODO if collider is disabled the rigidbody should'nt collide!
// TODO if transform position is changed in my component it should change in box2d
worldId               : b2.WorldId;
body_id_by_rigidbody  : map[^types.RigidBody]b2.BodyId;
shape_id_by_rigidbody  : map[^types.RigidBody]b2.ShapeId;
rigidbody_by_shape_id : map[b2.ShapeId]^types.RigidBody; // TODO use collider component instead
shape_id_by_collider  : map[^types.SquareCollider]b2.ShapeId
collider_by_shape_id  : map[b2.ShapeId]^types.SquareCollider
body_id_by_collider  : map[^types.SquareCollider]b2.BodyId;
// The box inputs {offset.x, offset.y, width, height} last used to build a child
// collider's shape. Lets us rebuild only when the child transform changes.
child_collider_params : map[^types.SquareCollider][4]f32
// The box inputs {width, height} last used to build a body's own main shape.
// Lets us rebuild only when the body's own transform/collider size changes.
body_shape_params : map[^types.RigidBody][2]f32
// The linear velocity (px/s) last mirrored from box2d onto a rigidbody. Lets us
// tell an external write (user set velocity) apart from box2d's own simulation.
last_velocity : map[^types.RigidBody]types.Vector2
// Same idea for angular velocity (degrees/sec).
last_angular_velocity : map[^types.RigidBody]f32

init_physics :: proc (e: ^types.ECS) {
    worldDef := b2.DefaultWorldDef();
    worldId = b2.CreateWorld(worldDef);

    // Tear down box2d objects when their components are destroyed.
    ecs.on_rigidbody_removed = destroy_rigidbody
    ecs.on_collider_removed  = destroy_collider
}

deinit_physics :: proc () {
    delete(body_id_by_rigidbody)
    delete(rigidbody_by_shape_id)
    delete(shape_id_by_collider)
    delete(collider_by_shape_id)
    delete(body_id_by_collider)
    delete(child_collider_params)
    delete(body_shape_params)
    delete(last_velocity)
    delete(last_angular_velocity)
    b2.DestroyWorld(worldId)
}

get_rot :: proc (rot: f32) -> b2.Rot {
    rot := rot * math.RAD_PER_DEG
    return b2.Rot({s=math.sin(rot), c=math.cos(rot)})
}

// Destroys the box2d body owned by a rigidbody and purges every map entry tied
// to it. b2.DestroyBody also destroys all shapes on the body (its own main
// shape plus any child colliders riding on it), so we drop that bookkeeping too.
destroy_rigidbody :: proc(rigid: ^types.RigidBody) {
    body_id, has := body_id_by_rigidbody[rigid]
    if !has do return

    // Collect colliders on this body first; deleting while ranging a map is unsafe.
    doomed : [dynamic]^types.SquareCollider
    defer delete(doomed)
    for collider, b in body_id_by_collider {
        if b == body_id do append(&doomed, collider)
    }
    for collider in doomed {
        if shape, ok := shape_id_by_collider[collider]; ok {
            delete_key(&collider_by_shape_id, shape)
        }
        delete_key(&shape_id_by_collider, collider)
        delete_key(&body_id_by_collider, collider)
        delete_key(&child_collider_params, collider)
    }

    if shape, ok := shape_id_by_rigidbody[rigid]; ok {
        delete_key(&rigidbody_by_shape_id, shape)
    }

    b2.DestroyBody(body_id)

    delete_key(&body_id_by_rigidbody, rigid)
    delete_key(&shape_id_by_rigidbody, rigid)
    delete_key(&body_shape_params, rigid)
    delete_key(&last_velocity, rigid)
    delete_key(&last_angular_velocity, rigid)
}

// Destroys the box2d shape backing a single collider (typically a child
// collider riding on an ancestor's body). No-op if it has no live shape --
// e.g. when its owning body was already torn down by destroy_rigidbody.
destroy_collider :: proc(collider: ^types.SquareCollider) {
    shape, has := shape_id_by_collider[collider]
    if !has do return

    // If this shape is actually the body's own main fixture (collider sits on
    // the same entity as the rigidbody), leave it to destroy_rigidbody; ripping
    // it out here would leave the body shapeless.
    if rigid, ok := rigidbody_by_shape_id[shape]; ok {
        if main, ok2 := shape_id_by_rigidbody[rigid]; ok2 && main == shape {
            return
        }
    }

    b2.DestroyShape(shape, true)
    delete_key(&rigidbody_by_shape_id, shape)
    delete_key(&collider_by_shape_id, shape)
    delete_key(&shape_id_by_collider, collider)
    delete_key(&body_id_by_collider, collider)
    delete_key(&child_collider_params, collider)
}


create_collider :: proc(rigid: ^types.RigidBody, collider: ^types.SquareCollider, child_t: ^types.Transform) {
    body_id, has_rigid := body_id_by_rigidbody[rigid];
    if !has_rigid do return // TODO maybe create body?

    // Recreate only if THIS collider already owns a shape. A body can own
    // many shapes (its own fixture + each child collider), so keying off the
    // body would wrongly destroy/unregister the parent's main shape.
    if old_shape, has_shape := shape_id_by_collider[collider]; has_shape {
        b2.DestroyShape(old_shape, true)
        delete_key(&rigidbody_by_shape_id, old_shape)
        delete_key(&collider_by_shape_id, old_shape)
        delete_key(&shape_id_by_collider, collider)
        delete_key(&body_id_by_collider, collider)
    }

    // Child-local offset in the body frame (body origin = parent center).
    // Positive, to match parent_system which draws the child at +local_pos.
    offset := b2.Vec2({
        child_t.local_pos.x / PIXELS_PER_METER,
        child_t.local_pos.y / PIXELS_PER_METER
    })
    box := b2.MakeOffsetBox(
        (child_t.size.x + collider.size.x) / 2 / PIXELS_PER_METER,
        (child_t.size.y + collider.size.y) / 2 / PIXELS_PER_METER,
        offset,
        b2.Rot_identity
    )

    shape_def := b2.DefaultShapeDef()
    shape_def.density = 0.5
    shape_def.enableContactEvents = true
    shape_def.enableSensorEvents = true
    shape_def.isSensor = collider.trigger // Set to true if it's just a weapon trigger

    shape_id := b2.CreatePolygonShape(body_id, shape_def, box)

    rigidbody_by_shape_id[shape_id] = rigid
    shape_id_by_collider[collider] = shape_id
    body_id_by_collider[collider] = body_id
    collider_by_shape_id[shape_id] = collider

}


create_body :: proc(e: ^types.ECS, ent: u32){
    transform, has_transform := ecs.get_component(e, ent, types.Transform)
    rigid, has_rigid := ecs.get_component(e, ent, types.RigidBody)
    collider, has_collider := ecs.get_component(e, ent, types.SquareCollider)

    // no rigidbody skip
    if !has_rigid do return
    // if its created skip
    temp_id, exists := body_id_by_rigidbody[rigid]
    if exists do return
    fmt.println("INFO: creating box2d body")

    
    body_def := b2.DefaultBodyDef();
    body_def.position = transform.pos/PIXELS_PER_METER
    body_def.type = b2.BodyType(rigid.type)
    
    if rigid.disable_gravity do body_def.gravityScale = 0
    if rigid.disable_rotation do body_def.fixedRotation = true
    body_def.linearDamping = rigid.linear_damping
    
    id := b2.CreateBody(worldId, body_def);
    b2.Body_SetTransform(id, transform.pos/PIXELS_PER_METER, get_rot(transform.rot))
    body_id_by_rigidbody[rigid] = id

    build_body_shape(id, rigid, transform, collider, has_collider)
}

body_box_params :: proc(transform: ^types.Transform, collider: ^types.SquareCollider, has_collider: bool) -> [2]f32 {
    return {
        transform.size.x + (has_collider ? collider.size.x : 0),
        transform.size.y + (has_collider ? collider.size.y : 0),
    }
}

// (Re)builds the body's own main fixture and registers it in the lookup maps.
// Destroys the previous main shape first so the geometry tracks the body's
// transform/collider size instead of being frozen at creation time.
build_body_shape :: proc(
    id: b2.BodyId,
    rigid: ^types.RigidBody,
    transform: ^types.Transform,
    collider: ^types.SquareCollider,
    has_collider: bool,
) {
    if old, has := shape_id_by_rigidbody[rigid]; has {
        b2.DestroyShape(old, true)
        delete_key(&rigidbody_by_shape_id, old)
        delete_key(&collider_by_shape_id, old)
    }

    box := b2.MakeBox(
        ((transform.size.x + (has_collider ? collider.size.x : 0)) / 2) / PIXELS_PER_METER,
        ((transform.size.y + (has_collider ? collider.size.y : 0)) / 2) / PIXELS_PER_METER
    )

    shapeDef := b2.DefaultShapeDef()
    shapeDef.density = rigid.density == 0 ? 1 : rigid.density
    shapeDef.enableContactEvents = (has_collider);
    shapeDef.enableSensorEvents = true
    shapeDef.isSensor = (has_collider ? collider.trigger : true)
    shapeId := b2.CreatePolygonShape(id, shapeDef, box);
    rigidbody_by_shape_id[shapeId] = rigid
    shape_id_by_rigidbody[rigid] = shapeId

    if has_collider {
        shape_id_by_collider[collider] = shapeId
        body_id_by_collider[collider] = id
        collider_by_shape_id[shapeId] = collider
    }

    body_shape_params[rigid] = body_box_params(transform, collider, has_collider)
}

handle_collision :: proc(e: ^types.ECS, events: b2.ContactEvents) {
    c_storage, _ := ecs.get_storage(e,^types.SquareCollider)
    
    for i in 0..< events.beginCount {
        e := events.beginEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]

        ca := collider_by_shape_id[e.shapeIdA]
        cb := collider_by_shape_id[e.shapeIdB]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(types.Event_Collision_Entered({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))
    }

    for i in 0..< events.endCount {
        e := events.endEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]

        ca := collider_by_shape_id[e.shapeIdA]
        cb := collider_by_shape_id[e.shapeIdB]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(types.Event_Collision_Left({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))
    }

    for i in 0..< events.hitCount {
        e := events.hitEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]
        
        ca := collider_by_shape_id[e.shapeIdA]
        cb := collider_by_shape_id[e.shapeIdB]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(types.Event_Collision_Hit({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))

    }
}


handle_trigger_collision :: proc(e: ^types.ECS, events: b2.SensorEvents) {
    c_storage, _ := ecs.get_storage(e,^types.SquareCollider)
    for i in 0..< events.beginCount {
        e := events.beginEvents[i]
        ra := rigidbody_by_shape_id[e.sensorShapeId]
        rb := rigidbody_by_shape_id[e.visitorShapeId]

        ca := collider_by_shape_id[e.sensorShapeId]
        cb := collider_by_shape_id[e.visitorShapeId]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(types.Event_Trigger_Entered({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))

    }

    for i in 0..< events.endCount {
        e := events.endEvents[i]
        ra := rigidbody_by_shape_id[e.sensorShapeId]
        rb := rigidbody_by_shape_id[e.visitorShapeId]

        ca := collider_by_shape_id[e.sensorShapeId]
        cb := collider_by_shape_id[e.visitorShapeId]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(types.Event_Trigger_Left({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))
    }

}

get_body_id :: proc(rigid: ^types.RigidBody) -> b2.BodyId {
    return body_id_by_rigidbody[rigid]
}

toggle_collider :: proc(
    collider: ^types.SquareCollider,
    c_transform: ^types.Transform
) {
    shape_id, found := shape_id_by_collider[collider]
    if !found do return
  
    if collider.disabled {
        filter := b2.Shape_GetFilter(shape_id)
        filter.maskBits = 0 
        b2.Shape_SetFilter(shape_id, filter)
        return
    }
    else {
        filter := b2.Shape_GetFilter(shape_id)
        if filter.maskBits == 0 {
            filter.maskBits = 0xFFFF
            b2.Shape_SetFilter(shape_id, filter)
        }
    }
}



// Attaches a child's SquareCollider to its parent's Box2D body as a shape, the
// first time we see that collider. Mirrors Unity: a collider on a child
// GameObject rides on the nearest ancestor's Rigidbody.
child_box_params :: proc(collider: ^types.SquareCollider, t: ^types.Transform) -> [4]f32 {
    return {
        t.local_pos.x,
        t.local_pos.y,
        t.size.x + collider.size.x,
        t.size.y + collider.size.y,
    }
}

attach_child_collider :: proc(ecs_: ^types.ECS, entity: u32, collider: ^types.SquareCollider, t: ^types.Transform) {
    params := child_box_params(collider, t)

    // Already attached: rebuild the shape only if the child transform changed,
    // otherwise it keeps a stale offset/size when the child moves or scales.
    if _, has_shape := shape_id_by_collider[collider]; has_shape {
        if cached, ok := child_collider_params[collider]; ok && cached == params do return
    }

    parent, has_parent := ecs.get_component(ecs_, entity, types.Parent)
    if !has_parent do return

    rigid, has_rigid := ecs.get_component(ecs_, parent.entity, types.RigidBody)
    if !has_rigid do return

    // Parent body must already exist (created by physics_system earlier this frame).
    if _, has_body := body_id_by_rigidbody[rigid]; !has_body do return

    create_collider(rigid, collider, t)
    child_collider_params[collider] = params
}

collider_system :: proc(ecs_: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    c_storage,_ := ecs.get_storage(ecs_, ^types.SquareCollider);
    trans,_ := ecs.get_storage(ecs_, ^types.Transform)
    for i in 0..<len(c_storage.dense) {
        collider := c_storage.dense[i]

        entity := c_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        t := trans.dense[trans.sparse[int(entity)]]

        attach_child_collider(ecs_, entity, collider, t)

        toggle_collider(collider, t);

        if collider.disabled do continue;

        // Draw the actual box2d shape (not the ecs transform/collider size),
        // so this reflects what box2d is really colliding against.
        if RENDER {
            shape_id, has_shape := shape_id_by_collider[collider]
            if !has_shape do continue

            body_id := b2.Shape_GetBody(shape_id)
            body_t := b2.Body_GetTransform(body_id)
            poly := b2.Shape_GetPolygon(shape_id)

            min_v := poly.vertices[0]
            max_v := poly.vertices[0]
            for j in 1..<int(poly.count) {
                v := poly.vertices[j]
                min_v.x = min(min_v.x, v.x); min_v.y = min(min_v.y, v.y)
                max_v.x = max(max_v.x, v.x); max_v.y = max(max_v.y, v.y)
            }
            size := (max_v - min_v) * PIXELS_PER_METER
            world_center := b2.TransformPoint(body_t, poly.centroid) * PIXELS_PER_METER
            rot := b2.Rot_GetAngle(body_t.q) * math.DEG_PER_RAD

            append(&renderer.debug_commands, rn.Rectangle({world_center, size, rot, rn.get_color(0x00ff00ff), true,0}));
            append(&renderer.debug_commands, rn.Text({
                world_center,
                18,
                0,
                fmt.tprintf("<%d>",entity),
                rn.get_color(0),
                0
            }))
        }
    }
}


physics_system :: proc(ecs_: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := ecs.get_storage(ecs_, ^types.RigidBody)
    trans, ok2 := ecs.get_storage(ecs_, ^types.Transform)
    c_storage, c_ok := ecs.get_storage(ecs_, ^types.SquareCollider)
    if !ok || !ok2 || !c_ok do return

    // --- pre-step: create/rebuild bodies and push component values the user
    //     changed this frame into box2d (so the step uses them) ---
    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        physics_body := phys.dense[i];

        transform := trans.dense[trans.sparse[entity]];
        collider, has_component := storage.get_component(c_storage, entity);

        id, has := body_id_by_rigidbody[physics_body];
        if !has {
            create_body(ecs_, entity);
            id, has = body_id_by_rigidbody[physics_body];
            if !has do continue
        } else {
            // Rebuild the body's own shape if its transform/collider size changed.
            params := body_box_params(transform, collider, has_component)
            if cached, ok := body_shape_params[physics_body]; !ok || cached != params {
                build_body_shape(id, physics_body, transform, collider, has_component)
            }
        }

        // Two-way velocity bind: if the component's velocity no longer matches
        // what we last mirrored out of box2d, the user set it -> push it in.
        // box2d works in m/s, the component in px/s, hence PIXELS_PER_METER.
        if cached, ok := last_velocity[physics_body]; !ok || cached != physics_body.velocity {
            b2.Body_SetLinearVelocity(id, physics_body.velocity/PIXELS_PER_METER)
        }
        // Same for angular velocity; component is deg/s, box2d is rad/s.
        if cached, ok := last_angular_velocity[physics_body]; !ok || cached != physics_body.angular_velocity {
            b2.Body_SetAngularVelocity(id, physics_body.angular_velocity*math.RAD_PER_DEG)
        }
        // Acceleration is a continuous input: apply it as a force every step
        // (F = m*a). Component is px/s^2, box2d wants Newtons in m/s^2. Guard the
        // zero case so we don't keep waking resting bodies for no reason.
        if physics_body.acceleration != {0, 0} {
            mass := b2.Body_GetMass(id)
            b2.Body_ApplyForceToCenter(id, physics_body.acceleration/PIXELS_PER_METER*mass, true)
        }
    }

    b2.World_Step(worldId, dt, 8);

    events := b2.World_GetContactEvents(worldId);
    handle_collision(ecs_,events)

    sensor_events := b2.World_GetSensorEvents(worldId);
    handle_trigger_collision(ecs_, sensor_events)

    // --- post-step: mirror the simulated box2d state back onto the components ---
    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        physics_body := phys.dense[i];

        transform := trans.dense[trans.sparse[entity]];

        id, has := body_id_by_rigidbody[physics_body];
        if !has do continue

        t := b2.Body_GetTransform(id);

        transform.pos = t.p*PIXELS_PER_METER;
        transform.rot = b2.Rot_GetAngle(t.q)*math.DEG_PER_RAD

        v := b2.Body_GetLinearVelocity(id)*PIXELS_PER_METER
        physics_body.velocity = v
        last_velocity[physics_body] = v

        w := b2.Body_GetAngularVelocity(id)*math.DEG_PER_RAD
        physics_body.angular_velocity = w
        last_angular_velocity[physics_body] = w

        append(&renderer.debug_commands, rn.Text({
            transform.pos-{100,80*2},
            18,
            0,
            fmt.tprintf("<%.1f, %.1f, %.1f>\n<%.1f,%.1f>",
                        transform.pos.x,
                        transform.pos.y,
                        transform.rot,
                        transform.size.x/2/PIXELS_PER_METER,
                        transform.size.y/2/PIXELS_PER_METER,

                       ),
            rn.get_color(0),
            0
        }))
        append(&renderer.debug_commands, rn.Rectangle({transform.pos, transform.size/4, transform.rot, rn.get_color(0x00ff00ff), false,0}));
    }
    
}
