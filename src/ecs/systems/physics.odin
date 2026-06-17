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

init_physics :: proc () {
    worldDef := b2.DefaultWorldDef();
    worldDef.gravity = {0,10};
    worldId = b2.CreateWorld(worldDef);
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

create_child :: proc(
    collider  : ^types.SquareCollider,
    c_transform : ^types.Transform,
    transform : ^types.Transform,
    rigid     : ^types.RigidBody,
    body_id   : b2.BodyId
) {
    fmt.println("create child")
    // Calculate the offset where the tool sits relative to the parent center
    // e.g., putting it slightly to the right of the parent body
    tool_offset := b2.Vec2{
        (c_transform.local_pos.x ) / PIXELS_PER_METER, 
        (c_transform.local_pos.y ) / PIXELS_PER_METER, 
    }

    // In Box2D v3, you can create an offset box using b2.MakeOffsetBox
    tool_box := b2.MakeOffsetBox(
        (c_transform.size.x + collider.size.x ) / 2 / PIXELS_PER_METER,
        (c_transform.size.y + collider.size.y ) / 2 / PIXELS_PER_METER,
        tool_offset,
        b2.Rot_identity, // No extra local rotation, or use b2.MakeRot(angle)
    )

    tool_shape_def := b2.DefaultShapeDef()
    tool_shape_def.density = 0.5 // Adjust weight of the tool
    tool_shape_def.enableContactEvents = true
    tool_shape_def.isSensor = false // Set to true if it's just a weapon trigger

    tool_shape_id := b2.CreatePolygonShape(body_id, tool_shape_def, tool_box)
    
    // You can map this shape to the rigid body too, 
    // or a different mapping if you need to detect tool hits specifically
    rigidbody_by_shape_id[tool_shape_id] = rigid
    shape_id_by_collider[collider] = tool_shape_id
    collider_by_shape_id[tool_shape_id] = collider
}

get_or_create_body :: proc(e: ^ecs.ECS,
                           entity: u32,
                           rigid : ^types.RigidBody,
                           collider: ^types.SquareCollider,
                           transform: ^types.Transform) -> b2.BodyId
{
                               
    id, ok := body_id_by_rigidbody[rigid]
    if !ok {
        body_def := b2.DefaultBodyDef();
        body_def.position = transform.pos/PIXELS_PER_METER
        body_def.type = b2.BodyType(rigid.type)
        
        if rigid.disable_gravity do body_def.gravityScale = 0
        if rigid.disable_rotation do body_def.fixedRotation = true
        body_def.linearDamping = rigid.linear_damping
        
        id = b2.CreateBody(worldId, body_def);
        b2.Body_SetTransform(id, transform.pos/PIXELS_PER_METER, get_rot(transform.rot))
        body_id_by_rigidbody[rigid] = id
        
        box := b2.MakeBox(
            ((transform.size.x + (collider != nil ? collider.size.x : 0)) / 2) / PIXELS_PER_METER,
            ((transform.size.y + (collider != nil ? collider.size.y : 0)) / 2) / PIXELS_PER_METER
        )

        shapeDef := b2.DefaultShapeDef() 
        shapeDef.density = 1
        shapeDef.enableContactEvents = (collider != nil);
        shapeDef.isSensor = (collider == nil)
        shapeId := b2.CreatePolygonShape(body_id_by_rigidbody[rigid], shapeDef, box);
        rigidbody_by_shape_id[shapeId] = rigid

        
        storage, _ := ecs.get_storage(e, ^types.SquareCollider)
        parent_storage, _ := ecs.get_storage(e, ^types.Parent)
        transform_storage, _ := ecs.get_storage(e, ^types.Transform)
        components := make([dynamic]^types.SquareCollider)
        for i in 0..<len(parent_storage.dense) {
            // if we have child

            if parent_storage.dense[i].entity == entity {

                child_entity := parent_storage.entities[i]
                comp := storage.dense[storage.sparse[child_entity]]
                trans := transform_storage.dense[storage.sparse[child_entity]]
                fmt.println(comp)
                create_child(comp, trans, transform, rigid, id);
            }
        }
        delete(components)
    }
    return id
}

handle_collision :: proc(events: b2.ContactEvents) {
    for i in 0..< events.beginCount {
        e := events.beginEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]

        ca, geta := collider_by_shape_id[e.shapeIdA]
        cb, getb := collider_by_shape_id[e.shapeIdB]
        if (geta && ca.trigger) || (getb && cb.trigger) do es.emit(es.Event_Trigger_Entered({ra,rb}))
        else do es.emit(es.Event_Collision_Entered({ra,rb}))
    }

    for i in 0..< events.endCount {
        e := events.endEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]
        ca, geta := collider_by_shape_id[e.shapeIdA]
        cb, getb := collider_by_shape_id[e.shapeIdB]
        if (geta && ca.trigger) || (getb && cb.trigger) do es.emit(es.Event_Trigger_Left({ra,rb}))
        else do es.emit(es.Event_Collision_Left({ra,rb}))
        // collision ended
    }

    for i in 0..< events.hitCount {
        e := events.hitEvents[i]
        ra := rigidbody_by_shape_id[e.shapeIdA]
        rb := rigidbody_by_shape_id[e.shapeIdB]
        ca, geta := collider_by_shape_id[e.shapeIdA]
        cb, getb := collider_by_shape_id[e.shapeIdB]
        if (geta && ca.trigger) || (getb && cb.trigger) do es.emit(es.Event_Trigger_Hit({ra,rb}))
        else do es.emit(es.Event_Collision_Hit({ra,rb}))
        // significant impact
    }
}

