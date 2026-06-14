package ecs;

import "core:fmt"
import "vendor:box2d"
import storage "./storage"
import rn "../renderer"
import io "../io/"





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
