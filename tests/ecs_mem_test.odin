package tests;

import "core:testing"
import "core:mem"
import "core:fmt"
import "../src/ogamer/ecs"

@(test)
test_mem :: proc(t: ^testing.T) {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    leaks := 0

    ECS := new(ecs.EntityComponentSystem)
    ecs.add_systems(ECS);

    ecs.add_component(ECS,0, ecs.NewTransform(pos={1,1}))
    ecs.add_component(ECS,0, ecs.NewShapeRenderer())
    ecs.add_component(ECS,0, ecs.NewScriptComponent(ecs.NewScript()))

    comp := ecs.get_component(ECS, 0, ecs.Transform);
    ecs.update_systems(ECS, nil, 1);
    ecs.free_ecs(ECS);

    for _, entry in track.allocation_map {
        //            fmt.eprintfln("%v leaked %v bytes", entry.location, entry.size)
        leaks += 1
    }
    mem.tracking_allocator_destroy(&track)

    testing.expect_value(t, 0, leaks)
}
