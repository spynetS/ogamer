package ogamer_ecs;

import "core:fmt"

transform_system :: proc(e: ^EntityComponentSystem, dt: f32) {
    fmt.println(dt)
}
