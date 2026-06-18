package systems;

import "core:fmt"
import "core:math"
import b2 "vendor:box2d"

import storage "../storage"
import rn "../../renderer"
import io "../../io/"
import "../types"
import ecs "../"
import es "../../event-system"


PIXELS_PER_METER :: 50.0

// TODO renames theise so they make sense
worldId               : b2.WorldId;
body_id_by_rigidbody  : map[^types.RigidBody]b2.BodyId;
rigidbody_by_shape_id : map[b2.ShapeId]^types.RigidBody; // TODO use collider component instead
shape_id_by_collider  : map[^types.SquareCollider]b2.ShapeId
collider_by_shape_id  : map[b2.ShapeId]^types.SquareCollider
body_id_by_collider  : map[^types.SquareCollider]b2.BodyId;

init_physics :: proc (e: ^ecs.ECS) {
    worldDef := b2.DefaultWorldDef();
    worldDef.gravity = {0,10};
    worldId = b2.CreateWorld(worldDef);

    //ecs.subscribe(e, added_component)
}

deinit_physics :: proc () {
    delete(body_id_by_rigidbody)
    delete(rigidbody_by_shape_id)
    delete(shape_id_by_collider)
    b2.DestroyWorld(worldId)
}

get_rot :: proc (rot: f32) -> b2.Rot {
    rot := rot * math.RAD_PER_DEG
    return b2.Rot({s=math.sin(rot), c=math.cos(rot)})
}


create_collider :: proc(rigid: ^types.RigidBody, collider: ^types.SquareCollider, child_t: ^types.Transform) {
    body_id, has_rigid := body_id_by_rigidbody[rigid];
    if !has_rigid do return // TODO maybe create body?
    
    shape_id, has_shape := shape_id_by_collider[collider];
    if has_shape {
        fmt.println("INFO: delete shape")
        b2.DestroyShape(shape_id,true)
        delete_key(&rigidbody_by_shape_id, shape_id)
        delete_key(&shape_id_by_collider, collider)
        delete_key(&body_id_by_collider, collider)
        delete_key(&collider_by_shape_id, shape_id)
    }

    
    offset := b2.Vec2({
        -child_t.local_pos.x / PIXELS_PER_METER,
        -child_t.local_pos.y / PIXELS_PER_METER
    })
    fmt.println("INFO: added shape with offset ", offset)
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

    shape_id = b2.CreatePolygonShape(body_id, shape_def, box)
    
    rigidbody_by_shape_id[shape_id] = rigid
    shape_id_by_collider[collider] = shape_id
    body_id_by_collider[collider] = body_id
    collider_by_shape_id[shape_id] = collider

}


create_body :: proc(e: ^ecs.ECS, ent: u32){
    transform, has_transform := ecs.get_component(e, ent, types.Transform)
    rigid, has_rigid := ecs.get_component(e, ent, types.RigidBody)
    collider, has_collider := ecs.get_component(e, ent, types.SquareCollider)

    if !has_rigid do return
    temp_id, exists := body_id_by_rigidbody[rigid]
    if exists do return

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
    shapeDef.isSensor = (!has_collider)
    shapeId := b2.CreatePolygonShape(body_id_by_rigidbody[rigid], shapeDef, box);
    rigidbody_by_shape_id[shapeId] = rigid
}

handle_collision :: proc(e: ^ecs.ECS, events: b2.ContactEvents) {
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


handle_trigger_collision :: proc(e: ^ecs.ECS, events: b2.SensorEvents) {
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



collider_system :: proc(ecs_: ^ecs.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    c_storage,_ := ecs.get_storage(ecs_, ^types.SquareCollider);
    trans,_ := ecs.get_storage(ecs_, ^types.Transform)
    for i in 0..<len(c_storage.dense) {
        collider := c_storage.dense[i]
        
        entity := c_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        t := trans.dense[trans.sparse[int(entity)]]

        toggle_collider(collider, t);
        
        if collider.disabled do continue;
        //append(&renderer.commands, rn.Rectangle({t.pos, t.size+collider.size, t.rot, rn.get_color(0x00ff00ff), true}));
    }
}


physics_system :: proc(ecs_: ^ecs.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := ecs.get_storage(ecs_, ^types.RigidBody)
    if !ok do return
    trans, ok2 := ecs.get_storage(ecs_, ^types.Transform)
    if !ok2 do return

    c_storage, c_ok := ecs.get_storage(ecs_, ^types.SquareCollider)
    if !c_ok do return

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
        if !has do create_body(ecs_, entity);
        
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
