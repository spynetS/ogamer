package ogamer_ecs;

import "core:fmt"
import "core:math"
import b2 "vendor:box2d"
import rn "../renderer/"
import  "../io/"
import  "../events/"
import  "../input/"
import  "../physics/"

shape_render_system :: proc(data: SystemData, dt: f32) {
    s_storage,ok := get_storage(data.ecs, ShapeRenderer)
    t_storage,ok2 := get_storage(data.ecs, Transform)
    if !ok || !ok2 do return
    
    for i in 0..<len(s_storage.dense) {
        s := s_storage.dense[i]
        entity := s_storage.entities[i]
        t := t_storage.dense[t_storage.sparse[entity]]
        if data.renderer == nil do continue
        rn.add_command(data.renderer, rn.Rectangle({t.pos,t.size,0, rn.get_color(0xffffffff), false, 0}))
    }
}

sprite_render_system :: proc(data: SystemData, dt: f32) {
    t_storage, ok := get_storage(data.ecs, Transform)
    s_storage, ok2 := get_storage(data.ecs, SpriteRenderer)
    if !ok || !ok2 do return

    for i in 0..<len(s_storage.dense) {
        s := s_storage.dense[i]
        entity := s_storage.entities[i]
        if int(entity) > len(t_storage.sparse) do continue
        t := t_storage.dense[t_storage.sparse[entity]]
        
        if data.renderer == nil do continue

        if data.renderer.active_camera != nil && s.parallax != {1,1} {
            s.offset = data.renderer.active_camera.target * (s.parallax)
        }


        rn.add_command(data.renderer, rn.Sprite({t.pos,s.offset, t.size, t.rot, s.inverted, s.sprite, s.layer, s.repeated_x, s.repeated_y}))
    }
}

script_system :: proc(data: SystemData, dt: f32) {
    t_storage,ok := get_storage(data.ecs, Transform)
    s_storage,ok2 := get_storage(data.ecs, ScriptComponent)
    if !ok || !ok2 do return

    for i in 0..<len(s_storage.dense) {
        s := s_storage.dense[i]
        entity := s_storage.entities[i]
        if int(entity) > len(t_storage.sparse) do continue
        t := &t_storage.dense[t_storage.sparse[entity]]

        go := GameObject({
            entity = entity,
            ecs = data.ecs,
            transform = t,
        })

        for script in s.scripts {
            data := ScriptData({
                data=script.data,
                gameObject = go,
                ecs=data.ecs,
                eventQueue = data.eventQueue,
                world = data.ecs.world,
                dt=dt
            })
            if script.update != nil do script.update(data)

            for event in events.event_queue_poll(data.eventQueue) {
                #partial switch v in event {
                    case events.Collision_Entered:
                    // box2d's shapeIdA/B ordering is arbitrary, so match either side.
                    if v.ea != go.entity && v.eb != go.entity do break
                    other := get_gameobject(data.ecs, v.ea == go.entity ? v.eb : v.ea);
                    if script.on_collision_enter != nil do script.on_collision_enter(data, other)

                    case events.Collision_Left:
                    if v.ea != go.entity && v.eb != go.entity do break
                    other := get_gameobject(data.ecs, v.ea == go.entity ? v.eb : v.ea);
                    if script.on_collision_left != nil do script.on_collision_left(data, other)

                    case events.Trigger_Entered:
                    if v.ea != go.entity && v.eb != go.entity do break
                    other_id := v.eb
                    other := get_gameobject(data.ecs, v.ea == go.entity ? v.eb : v.ea);

                    if script.on_trigger_enter != nil do script.on_trigger_enter(data, other)

                    case events.Trigger_Left:
                    if v.ea != go.entity do break
                    other := get_gameobject(data.ecs, v.eb);
                    if script.on_trigger_left != nil do script.on_trigger_left(data, other)

                    case events.AnimationFinished:
                    if v.entity != go.entity do break
                    if go_anim, has := get_component(go.ecs, go.entity, SpriteAnimator); has {
                        if script.on_animation_finished != nil do script.on_animation_finished(data, go_anim)
                    }

                }
            }
        }

    }
}

animation_length :: proc(animator: ^SpriteAnimator) -> int {
    anim := animator._active_animation
    if animator.sprites_length == nil || animator.sprites_length[anim] == 0 {
        return len(animator.sprites[anim])
    }
    return animator.sprites_length[anim]
}


