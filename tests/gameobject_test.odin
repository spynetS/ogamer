package tests

import "core:testing"
import "../src/ecs"
import "../src/types"
import sc "../src/scripting"

@(test)
test_new_gameobject_gets_default_transform :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Transform)

    go, ok := sc.new_gameobject(&e)
    defer free(go)

    testing.expect(t, ok)
    testing.expect_value(t, go.transform.size.x, f32(100))
    testing.expect_value(t, go.transform.size.y, f32(100))
}

@(test)
test_add_child_links_parent_component_and_pointer :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.Parent)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Parent)

    parent, _ := sc.new_gameobject(&e)
    defer free(parent)
    child, _ := sc.new_gameobject(&e)
    defer free(child)

    sc.add_child(parent, child)

    testing.expect(t, child.parent == parent)

    parent_comp, ok := ecs.get_component(&e, child.entity, types.Parent)
    testing.expect(t, ok)
    testing.expect_value(t, parent_comp.entity, parent.entity)
}

@(test)
test_get_children_finds_only_direct_children :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.Parent)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Parent)

    parent, _ := sc.new_gameobject(&e)
    defer free(parent)
    child, _ := sc.new_gameobject(&e)
    defer free(child)
    unrelated, _ := sc.new_gameobject(&e)
    defer free(unrelated)

    sc.add_child(parent, child)

    children := sc.get_children(parent)
    defer {
        for c in children do ecs.free_gameobject(c)
        delete(children)
    }

    testing.expect_value(t, len(children), 1)
    testing.expect_value(t, children[0].entity, child.entity)
}

@(test)
test_get_child_components_returns_components_of_children_only :: proc(t: ^testing.T) {
    e: types.ECS
    defer delete(e.storages)
    ecs.add_storage(&e, ^types.Transform)
    ecs.add_storage(&e, ^types.Parent)
    ecs.add_storage(&e, ^types.SquareCollider)
    defer ecs.delete_storage(&e, ^types.Transform)
    defer ecs.delete_storage(&e, ^types.Parent)
    defer ecs.delete_storage(&e, ^types.SquareCollider)

    parent, _ := sc.new_gameobject(&e)
    defer free(parent)
    child, _ := sc.new_gameobject(&e)
    defer free(child)
    stranger, _ := sc.new_gameobject(&e)
    defer free(stranger)

    sc.add_child(parent, child)
    sc.add_component(child, types.SquareCollider{trigger = true})
    sc.add_component(stranger, types.SquareCollider{trigger = false})

    colliders := sc.get_child_components(parent, types.SquareCollider)
    defer delete(colliders)

    testing.expect_value(t, len(colliders), 1)
    testing.expect(t, colliders[0].trigger)
}
