package ogamer_ecs;

import "core:fmt"
import "core:math"
import rn "../renderer/"
import  "../io/"
import  "../events/"

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
    t_storage,ok := get_storage(data.ecs, Transform)
    s_storage,ok2 := get_storage(data.ecs, SpriteRenderer)
    if !ok || !ok2 do return

    for i in 0..<len(s_storage.dense) {
        s := s_storage.dense[i]
        entity := s_storage.entities[i]
        if int(entity) > len(t_storage.sparse) do continue
        t := t_storage.dense[t_storage.sparse[entity]]
        
        if data.renderer == nil do continue
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
            if script.update != nil do script.update(ScriptData({
                data=script.data,
                gameObject = go,
                ecs=data.ecs,
                eventQueue = data.eventQueue,
                dt=dt
            }))
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
            index, has_sprite := has_component(sprite_storage, storage.entities[i])
            if has_sprite {
                animator.sprite_comp = &sprite_storage.dense[index]
            } else {
                fmt.println("INFO: Adding sprite component to", storage.entities[i], animator, "because it had no sprite_component")
                sprite := add_component(data.ecs, storage.entities[i], NewSpriteRenderer())
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
        t_idx, has_t := has_component(t_storage, entity)
        if !has_t do continue
        
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
text_system :: proc(data:SystemData, dt: f32){
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

