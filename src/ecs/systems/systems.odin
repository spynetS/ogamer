package systems;

import "core:fmt"
import "core:math"
import stor "../storage"
import rn "../../renderer"
import ecss "../"
import "../../types"
import es "../../event-system"


camera_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    storage, ok := ecss.get_storage(ecs, ^types.Camera2D);
    if !ok do return;
    t_storage, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return
    
    for i in 0..<len(storage.dense) {
        entity    := storage.entities[i]
        camera    := storage.dense[i];
        transform := t_storage.dense[t_storage.sparse[entity]];

        camera.target = transform.pos
        renderer.active_camera = camera
    }

}

render_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    render_storage, ok := ecss.get_storage(ecs, ^types.RectangleRenderable);
    if !ok do return;
    trans, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return
    for i in 0..<len(render_storage.dense) {
        entity := render_storage.entities[i]
        t_idx, has_t := stor.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        r := render_storage.dense[i]
        cmd : rn.Rectangle = {t.pos,t.size, t.rot, r.color, false, r.layer};
        rn.add_command(renderer, cmd);
    }
}

ui_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    text_storage, ok := ecss.get_storage(ecs, ^types.TextElement);
    sprite_storage, ok3 := ecss.get_storage(ecs, ^types.UiSprite);
    trans, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok || !ok2 || !ok3 do return

    for i in 0..<len(sprite_storage.dense) {
        entity := sprite_storage.entities[i]
        t_idx, has_t := stor.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        sprite := sprite_storage.dense[i]
        if sprite.disabled do continue;

        cmd := rn.UISprite({t.pos+sprite.offset, t.size+sprite.size, t.rot, sprite.inverted, sprite.sprite, sprite.layer})
        rn.add_command(renderer, cmd);
    }

    for i in 0..<len(text_storage.dense) {
        entity := text_storage.entities[i]
        t_idx, has_t := stor.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        r := text_storage.dense[i]

        color := r.color == 0 ? rn.get_color(0x181818ff) : r.color

        cmd :rn.UIText = {t.pos, r.font_size, t.rot, r.text, r.color, r.layer}
        rn.add_command(renderer, cmd);
    }
}

tilemap_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    tilemap_storage, ok := ecss.get_storage(ecs, ^types.TileMap);
    if !ok do return;
    trans, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return
    for i in 0..<len(tilemap_storage.dense) {
        tilemap := tilemap_storage.dense[i]
        
        entity := tilemap_storage.entities[i]
        t_idx, has_t := stor.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]

        cols := tilemap.width
        rows := tilemap.height
        if cols <= 0 { // fall back to a single horizontal row
            cols = len(tilemap.tiles)
            rows = 1
        }
        if cols <= 0 do continue

        tile_size := t.size / {f32(cols), f32(rows)}
        // Center of the bottom-left tile in the Y-up world.
        bottom_left := t.pos - t.size/2 + tile_size/2

        for tile, index in tilemap.tiles {
            col := index % cols
            row := index / cols
            // tiles are row-major with row 0 at the top; in Y-up, higher rows
            // sit at higher Y, so count rows up from the bottom.
            pos := bottom_left + {f32(col), f32(rows-1-row)} * tile_size

            cmd := rn.Sprite({pos, {0,0}, tile_size, t.rot, false, tile, tilemap.layer, false, false})
            rn.add_command(renderer, cmd);
        }

    }
}

sprite_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    sprite_storage, ok := ecss.get_storage(ecs, ^types.SpriteRenderable);
    if !ok do return;
    trans, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return
    for i in 0..<len(sprite_storage.dense) {
        sprite := sprite_storage.dense[i]
        if sprite.disabled do continue;
        
        entity := sprite_storage.entities[i]
        t_idx, has_t := stor.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        if renderer.active_camera != nil && sprite.parallax != {0,0}{
            sprite.offset = renderer.active_camera.target * (-sprite.parallax)
        }
        
        cmd := rn.Sprite({t.pos, sprite.offset, t.size+sprite.size, t.rot, sprite.inverted, sprite.sprite, sprite.layer, sprite.repeated_x, sprite.repeated_y})
        rn.add_command(renderer, cmd);
    }
}

