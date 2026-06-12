package ecs;

import "core:fmt"
import ec "./ecs_core"
import rn "../renderer"


render_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    render_storage, ok := get_storage(ecs, ec.RectangleRenderable);
    if !ok do return;
    for entity, idx in render_storage.sparse{
        
        render := render_storage.dense[idx];
        trans, _ := get_component(ecs, entity, ec.Transform);
        
        cmd : rn.Rectangle = {trans.pos,trans.size, render.color};
        append(&renderer.commands, cmd);
    }
}

physics_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    physics_storage, ok := get_storage(ecs, ec.PhysicsBody);
    if !ok do return;
    for entity, idx in physics_storage.sparse{
        
        phy := &physics_storage.dense[idx];
        trans, _ := get_component(ecs, entity, ec.Transform);

        phy.vel += phy.acc * dt;
        trans.pos += phy.vel;
    }

}

script_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer, dt: f32) {
    script_storage, ok := get_storage(ecs, Script);
    if !ok do return;
    for entity, idx in script_storage.sparse{
        
        script := &script_storage.dense[idx];
        script.on_update(ecs, entity, dt);
    }

}