sprite_animator_system :: proc(data: SystemData, dt: f32) {
    storage,        ok  := get_storage(data.ecs, SpriteAnimator)
    sprite_storage, ok2 := get_storage(data.ecs, SpriteRenderer)
    if !ok || !ok2 do return
    
    for i in 0..<len(storage.dense) {
        animator := &storage.dense[i]
        entity   := storage.entities[i]
        if animator.disabled do continue

        // Lazily attach a SpriteRenderable to write frames into.
        if animator.sprite_comp == nil {
            index, has_sprite := has_component(sprite_storage, entity)
            if has_sprite {
                animator.sprite_comp = &sprite_storage.dense[sprite_storage.sparse[entity]]
            } else {
                fmt.println("INFO: Adding sprite component to", entity, animator, "because it had no sprite_component")
                sprite := add_component(data.ecs, entity, NewSpriteRenderer())
                animator.sprite_comp = sprite
            }
        }

        // Switch to a newly requested animation.
        if animator.active_animation != animator._active_animation {
            if animator.active_animation < 0 || animator.active_animation >= len(animator.sprites) {
                fmt.println("WARNING: active_animation", animator.active_animation, "out of bounds")
                continue
            }
            animator._active_animation = animator.active_animation
            animator._frame_counter    = animation_length(animator) - 1
            animator.active_index      = 0
            animator._time_counter     = animator.time
        }

        length := animation_length(animator)
        if length <= 0 do continue // nothing to play; guards the modulo below

        // End-of-cycle bookkeeping.
        if animator._frame_counter <= 0 {
            animator._frame_counter = length
            if animator._first_run do events.emit(data.eventQueue, events.AnimationFinished({entity}))
            else                   do animator._first_run = true
        }

        // Advance the frame timer.
        if animator._time_counter <= 0 {
            animator._time_counter      = animator.time
            animator.active_index       = (animator.active_index + 1) % length
            animator.sprite_comp.sprite = animator.sprites[animator._active_animation][animator.active_index]
            animator._frame_counter    -= 1
        } else {
            animator._time_counter -= dt
        }
    }
}

rotate :: proc(p : Vector2, angle: f32) -> Vector2 {

    rad := angle / math.DEG_PER_RAD;
    s := math.sin(rad)
    c := math.cos(rad)
    return Vector2({
        p.x * c - p.y * s,
        p.x * s + p.y * c
    })
}


parent_system :: proc(data: SystemData, dt: f32) {
    parent_storage, ok := get_storage(data.ecs, Parent);
    if !ok do return;
    t_storage, ok2 := get_storage(data.ecs, Transform)
    if !ok2 do return


    for i in 0..<len(parent_storage.dense) {
        entity := parent_storage.entities[i]
        // t_idx, has_t := has_component(t_storage, entity)
        // if !has_t do continue
        
        child_t  := &t_storage.dense[t_storage.sparse[int(entity)]]
        parent   := &parent_storage.dense[i]

        
        if t_storage.sparse[int(parent.parent_entity)] == -1 do continue
        parent_t := &t_storage.dense[t_storage.sparse[int(parent.parent_entity)]]



        child_t.pos = parent_t.pos + rotate(child_t.local_pos * parent_t.size/100, parent_t.rot) // divide by 100 because default size is 100?
        child_t.size = parent_t.size + child_t.local_size * parent_t.size/100
        child_t.rot = parent_t.rot
    }
}

camera_system :: proc(data: SystemData, dt: f32) {
    storage, ok := get_storage(data.ecs, Camera2D);
    if !ok do return;
    t_storage, ok2 := get_storage(data.ecs, Transform)
    if !ok2 do return
    
    for i in 0..<len(storage.dense) {
        entity    := storage.entities[i]
        camera    := storage.dense[i];
        transform := t_storage.dense[t_storage.sparse[entity]];

        camera.target = transform.pos
        // FIXME
        if data.renderer.active_camera == nil do data.renderer.active_camera = new(rn.Camera2D)
        data.renderer.active_camera.offset=camera.offset
        data.renderer.active_camera.target=camera.target
        data.renderer.active_camera.zoom=camera.zoom
        data.renderer.active_camera.rotation=camera.rotation
    }
}

