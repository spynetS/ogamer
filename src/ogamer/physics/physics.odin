package ogamer_physics;

import b2 "vendor:box2d"
import "core:fmt"

PIXELS_PER_METER :: 50.0 // to sync better box2d physics with pixels
Entity :: u32
Vector2 :: [2]f32

PhysicsWorld :: struct {
    world_id: b2.WorldId,
    bodies: map[Entity]b2.BodyId, 
    shapes: map[b2.BodyId]b2.ShapeId
}

init_physics :: proc (world: ^PhysicsWorld) {
    worldDef := b2.DefaultWorldDef();
    world.world_id = b2.CreateWorld(worldDef);
}

deinit_physics :: proc (world: ^PhysicsWorld) {
    b2.DestroyWorld(world.world_id)
}

create_body  :: proc (world: ^PhysicsWorld,
                      entity: Entity,
                      type: b2.BodyType,
                      pos: Vector2,
                      rot: f32,
                      disable_gravity: bool,
                      disable_rotation: bool,
                     ) {

    if _, has := world.bodies[entity]; has {
        return
    }

    body_def := b2.DefaultBodyDef();
    body_def.position = pos/PIXELS_PER_METER
    body_def.type = type

    if disable_gravity  do body_def.gravityScale = 0
    if disable_rotation do body_def.fixedRotation = true
    //body_def.linearDamping = rigid.linear_damping

    id : = b2.CreateBody(world.world_id, body_def);
    b2.Body_SetTransform(id, pos/PIXELS_PER_METER, get_rot(rot))
    world.bodies[entity] = id
    fmt.println("INFO: ", entity, "created box2d body")
}

build_body_shape :: proc (world: ^PhysicsWorld,
                          body_id: b2.BodyId,
                          size: Vector2,
                          is_collider: bool,
                          is_trigger: bool,
                          density: f32 = 0
                         ) {
    // if the body has a shape we have to destroy the old one
    if old, has := world.shapes[body_id]; has {
        b2.DestroyShape(old, true);
    }
    box := b2.MakeBox(
        (size.x / 2) / PIXELS_PER_METER,
        (size.y / 2) / PIXELS_PER_METER
    )

    shapeDef := b2.DefaultShapeDef()
    shapeDef.density = density == 0 ? 1 : density
    shapeDef.enableContactEvents = (is_collider);
    shapeDef.enableSensorEvents = true
    shapeDef.isSensor = (is_collider ? is_trigger : true)
    shapeId := b2.CreatePolygonShape(body_id, shapeDef, box);

    world.shapes[body_id] = shapeId
    fmt.println("INFO: ", body_id, "created box2d shape ")
}


destroy_body :: proc () {}
