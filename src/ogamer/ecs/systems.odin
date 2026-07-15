package ogamer_ecs;

import "core:fmt"
import rn "../renderer/"
import "./components/"

shape_render_system :: proc(e: ^EntityComponentSystem, renderer: ^rn.Renderer, dt: f32) {
    s_storage,ok := get_storage(e, components.ShapeRenderer)
    t_storage,ok2 := get_storage(e, components.Transform)
    for i in 0..<len(s_storage.dense) {
        s := s_storage.dense[i]
        entity := s_storage.entities[i]
        t := t_storage.dense[t_storage.sparse[entity]]
        rn.add_command(renderer, rn.Rectangle({t.pos,t.size,0, rn.get_color(0xffffffff), false, 0}))
    }
}

sprite_render_system :: proc(e: ^EntityComponentSystem, renderer: ^rn.Renderer, dt: f32) {
    t_storage,ok := get_storage(e, components.Transform)
    s_storage,ok2 := get_storage(e, components.SpriteRenderer)
    for i in 0..<len(s_storage.dense) {
        s := s_storage.dense[i]
        entity := s_storage.entities[i]
        if int(entity) > len(t_storage.sparse) do continue
        t := t_storage.dense[t_storage.sparse[entity]]

        rn.add_command(renderer, rn.Sprite({t.pos,s.offset, t.size, 0, s.inverted, s.sprite, s.layer, s.repeated_x, s.repeated_y}))
    }

}

