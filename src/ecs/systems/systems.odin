package systems;

import "core:fmt"
import "core:math"
import storage "../storage"
import rn "../../renderer"
import rl "vendor:raylib/rlgl"
import io "../../io/"
import ecss "../"
import "../types"


camera_system :: proc(ecs: ^ecss.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
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

render_system :: proc(ecs: ^ecss.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    render_storage, ok := ecss.get_storage(ecs, ^types.RectangleRenderable);
    if !ok do return;
    trans, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return
    for i in 0..<len(render_storage.dense) {
        entity := render_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        r := render_storage.dense[i]
        cmd : rn.Rectangle = {t.pos,t.size, t.rot, r.color};
        append(&renderer.commands, cmd);
    }
}

sprite_system :: proc(ecs: ^ecss.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    sprite_storage, ok := ecss.get_storage(ecs, ^types.SpriteRenderable);
    if !ok do return;
    trans, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return
    for i in 0..<len(sprite_storage.dense) {
        sprite := sprite_storage.dense[i]
        if sprite.disabled do continue;
        
        entity := sprite_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        
        
        cmd := rn.Sprite({t.pos, t.size, t.rot, sprite.image})
        append(&renderer.commands, cmd);
    }
}

sprite_animator_system :: proc(ecs: ^ecss.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    storage, ok := ecss.get_storage(ecs, ^types.SpriteAnimator);
    if !ok do return;
    for i in 0..<len(storage.dense) {
        animator := storage.dense[i]
        if animator.disabled do continue;
        if animator.counter <= 0 {
            fmt.println("new sprite")
            animator.counter = animator.time
            animator.active_index = (animator.active_index + 1) % len(animator.sprites)
            animator.sprite_comp.image = animator.sprites[animator.active_index]
        }
        else {
            fmt.println("count down", animator.counter, animator.active_index)
            animator.counter -= dt;
        }
    }
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

parent_system :: proc(ecs: ^ecss.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    parent_storage, ok := ecss.get_storage(ecs, ^types.Parent);
    if !ok do return;
    t_storage, ok2 := ecss.get_storage(ecs, ^types.Transform)
    if !ok2 do return

    for i in 0..<len(parent_storage.dense) {
        entity := parent_storage.entities[i]
        t_idx, has_t := storage.has_component(t_storage, entity)
        if !has_t do continue
        
        child_t := t_storage.dense[t_storage.sparse[int(entity)]]
        parent := parent_storage.dense[i]
        parent_t := t_storage.dense[t_storage.sparse[int(parent.entity)]]

        child_t.pos = parent_t.pos + rotate(child_t.local_pos * parent_t.size/100, parent_t.rot) // divide by 100 because default size is 100?
        child_t.size = parent_t.size + child_t.local_size
        child_t.rot = parent_t.rot
    }
}


script_system :: proc(ecs: ^ecss.ECS, io_handler: ^types.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    script_storage, ok := ecss.get_storage(ecs, ^ecss.Script);
    if !ok do return;
    for i in 0..<len(script_storage.dense) {
        entity := script_storage.entities[i]
        script := script_storage.dense[i];
        script.on_update(ecs, u32(entity), dt);
    }

}