sprite_animator_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    storage,        ok  := ecss.get_storage(ecs, ^types.SpriteAnimator)
    sprite_storage, ok2 := ecss.get_storage(ecs, ^types.SpriteRenderable)
    if !ok || !ok2 do return

    for i in 0..<len(storage.dense) {
        animator := storage.dense[i]
        if animator.disabled do continue

        // Lazily attach a SpriteRenderable to write frames into.
        if animator.sprite_comp == nil {
            index, has_sprite := ecss.has_component(ecs, storage.entities[i], types.SpriteRenderable)
            if has_sprite {
                animator.sprite_comp = sprite_storage.dense[index]
            } else {
                fmt.println("INFO: Adding sprite component to", storage.entities[i], animator, "because it had no sprite_component")
                sprite, _ := ecss.add_component(ecs, storage.entities[i], types.SpriteRenderable({}))
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
            if animator._first_run do es.emit(types.Event_SpriteAnimator_End({animator}))
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

// Frames in the current animation: the explicit length if set, else the slice length.
animation_length :: proc(animator: ^types.SpriteAnimator) -> int {
    anim := animator._active_animation
    if animator.sprites_length == nil || animator.sprites_length[anim] == 0 {
        return len(animator.sprites[anim])
    }
    return animator.sprites_length[anim]
}


rotate :: proc(p : types.Vector2, angle: f32) -> types.Vector2 {

    rad := angle / math.DEG_PER_RAD;
    s := math.sin(rad)
    c := math.cos(rad)
    return types.Vector2({
        p.x * c - p.y * s,
        p.x * s + p.y * c
    })
}

parent_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    parent_storage, ok := ecss.get_storage(ecs, ^types.Parent);
    if !ok do return;
    t_storage, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return

    for i in 0..<len(parent_storage.dense) {
        entity := parent_storage.entities[i]
        t_idx, has_t := stor.has_component(t_storage, entity)
        if !has_t do continue
        
        child_t  := t_storage.dense[t_storage.sparse[int(entity)]]
        parent   := parent_storage.dense[i]
        if t_storage.sparse[int(parent.entity)] == -1 do continue
        parent_t := t_storage.dense[t_storage.sparse[int(parent.entity)]]

        child_t.pos = parent_t.pos + rotate(child_t.local_pos * parent_t.size/100, parent_t.rot) // divide by 100 because default size is 100?
        child_t.size = parent_t.size + child_t.local_size * parent_t.size/100
        child_t.rot = parent_t.rot
    }
}


script_system :: proc(ecs: ^types.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    script_storage, ok := ecss.get_storage(ecs, ^types.Script);
    if !ok do return;
    // Re-check len each step: a script may destroy entities (e.g. a level
    // transition tearing down the old level) which swap-removes from dense.
    // A fixed 0..<len bound could then index past the shrunk array.
    for i := 0; i < len(script_storage.dense); i += 1 {
        entity := script_storage.entities[i]
        script := script_storage.dense[i];

        go, _ := ecss.get_gameobject(ecs, entity);
        defer ecss.free_gameobject(go);

        if script.on_update != nil do script.on_update(go^,script.data ,dt);
        
        // TODO optimize this shit
        for event in es.event_queue_poll() {
            if script.on_event != nil do script.on_event(go^, script.data, event)
            #partial switch v in event {
                case types.Event_Collision_Entered:
                // box2d's shapeIdA/B ordering is arbitrary, so match either side.
                if v.ea != go.entity && v.eb != go.entity do break
                fmt.println("ENTERED IN SCRIPT")
                other, _ := ecss.get_gameobject(ecs, v.ea == go.entity ? v.eb : v.ea);
                defer ecss.free_gameobject(other);
                if script.on_collision_entered != nil do script.on_collision_entered(go^, other^, script.data, v)

                case types.Event_Collision_Left:
                if v.ea != go.entity && v.eb != go.entity do break
                other, _ := ecss.get_gameobject(ecs, v.ea == go.entity ? v.eb : v.ea);
                defer ecss.free_gameobject(other);
                if script.on_collision_left != nil do script.on_collision_left(go^, other^, script.data, v)

                case types.Event_Trigger_Entered:
                if v.ea != go.entity && v.eb != go.entity do break
                other_id := v.eb
                other, _ := ecss.get_gameobject(ecs, v.ea == go.entity ? v.eb : v.ea);
                defer ecss.free_gameobject(other);

                if script.on_trigger_entered != nil do script.on_trigger_entered(go^, other^, script.data, v)

                case types.Event_Trigger_Left:
                if v.ea != go.entity do break
                other, _ := ecss.get_gameobject(ecs, v.eb);
                defer ecss.free_gameobject(other);
                if script.on_trigger_left != nil do script.on_trigger_left(go^, other^, script.data, v)

                case types.Event_SpriteAnimator_End:
                if go_anim, has := ecss.get_component(go.ecs, go.entity, types.SpriteAnimator); has && go_anim == v.animator {
                    if script.on_sprite_animator_end != nil do script.on_sprite_animator_end(go^, script.data, v)
                }
                
            }
        }
        
    }

}