ui_system :: proc(data:SystemData, dt: f32){
    text_storage, ok := get_storage(data.ecs, UIText);
    sprite_storage, ok2 := get_storage(data.ecs, UISpriteRenderer);
    t_storage, ok3 := get_storage(data.ecs, Transform)
    if !ok || !ok2 || !ok3 do return;

    for i in 0..<len(text_storage.dense) {
        entity := text_storage.entities[i]
        text := text_storage.dense[i]
        t := t_storage.dense[t_storage.sparse[entity]]

        rn.add_command(data.renderer, rn.UIText({
            pos=t.pos+text.offset,
            font_size=text.font_size,
            rot=t.rot,
            text=text.text,
            color=text.color,
            layer=text.layer
        }))
    }

     for i in 0..<len(sprite_storage.dense) {
        entity := sprite_storage.entities[i]
        sprite := sprite_storage.dense[i]
        t := t_storage.dense[t_storage.sparse[entity]]

        rn.add_command(data.renderer, rn.UISprite({
            pos=t.pos,
            offset = sprite.offset,
            size = t.size + sprite.size,
            rot=t.rot,
            inverted=sprite.inverted,
            sprite=sprite.sprite,
            layer=sprite.layer,
            repeated_x = sprite.repeated_x,
            repeated_y = sprite.repeated_y
        }))
    }

}
text_system :: proc(data: SystemData, dt: f32){
    text_storage, ok := get_storage(data.ecs, Text);
    t_storage, ok2 := get_storage(data.ecs, Transform)
    if !ok || !ok2 do return;

    for i in 0..<len(text_storage.dense) {
        entity := text_storage.entities[i]
        text := text_storage.dense[i]
        t := t_storage.dense[t_storage.sparse[entity]]

        rn.add_command(data.renderer, rn.Text({
            pos=t.pos+text.offset,
            font_size=text.font_size,
            rot=t.rot,
            text=text.text,
            color=text.color,
            layer=text.layer
        }))
    }

}

collider_check_parent_body :: proc(ecs: ^EntityComponentSystem, entity: Entity) -> (b2.BodyId, bool) {
    fmt.println("INFO: checking for body in parent we are", entity)
    if parent, has_parent := get_component(ecs, entity, Parent); has_parent {
        fmt.println("INFO: had parent", parent)
        if parent.parent_entity == entity do panic("WTF")
        if body_id, has_body := ecs.world.bodies[parent.parent_entity]; has_body {
            return body_id, true
        }
        else do return collider_check_parent_body(ecs, parent.parent_entity)
    }
    return b2.BodyId({}), false
}

collider_system :: proc(data: SystemData, dt: f32) {
    collider_storage, ok := get_storage(data.ecs, Collider);
    transform_storage, ok1 := get_storage(data.ecs, Transform);
    rigid_storage, ok2 := get_storage(data.ecs, Rigidbody);

    if !ok || !ok1 || !ok2 do return

    for i in 0..<len(collider_storage.dense) {
        collider := collider_storage.dense[i]
        entity   := collider_storage.entities[i]
        transform := transform_storage.dense[transform_storage.sparse[entity]]
        // we check if this entity has a body
        // if it has we check if it has a shape
        // if it doesnt we create it
        // if the entity doesnt have a body we check if it has a parent with a body
        if shape_id, has_shape := data.ecs.world.shapes[entity]; has_shape {
            // update shape if neceary
            rn.add_command(data.renderer, rn.Rectangle({transform.pos,transform.size+collider.size,transform.rot, rn.get_color(0x00ff00ff), true, 0}))
        }
        else {
            body_id, has_body := data.ecs.world.bodies[entity]; 
            if !has_body {
                // check parent
                body_id, has_body = collider_check_parent_body(data.ecs, entity);
                if has_body do fmt.println("INFO: ",entity,"Found parent body")
            }
            if has_body{
                fmt.println("INFO: built shape for collider")
                // build collider
                physics.build_body_shape(data.ecs.world,
                                         entity,
                                         body_id,
                                         transform.local_pos+collider.offset,
                                         transform.size+collider.size,
                                         true,
                                         collider.trigger)
                    

            }
        }


    }
    
}

handle_collision :: proc (ecs: ^EntityComponentSystem, eventQueue: ^events.EventQueue, contact_events: b2.ContactEvents ) {

    c_storage,_ := get_storage(ecs,Collider)
    for i in 0..< contact_events.beginCount {
        e := contact_events.beginEvents[i]        
        
        ea := ecs.world.entites_by_shape[e.shapeIdA]
        eb := ecs.world.entites_by_shape[e.shapeIdB]
            

        events.emit(eventQueue, events.Collision_Entered({ea=ea, eb=eb}))

    }

    for i in 0..< contact_events.endCount {
        e := contact_events.endEvents[i]        
        
        ea := ecs.world.entites_by_shape[e.shapeIdA]
        eb := ecs.world.entites_by_shape[e.shapeIdB]

        events.emit(eventQueue, events.Collision_Left({ea=ea, eb=eb}))
    }
}
handle_triggers :: proc (ecs: ^EntityComponentSystem, eventQueue: ^events.EventQueue, sensor_events: b2.SensorEvents ) {

    c_storage,_ := get_storage(ecs,Collider)
    for i in 0..< sensor_events.beginCount {
        e := sensor_events.beginEvents[i]        
        
        ea := ecs.world.entites_by_shape[e.sensorShapeId]
        eb := ecs.world.entites_by_shape[e.visitorShapeId]
            
        events.emit(eventQueue, events.Trigger_Entered({ea=ea, eb=eb}))
    }

    for i in 0..< sensor_events.endCount {
        e := sensor_events.endEvents[i]        
        
        ea := ecs.world.entites_by_shape[e.sensorShapeId]
        eb := ecs.world.entites_by_shape[e.visitorShapeId]

        events.emit(eventQueue, events.Trigger_Left({ea=ea, eb=eb}))
    }
}

