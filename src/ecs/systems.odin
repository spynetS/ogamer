package ecs;

import "core:fmt"
import storage "./storage"
import rn "../renderer"
import rl "vendor:raylib/rlgl"


render_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
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
        cmd : rn.Rectangle = {t.pos,t.size, r.color};
        append(&renderer.commands, cmd);
    }
}


physics_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
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

script_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    script_storage, ok := get_storage(ecs, ^Script);
    if !ok do return;
    for i in 0..<len(script_storage.dense) {
        entity := script_storage.entities[i]
        script := script_storage.dense[i];
        script.on_update(ecs, u32(entity), dt);
    }

}
