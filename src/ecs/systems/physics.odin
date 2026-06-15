package systems;

import "core:fmt"
import "core:math"
import b2 "vendor:box2d"

import storage "../storage"
import rn "../../renderer"
import io "../../io/"
import "../types"
import ecs "../"

PIXELS_PER_METER :: 50.0



worldId : b2.WorldId;
body_id : map[^types.RigidBody]b2.BodyId;

init_physics :: proc () {
    worldDef := b2.DefaultWorldDef();
    worldDef.gravity = {0,10};
    worldId = b2.CreateWorld(worldDef);
}

get_or_create_body :: proc(phy_body : ^types.RigidBody, transform: ^types.Transform) -> b2.BodyId {
    id, ok := body_id[phy_body]
    if !ok {
        body_def := b2.DefaultBodyDef();
        body_def.position = transform.pos/PIXELS_PER_METER
        body_def.type = b2.BodyType(phy_body.type)

        id = b2.CreateBody(worldId, body_def);
        body_id[phy_body] = id

        box := b2.MakeBox(
            (transform.size.x/2) / PIXELS_PER_METER,
            (transform.size.y/2) / PIXELS_PER_METER
        )
        shapeDef := b2.DefaultShapeDef() 
        shapeDef.density = 1    
        shapeId := b2.CreatePolygonShape(body_id[phy_body], shapeDef, box);
        
    }
    return id
}


physics_system :: proc(ecs_: ^ecs.ECS, io_handler: ^io.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := ecs.get_storage(ecs_, ^types.RigidBody)
    if !ok do return
    trans, ok2 := ecs.get_storage(ecs_, ^types.Transform)
    if !ok2 do return

    b2.World_Step(worldId, dt, 8);

    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        physics_body := phys.dense[i];
        
        transform := trans.dense[trans.sparse[entity]];


        t := b2.Body_GetTransform(get_or_create_body(physics_body, transform));

        transform.pos = t.p*PIXELS_PER_METER;
        transform.rot = b2.Rot_GetAngle(t.q)*math.DEG_PER_RAD

        append(&renderer.commands, rn.Text({
            transform.pos-{100,80*2},
            32,
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
