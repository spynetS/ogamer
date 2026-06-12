package ecs;

import "core:fmt"
import ec "./ecs_core"
import rn "../renderer"


render_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer) {
    render_storage, ok := get_storage(ecs, ec.RectangleRenderable);
    if !ok do return;
    for entity in render_storage.sparse{
        
        render := render_storage.dense[entity];
        trans, _ := get_component(ecs, entity, ec.Transform);
        
        cmd : rn.Triangle = {trans.pos, {trans.pos.x,trans.pos.y+trans.size.y}, trans.pos+trans.size, render.color};
        append(&renderer.commands, cmd);
        cmd = {{trans.pos.x+trans.size.x, trans.pos.y},trans.pos,trans.pos+trans.size, render.color};
        append(&renderer.commands, cmd);
    }
}

physics_system :: proc(ecs: ^ECS, renderer: ^rn.Renderer) {
    physics_storage, ok := get_storage(ecs, ec.PhysicsBody);
    if !ok do return;
    for entity, idx in physics_storage.sparse{
        
        phy := &physics_storage.dense[idx];
        trans, _ := get_component(ecs, entity, ec.Transform);

        phy.vel += phy.acc * 0.016;
        trans.pos += phy.vel;
    }

}