get_body_id :: proc(rigid: ^types.RigidBody) -> b2.BodyId {
    return body_id_by_rigidbody[rigid]
}

toggle_collider :: proc(collider: ^types.SquareCollider) {
    shape_id, found := shape_id_by_collider[collider]
    if !found do return
    
    filter := b2.Shape_GetFilter(shape_id)
    
    if !collider.disabled && !collider.trigger{
        // Restore your default collision bits 
        // (0xFFFF means collide with everything, or use your specific category bits)
        filter.maskBits = 0xFFFF 
    } else {
        // Setting maskBits to 0 effectively turns the collider off
        filter.maskBits = 0 
    }
    
    // Apply the updated filter back to the shape
    b2.Shape_SetFilter(shape_id, filter)
}


collider_system :: proc(ecs_: ^ecs.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    c_storage, ok := ecs.get_storage(ecs_, ^types.SquareCollider);
    if !ok do return;
    trans, ok2 := ecs.get_storage(ecs_, ^types.Transform)
    if !ok2 do return
    for i in 0..<len(c_storage.dense) {
        collider := c_storage.dense[i]
        // TODO handle collider toggle
        toggle_collider(collider);
        

        if collider.disabled do continue;
        entity := c_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        t := trans.dense[trans.sparse[int(entity)]]
        
        append(&renderer.commands, rn.Rectangle({t.pos, t.size+collider.size, t.rot, rn.get_color(0x00ff00ff), true}));
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
    handle_collision(events)

    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        physics_body := phys.dense[i];
        
        transform := trans.dense[trans.sparse[entity]];
        collider, has_component := storage.get_component(c_storage, entity);

        t := b2.Body_GetTransform(get_or_create_body(ecs_,entity, physics_body, collider, transform));

        transform.pos = t.p*PIXELS_PER_METER;
        transform.rot = b2.Rot_GetAngle(t.q)*math.DEG_PER_RAD
        
        // append(&renderer.commands, rn.Text({
        //     transform.pos-{100,80*2},
        //     24,
        //     0,
        //     fmt.tprintf("<%f, %f, %f>\n<%f,%f>",
        //                 transform.pos.x,
        //                 transform.pos.y,
        //                 transform.rot,
        //                 transform.size.x/2/PIXELS_PER_METER,
        //                 transform.size.y/2/PIXELS_PER_METER,

        //                )
        // }))
        append(&renderer.commands, rn.Rectangle({transform.pos, transform.size/2, transform.rot, rn.get_color(0x00ff00ff), false}));
    }
        
}