physics_system :: proc(data: SystemData, dt: f32) {
    rigid_storage, ok := get_storage(data.ecs, Rigidbody);
    transform_storage, ok1 := get_storage(data.ecs, Transform);
    if !ok do return

    b2.World_Step(data.ecs.world.world_id, dt, 8);
    events := b2.World_GetContactEvents(data.ecs.world.world_id);
    handle_collision(data.ecs,data.eventQueue, events)

    sensor_events := b2.World_GetSensorEvents(data.ecs.world.world_id);
    handle_triggers(data.ecs,data.eventQueue, sensor_events)

    for i in 0..<len(rigid_storage.dense) {
        // Check for rigidbody value change and change box2d
        entity := rigid_storage.entities[i]
        rb := &rigid_storage.dense[i]
        transform := &transform_storage.dense[transform_storage.sparse[entity]]

        if body_id, has_body := data.ecs.world.bodies[entity]; has_body {
            if shape_id, has_shape := data.ecs.world.shapes[entity]; has_shape {
                body_t := b2.Body_GetTransform(body_id)
                poly := b2.Shape_GetPolygon(shape_id)
                world_center := b2.TransformPoint(body_t, poly.centroid) * physics.PIXELS_PER_METER

                // Check if the transforms position has changed
                // we check axies independently to not destrurb unchanged axies
                if transform._pos.x != transform.pos.x {
                    body_t.p= b2.Vec2({
                        transform.pos.x/physics.PIXELS_PER_METER,
                        body_t.p.y})
                    b2.Body_SetTransform(body_id,body_t.p,body_t.q)

                    
                }
                if transform._pos.y != transform.pos.y {
                    b2.Body_SetTransform(body_id,b2.Vec2({
                        body_t.p.x,
                        transform.pos.y/physics.PIXELS_PER_METER}
                    ),body_t.q)
                }

                transform.pos = world_center
                transform._pos = world_center // save old pos so we can use it later to compare

                transform.rot = b2.Rot_GetAngle(body_t.q) * math.DEG_PER_RAD

                body_vel := b2.Body_GetLinearVelocity(body_id)

                // Check if the rigidbody vel has changed
                // we check axies independently to not destrurb unchanged axies
                if rb._vel.x != rb.vel.x {
                    body_vel = {rb._vel.x, body_vel.y}
                    b2.Body_SetLinearVelocity(body_id, body_vel)
                }
                if rb._vel.y != rb.vel.y {
                    body_vel = {body_vel.x, rb._vel.y}
                    b2.Body_SetLinearVelocity(body_id, body_vel)
                }
                rb.vel = body_vel
                rb._vel = body_vel

            }
            else {
                // TODO create shape
                physics.build_body_shape(data.ecs.world,
                                         entity,
                                         body_id,
                                         transform.local_pos,
                                         transform.size,
                                         false,
                                         true)
            }
            
        }
        else {
            physics.create_body(data.ecs.world,
                                entity,
                                b2.BodyType(rb.type),
                                transform.pos,
                                transform.rot,
                                rb.linear_damping,
                                rb.disabled_gravity,
                                rb.disabled_rotation)
        }
    }

}

mouse_over_system :: proc (data: SystemData, dt: f32) {
    mouse_storage, ok := get_storage(data.ecs, MouseOverComponent);
    transform_storage, ok1 := get_storage(data.ecs, Transform);
    if !ok do return

    for i in 0..<len(mouse_storage.dense) {
        entity := mouse_storage.entities[i];
        mouse_over := mouse_storage.dense[i]
        transform := transform_storage.dense[transform_storage.sparse[entity]]
        
        mp := input.get_world_mouse_position()
        px := mp.x
        py := mp.y
        x := transform.pos.x
        y := transform.pos.y
        w := transform.size.x
        h := transform.size.y

        before := mouse_over.over
        mouse_over.over = px >= x &&
           px <= x + w &&
           py >= y &&
            py <= y + h;

        // we left
        if before && !mouse_over.over {
            events.emit(data.eventQueue, events.MouseLeftEntity({entity}))
        }
        else if !before && mouse_over.over {
            events.emit(data.eventQueue, events.MouseEnteredEntity({entity}))
        }

    }
}
