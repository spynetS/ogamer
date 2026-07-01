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


PIXELS_PER_METER :: 50.0 // to sync better box2d physics with pixels

// TODO if collider is disabled the rigidbody should'nt collide!

worldId               : b2.WorldId;
body_id_by_rigidbody  : map[^types.RigidBody]b2.BodyId;
shape_id_by_rigidbody  : map[^types.RigidBody]b2.ShapeId;
rigidbody_by_shape_id : map[b2.ShapeId]^types.RigidBody; // TODO use collider component instead
shape_id_by_collider  : map[^types.SquareCollider]b2.ShapeId
collider_by_shape_id  : map[b2.ShapeId]^types.SquareCollider
body_id_by_collider  : map[^types.SquareCollider]b2.BodyId;

init_physics :: proc (e: ^types.ECS) {
    worldDef := b2.DefaultWorldDef();
    worldDef.gravity = {0,10};
    worldId = b2.CreateWorld(worldDef);
    

}

deinit_physics :: proc () {
    delete(body_id_by_rigidbody)
    delete(rigidbody_by_shape_id)
    delete(shape_id_by_collider)
    delete(collider_by_shape_id)
    delete(body_id_by_collider)
    b2.DestroyWorld(worldId)
}

get_rot :: proc (rot: f32) -> b2.Rot {
    rot := rot * math.RAD_PER_DEG
    return b2.Rot({s=math.sin(rot), c=math.cos(rot)})
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
    
    box := b2.MakeBox(
        ((transform.size.x + (has_collider ? collider.size.x : 0)) / 2) / PIXELS_PER_METER,
        ((transform.size.y + (has_collider ? collider.size.y : 0)) / 2) / PIXELS_PER_METER
    )

    shapeDef := b2.DefaultShapeDef() 
    shapeDef.density = rigid.density == 0 ? 1 : rigid.density
    shapeDef.enableContactEvents = (has_collider);
    shapeDef.enableSensorEvents = true
    shapeDef.isSensor = (has_collider ? collider.trigger : true)
    shapeId := b2.CreatePolygonShape(body_id_by_rigidbody[rigid], shapeDef, box);
    rigidbody_by_shape_id[shapeId] = rigid
    shape_id_by_rigidbody[rigid] = shapeId
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
        
        es.emit(es.Event_Collision_Entered({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))
    }

    for i in 0..< events.endCount {
        e := events.endEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]

          ca := collider_by_shape_id[e.shapeIdA]
        cb := collider_by_shape_id[e.shapeIdB]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(es.Event_Collision_Left({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))
    }

    for i in 0..< events.hitCount {
        e := events.hitEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]
        
        ca := collider_by_shape_id[e.shapeIdA]
        cb := collider_by_shape_id[e.shapeIdB]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(es.Event_Collision_Hit({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))

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
        
        es.emit(es.Event_Trigger_Entered({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))

    }

    for i in 0..< events.endCount {
        e := events.endEvents[i]
        ra := rigidbody_by_shape_id[e.sensorShapeId]
        rb := rigidbody_by_shape_id[e.visitorShapeId]

        ca := collider_by_shape_id[e.sensorShapeId]
        cb := collider_by_shape_id[e.visitorShapeId]
        
        ea := c_storage.entity_by_comp[ca]
        eb := c_storage.entity_by_comp[cb]
        
        es.emit(es.Event_Trigger_Left({ra=ra, rb=rb, ca=ca, cb=cb, ea=ea, eb=eb}))
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
    // is_currently_sensor := b2.Shape_IsSensor(shape_id)

    // if collider.trigger != is_currently_sensor {
    //     rigid, body_id := rigidbody_by_shape_id[shape_id], body_id_by_collider[collider]

    //     b2.DestroyShape(shape_id,true)
    //     delete_key(&rigidbody_by_shape_id, shape_id)
    //     delete_key(&shape_id_by_collider, collider)
    //     delete_key(&body_id_by_collider, collider)
    //     delete_key(&collider_by_shape_id, shape_id)
        
    //     crebte_child(collider, c_transform, rigid, body_ib)
    // }

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
attach_child_collider :: proc(ecs_: ^types.ECS, entity: u32, collider: ^types.SquareCollider, t: ^types.Transform) {
    if _, has_shape := shape_id_by_collider[collider]; has_shape do return

    parent, has_parent := ecs.get_component(ecs_, entity, types.Parent)
    if !has_parent do return

    rigid, has_rigid := ecs.get_component(ecs_, parent.entity, types.RigidBody)
    if !has_rigid do return

    // Parent body must already exist (created by physics_system earlier this frame).
    if _, has_body := body_id_by_rigidbody[rigid]; !has_body do return

    create_collider(rigid, collider, t)
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
        append(&renderer.commands, rn.Rectangle({t.pos, t.size+collider.size, t.rot, rn.get_color(0x00ff00ff), true}));
    }
}


physics_system :: proc(ecs_: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := ecs.get_storage(ecs_, ^types.RigidBody)
    trans, ok2 := ecs.get_storage(ecs_, ^types.Transform)
    c_storage, c_ok := ecs.get_storage(ecs_, ^types.SquareCollider)
    if !ok || !ok2 || !c_ok do return

    b2.World_Step(worldId, dt, 8);
    
    events := b2.World_GetContactEvents(worldId);
    handle_collision(ecs_,events)
    
    sensor_events := b2.World_GetSensorEvents(worldId);
    handle_trigger_collision(ecs_, sensor_events)

    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        physics_body := phys.dense[i];
        
        transform := trans.dense[trans.sparse[entity]];
        collider, has_component := storage.get_component(c_storage, entity);

        id, has := body_id_by_rigidbody[physics_body];
        if !has {
            create_body(ecs_, entity);
            id = body_id_by_rigidbody[physics_body]; 
        }


        t := b2.Body_GetTransform(id);

        transform.pos = t.p*PIXELS_PER_METER;
        transform.rot = b2.Rot_GetAngle(t.q)*math.DEG_PER_RAD
        
        append(&renderer.commands, rn.Text({
            transform.pos-{100,80*2},
            18,
            0,
            fmt.tprintf("<%.1f, %.1f, %.1f>\n<%.1f,%.1f>",
                        transform.pos.x,
                        transform.pos.y,
                        transform.rot,
                        transform.size.x/2/PIXELS_PER_METER,
                        transform.size.y/2/PIXELS_PER_METER,

                       )
        }))
        append(&renderer.commands, rn.Rectangle({transform.pos, transform.size/2, transform.rot, rn.get_color(0x00ff00ff), false}));
    }
        
}
