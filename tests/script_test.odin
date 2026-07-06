package tests

import "core:mem"
import "core:testing"
import "../src/ecs"
import "../src/types"


PlayerData :: struct {
    collider: ^types.SquareCollider
}

@(test)
test_script_data_test :: proc(t: ^testing.T) {
    testing.expect_leaks(t, proc(t: ^testing.T) {
        data := new(PlayerData)
        e: types.ECS
        defer delete(e.storages)
        ecs.add_storage(&e, ^types.Transform)
        ecs.add_storage(&e, ^types.RigidBody)
        ecs.add_storage(&e, ^types.SquareCollider)
        ecs.add_storage(&e, ^types.Parent)
        ecs.add_storage(&e, ^types.Script)
        defer ecs.delete_storage(&e, ^types.Transform)
        defer ecs.delete_storage(&e, ^types.RigidBody)
        defer ecs.delete_storage(&e, ^types.SquareCollider)
        defer ecs.delete_storage(&e, ^types.Parent)
        defer ecs.delete_storage(&e, ^types.Script)

        entity := types.Entity(0)
        ecs.add_component(&e, entity, types.Transform{pos = {1, 2}})
        ecs.add_component(&e, entity, types.RigidBody{})
        ecs.add_component(&e, entity, types.SquareCollider{})
        ecs.add_component(&e, entity, types.Parent{entity = entity})
        ecs.add_component(&e, entity, types.Script({
            data=data,
            on_destroy = proc(go: types.GameObject, data: rawptr){
                dat := cast(^PlayerData)data
                free(dat)
            }
        }))

        ecs.destroy_entity(&e, entity)
    }, no_leaks_verifier)
}
