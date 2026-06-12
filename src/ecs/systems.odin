package ecs;

import "core:fmt"
import ec "./ecs_core"
import storage "./storage"
import rn "../renderer"
import rl "vendor:raylib/rlgl"


render_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    render_storage, ok := get_storage(ecs, ec.RectangleRenderable);
    if !ok do return;
    trans, ok2 := get_storage(ecs, ec.Transform)
    if !ok2 do return
    for i in 0..<len(render_storage.dense) {
        entity := render_storage.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        
        t := &trans.dense[trans.sparse[int(entity)]]
        r := &render_storage.dense[i]
        cmd : rn.Rectangle = {t.pos,t.size, r.color};
        append(&renderer.commands, cmd);
    }
}


physics_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    phys, ok := get_storage(ecs, ec.PhysicsBody)
    if !ok do return
    trans, ok2 := get_storage(ecs, ec.Transform)
    if !ok2 do return

    for i in 0..<len(phys.dense) {
        entity := phys.entities[i]
        t_idx, has_t := storage.has_component(trans, entity)
        if !has_t do continue
        t := &trans.dense[trans.sparse[int(entity)]]
        p := &phys.dense[i]

        p.vel += p.acc * dt
        t.pos += p.vel * dt
    }
}

script_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    script_storage, ok := get_storage(ecs, Script);
    if !ok do return;
    for entity, idx in script_storage.sparse{
        
        script := &script_storage.dense[idx];
        script.on_update(ecs, u32(entity), dt);
    }

}
