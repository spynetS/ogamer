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



worldId  : b2.WorldId;
body_id  : map[^types.RigidBody]b2.BodyId;
shape_id : map[b2.ShapeId]^types.RigidBody; // TODO use collider component instead

init_physics :: proc () {
    worldDef := b2.DefaultWorldDef();
    worldDef.gravity = {0,10};
    worldId = b2.CreateWorld(worldDef);
}

deinit_physics :: proc () {
    delete(body_id)
    b2.DestroyWorld(worldId)
}

get_or_create_body :: proc(rigid : ^types.RigidBody, transform: ^types.Transform) -> b2.BodyId {
    id, ok := body_id[rigid]
    if !ok {
        body_def := b2.DefaultBodyDef();
        body_def.position = transform.pos/PIXELS_PER_METER
        body_def.type = b2.BodyType(rigid.type)

        if rigid.disable_gravity do body_def.gravityScale = 0
        body_def.linearDamping = rigid.linear_damping

        id = b2.CreateBody(worldId, body_def);
        body_id[rigid] = id

        // TODO create shape based on collider component
        box := b2.MakeBox(
            (transform.size.x/2) / PIXELS_PER_METER,
            (transform.size.y/2) / PIXELS_PER_METER
        )

        shapeDef := b2.DefaultShapeDef() 
        shapeDef.density = 1
        shapeDef.enableContactEvents = true;
        shapeId := b2.CreatePolygonShape(body_id[rigid], shapeDef, box);
        shape_id[shapeId] = rigid
        
    }
    return id
}

handle_collision :: proc(events: b2.ContactEvents) {
    for i in 0..< events.beginCount {
        //b2ContactBeginTouchEvent* e = events.beginEvents + i;
        e := events.beginEvents[i]
        ra := shape_id[e.shapeIdA]
        rb := shape_id[e.shapeIdB]
        es.emit(es.Event_Collision_Entered({ra,rb}))
    }

    for i in 0..< events.endCount {
        //b2ContactEndTouchEvent* e = events.endEvents + i;
        e := events.endEvents[i]
        ra := shape_id[e.shapeIdA]
        rb := shape_id[e.shapeIdB]
        es.emit(es.Event_Collision_Left({ra,rb}))
        // collision ended
    }

    for i in 0..< events.hitCount {
        //b2ContactHitEvent* e = events.hitEvents + i;
        e := events.hitEvents[i]
        ra := shape_id[e.shapeIdA]
        rb := shape_id[e.shapeIdB]
        es.emit(es.Event_Collision_Hit({ra,rb}))
        // significant impact
    }
}

physics_system :: proc(ecs_: ^ecs.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := ecs.get_storage(ecs_, ^types.RigidBody)
    if !ok do return
    trans, ok2 := ecs.get_storage(ecs_, ^types.Transform)
    if !ok2 do return

    b2.World_Step(worldId, dt, 8);
    events := b2.World_GetContactEvents(worldId);
    handle_collision(events)

    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        physics_body := phys.dense[i];
        
        transform := trans.dense[trans.sparse[entity]];

        t := b2.Body_GetTransform(get_or_create_body(physics_body, transform));

        transform.pos = t.p*PIXELS_PER_METER;
        transform.rot = b2.Rot_GetAngle(t.q)*math.DEG_PER_RAD

        append(&renderer.commands, rn.Text({
            transform.pos-{100,80*2},
            24,
            0,
            fmt.tprintf("<%f, %f, %f>\n<%f,%f>",
                        transform.pos.x,
                        transform.pos.y,
                        transform.rot,
                        transform.size.x/2/PIXELS_PER_METER,
                        transform.size.y/2/PIXELS_PER_METER,

                       )
        }))

    }
        
}
