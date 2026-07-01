package tests

import "core:mem"
import "core:testing"
import "../src/ecs"
import "../src/types"

no_leaks_verifier :: proc(t: ^testing.T, ta: ^mem.Tracking_Allocator) {
    testing.expect_value(t, len(ta.allocation_map), 0)
    testing.expect_value(t, len(ta.bad_free_array), 0)
}

// Round-trips a single entity through every component kind it can hold and
// destroys it. Unlike the plain leak warnings the runner logs, expect_leaks
// turns a leftover allocation into an actual test failure.
@(test)
test_entity_full_component_lifecycle_frees_all_memory :: proc(t: ^testing.T) {
    testing.expect_leaks(t, proc(t: ^testing.T) {
        e: types.ECS
        defer delete(e.storages)
        ecs.add_storage(&e, ^types.Transform)
        ecs.add_storage(&e, ^types.RigidBody)
        ecs.add_storage(&e, ^types.SquareCollider)
        ecs.add_storage(&e, ^types.Parent)
        defer ecs.delete_storage(&e, ^types.Transform)
        defer ecs.delete_storage(&e, ^types.RigidBody)
        defer ecs.delete_storage(&e, ^types.SquareCollider)
        defer ecs.delete_storage(&e, ^types.Parent)

        entity := types.Entity(0)
        ecs.add_component(&e, entity, types.Transform{pos = {1, 2}})
        ecs.add_component(&e, entity, types.RigidBody{})
        ecs.add_component(&e, entity, types.SquareCollider{})
        ecs.add_component(&e, entity, types.Parent{entity = entity})

        ecs.destroy_entity(&e, entity)
    }, no_leaks_verifier)
}

// Simulates many entities spawning, a wave of them despawning, survivors
// respawning into the freed slots, and a final teardown -- the kind of
// churn a running game would put entity storage through in one session.
@(test)
test_many_entities_spawn_despawn_respawn_without_leaking :: proc(t: ^testing.T) {
    testing.expect_leaks(t, proc(t: ^testing.T) {
        e: types.ECS
        defer delete(e.storages)
        ecs.add_storage(&e, ^types.Transform)
        ecs.add_storage(&e, ^types.RigidBody)
        ecs.add_storage(&e, ^types.SquareCollider)
        defer ecs.delete_storage(&e, ^types.Transform)
        defer ecs.delete_storage(&e, ^types.RigidBody)
        defer ecs.delete_storage(&e, ^types.SquareCollider)

        entity_count :: 200

        for i in 0 ..< entity_count {
            entity := types.Entity(i)
            ecs.add_component(&e, entity, types.Transform{pos = {f32(i), 0}})
            ecs.add_component(&e, entity, types.RigidBody{})
            if i % 2 == 0 {
                ecs.add_component(&e, entity, types.SquareCollider{})
            }
        }

        // a wave of enemies dies
        for i in 0 ..< entity_count {
            if i % 2 == 0 {
                ecs.destroy_entity(&e, types.Entity(i))
            }
        }

        // survivors respawn into the freed slots with fresh components
        for i in 0 ..< entity_count {
            if i % 2 == 0 {
                ecs.add_component(&e, types.Entity(i), types.Transform{pos = {999, 999}})
                ecs.add_component(&e, types.Entity(i), types.RigidBody{})
            }
        }

        // everyone leaves at the end of the session
        for i in 0 ..< entity_count {
            ecs.destroy_entity(&e, types.Entity(i))
        }

        testing.expect_value(t, len(e.storages), 3)
    }, no_leaks_verifier)
}
