package ecs;

import "core:fmt"
import "core:math"
import storage "./storage"
import rn "../renderer"
import rl "vendor:raylib/rlgl"
import io "../io/"


render_system :: proc(ecs: ^ECS, io_handler: ^io.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    render_storage, ok := get_storage(ecs, ^RectangleRenderable);
    if !ok do return;
    trans, ok2 := get_storage(ecs, ^Transform)
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

sprite_system :: proc(ecs: ^ECS, io_handler: ^io.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    sprite_storage, ok := get_storage(ecs, ^SpriteRenderable);
    if !ok do return;
    trans, ok2 := get_storage(ecs, ^Transform)
    if !ok2 do return
    for i in 0..<len(sprite_storage.dense) {
        entity := sprite_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        
        t := trans.dense[trans.sparse[int(entity)]]
        sprite := sprite_storage.dense[i]
        
        cmd := rn.Sprite({t.pos, t.size, t.rot, sprite.file_path})
        append(&renderer.commands, cmd);
    }
}

// Vector2 RotatePoint(Vector2 p, float angle)
// {
//     float rad = angle * DEG2RAD;
//     float s = sinf(rad);
//     float c = cosf(rad);

//     return (Vector2){
//         p.x * c - p.y * s,
//         p.x * s + p.y * c
//     };
// }

rotate :: proc(p : Vector2, angle: f32) -> Vector2 {
    rad := angle / math.DEG_PER_RAD;
    s := math.sin(rad)
    c := math.cos(rad)
    return Vector2({
        p.x * c - p.y * s,
        p.x * s + p.y * c
    })
}

parent_system :: proc(ecs: ^ECS, io_handler: ^io.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    parent_storage, ok := get_storage(ecs, ^Parent);
    if !ok do return;
    t_storage, ok2 := get_storage(ecs, ^Transform)
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

        // cmd : rn.Rectangle = {child_t.pos+{200,0},child_t.size, rn.get_color(0xff0000ff)};
        // append(&renderer.commands, cmd);
    }
}

physics_system :: proc(ecs: ^ECS, io_handler: ^io.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := get_storage(ecs, ^PhysicsBody)
    if !ok do return
    trans, ok2 := get_storage(ecs, ^Transform)
    if !ok2 do return

    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        t := trans.dense[trans.sparse[int(entity)]]
        p := phys.dense[i]

        p.vel += p.acc * dt
        t.pos += p.vel * dt
    }
}

script_system :: proc(ecs: ^ECS, io_handler: ^io.IOHandler, renderer: ^rn.Renderer, dt: f32) {
    script_storage, ok := get_storage(ecs, ^Script);
    if !ok do return;
    for i in 0..<len(script_storage.dense) {
        entity := script_storage.entities[i]
        script := script_storage.dense[i];
        script.on_update(ecs, u32(entity), dt);
    }

}
