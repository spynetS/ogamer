package tests

import "core:testing"
import "../src/ecs"
import "../src/types"

@(test)
test_ecs_add_component_and_get_component :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Transform)

    ecs.add_component(&e, 0, types.Transform{pos = {1, 2}})

    got, ok := ecs.get_component(&e, 0, types.Transform)
    testing.expect(t, ok)
    testing.expect_value(t, got.pos.x, f32(1))
    testing.expect_value(t, got.pos.y, f32(2))
}

@(test)
test_ecs_get_component_without_storage_fails :: proc(t: ^testing.T) {
    e: types.ECS
    _, ok := ecs.get_component(&e, 0, types.Transform)
    testing.expect(t, !ok)
}

@(test)
test_ecs_has_component_is_per_type :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.RigidBody)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.RigidBody)

    ecs.add_component(&e, 1, types.Transform{})

    _, has_transform := ecs.has_component(&e, 1, types.Transform)
    testing.expect(t, has_transform)

    _, has_rigidbody := ecs.has_component(&e, 1, types.RigidBody)
    testing.expect(t, !has_rigidbody)
}

// destroy_entity fans out across every registered component storage;
// an entity's components of every kind must be gone afterwards.
@(test)
test_ecs_destroy_entity_clears_all_registered_component_kinds :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.RigidBody)
    ecs.add_storage(&e, ^types.SquareCollider)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.RigidBody)
    defer ecs.delete_storage(&e, ^types.SquareCollider)

    entity := types.Entity(3)
    ecs.add_component(&e, entity, types.Transform{})
    ecs.add_component(&e, entity, types.RigidBody{})
    ecs.add_component(&e, entity, types.SquareCollider{})

    ecs.destroy_entity(&e, entity)

    _, ok1 := ecs.has_component(&e, entity, types.Transform)
    _, ok2 := ecs.has_component(&e, entity, types.RigidBody)
    _, ok3 := ecs.has_component(&e, entity, types.SquareCollider)
    testing.expect(t, !ok1)
    testing.expect(t, !ok2)
    testing.expect(t, !ok3)
}

// destroy_entity must leave other entities' components in the same
// storages untouched (guards against swap-remove index corruption).
@(test)
test_ecs_destroy_entity_does_not_affect_other_entities :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Transform)

    ecs.add_component(&e, 0, types.Transform{pos = {10, 10}})
    ecs.add_component(&e, 1, types.Transform{pos = {20, 20}})

    ecs.destroy_entity(&e, 0)

    got, ok := ecs.get_component(&e, 1, types.Transform)
    testing.expect(t, ok)
    testing.expect_value(t, got.pos.x, f32(20))
}

@(test)
test_ecs_get_gameobject_adds_default_transform_when_missing :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.Parent)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Parent)

    go, ok := ecs.get_gameobject(&e, 0)
    defer ecs.free_gameobject(go)

    testing.expect(t, ok)
    testing.expect_value(t, go.transform.size.x, f32(100))
    testing.expect_value(t, go.transform.size.y, f32(100))
}

@(test)
test_ecs_get_gameobject_resolves_parent_chain :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.Parent)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Parent)

    ecs.add_component(&e, 0, types.Transform{pos = {5, 5}})
    ecs.add_component(&e, 1, types.Parent{entity = 0})

    go, ok := ecs.get_gameobject(&e, 1)
    defer ecs.free_gameobject(go)

    testing.expect(t, ok)
    testing.expect(t, go.parent != nil)
    testing.expect_value(t, go.parent.entity, types.Entity(0))
    testing.expect_value(t, go.parent.transform.pos.x, f32(5))
}

// a self-referential Parent component would otherwise recurse forever;
// get_gameobject must detect it and fail instead.
@(test)
test_ecs_get_gameobject_rejects_self_parent_cycle :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.Parent)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Parent)

    ecs.add_component(&e, 0, types.Parent{entity = 0})

    go, ok := ecs.get_gameobject(&e, 0)
    testing.expect(t, !ok)
    testing.expect(t, go == nil)
}
