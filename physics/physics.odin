package ogamer_physics;

import b2 "vendor:box2d"
import "core:fmt"

PIXELS_PER_METER :: 50.0 // to sync better box2d physics with pixels
Entity :: u32
Vector2 :: [2]f32

PhysicsWorld :: struct {
    world_id: b2.WorldId,
    bodies: map[Entity]b2.BodyId, 
    shapes: map[Entity]b2.ShapeId,
    entites_by_shape: map[b2.ShapeId]Entity
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
                      linear_damping:f32,
                      disable_gravity: bool,
                      disable_rotation: bool,
                     ) {

    if _, has := world.bodies[entity]; has {
        return
    }

    fmt.println("CREATED PHYSICS BODY")

    body_def := b2.DefaultBodyDef();
    body_def.position = pos/PIXELS_PER_METER
    body_def.type = type

    if disable_gravity  do body_def.gravityScale = 0
    if disable_rotation do body_def.fixedRotation = true
    //body_def.linearDamping = rigid.linear_damping
    body_def.linearDamping = linear_damping
    
    id : = b2.CreateBody(world.world_id, body_def);
    b2.Body_SetTransform(id, pos/PIXELS_PER_METER, get_rot(rot))
    world.bodies[entity] = id
    fmt.println("INFO: ", entity, "created box2d body")
}

build_body_shape :: proc (world: ^PhysicsWorld,
                          entity: Entity,
                          body_id: b2.BodyId,
                          local_pos: Vector2,
                          size: Vector2,
                          is_collider: bool,
                          is_trigger: bool,
                          density: f32 = 1
                         ) {
    // if the body has a shape we have to destroy the old one

    if old, has := world.shapes[entity]; has {
        b2.DestroyShape(old, true);
    }

    local := b2.Vec2{
        local_pos.x / PIXELS_PER_METER,
        local_pos.y / PIXELS_PER_METER,
    }
    
    box := b2.MakeOffsetBox(
        (size.x / 2) / PIXELS_PER_METER,
        (size.y / 2) / PIXELS_PER_METER,
        local,
        b2.Rot_identity,
    )

    shapeDef := b2.DefaultShapeDef()
    shapeDef.density = density
    shapeDef.enableContactEvents = is_collider;
    shapeDef.enableSensorEvents = is_trigger
    shapeDef.isSensor = (is_collider ? is_trigger : true)
    shapeId := b2.CreatePolygonShape(body_id, shapeDef, box);

    world.shapes[entity] = shapeId
    world.entites_by_shape[shapeId] = entity
    fmt.println("INFO: ", body_id, "created box2d shape ")
}

destroy_body :: proc (world: ^PhysicsWorld, entity: Entity) -> bool {
    fmt.println("DESTROYING b2 BODY:", entity)
    if old, has := world.bodies[entity]; has {
        destroy_shape(world, entity)
        delete_key(&world.bodies, entity)
        b2.DestroyBody(old)
        return true
    }
    return false
}


destroy_shape :: proc (world: ^PhysicsWorld, entity: Entity) -> bool {
    fmt.println("DESTROYING b2 SHAPE:", entity)
    if old, has := world.shapes[entity]; has {
        delete_key(&world.entites_by_shape, old)
        delete_key(&world.shapes, entity)
        b2.DestroyShape(old, true)
        return true
    }
    return false;
}
