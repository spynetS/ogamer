package tests

import "core:testing"
import stor "../src/ecs/storage"

Position :: struct {
    x, y: f32,
}

@(test)
test_storage_add_and_get_component :: proc(t: ^testing.T) {
    storage := stor.init_storage(^Position, 4)
    defer stor.delete_storage(storage)

    pos := Position{x = 1, y = 2}
    added := stor.add_component(storage, 0, &pos)
    testing.expect_value(t, added.x, f32(1))
    testing.expect_value(t, added.y, f32(2))

    got, ok := stor.get_component(storage, 0)
    testing.expect(t, ok)
    testing.expect_value(t, got.x, f32(1))
    testing.expect_value(t, got.y, f32(2))

    // the storage must own its own copy, not alias the caller's local
    testing.expect(t, got != &pos)
}

@(test)
test_storage_get_component_missing_entity :: proc(t: ^testing.T) {
    storage := stor.init_storage(^Position, 4)
    defer stor.delete_storage(storage)

    _, ok := stor.get_component(storage, 7)
    testing.expect(t, !ok)
}

@(test)
test_storage_has_component :: proc(t: ^testing.T) {
    storage := stor.init_storage(^Position, 4)
    defer stor.delete_storage(storage)

    _, ok := stor.has_component(storage, 5)
    testing.expect(t, !ok)

    pos := Position{}
    stor.add_component(storage, 5, &pos)

    _, ok2 := stor.has_component(storage, 5)
    testing.expect(t, ok2)
}

// add_component/remove_component use a swap-remove against the dense array;
// removing a non-last entity must not corrupt the entities that get swapped in.
@(test)
test_storage_swap_remove_keeps_other_entities_intact :: proc(t: ^testing.T) {
    storage := stor.init_storage(^Position, 4)
    defer stor.delete_storage(storage)

    p0 := Position{x = 0}
    p1 := Position{x = 1}
    p2 := Position{x = 2}
    stor.add_component(storage, 0, &p0)
    stor.add_component(storage, 1, &p1)
    stor.add_component(storage, 2, &p2)

    stor.remove_component(storage, 1)

    _, ok := stor.get_component(storage, 1)
    testing.expect(t, !ok)

    got0, ok0 := stor.get_component(storage, 0)
    testing.expect(t, ok0)
    testing.expect_value(t, got0.x, f32(0))

    got2, ok2 := stor.get_component(storage, 2)
    testing.expect(t, ok2)
    testing.expect_value(t, got2.x, f32(2))

    testing.expect_value(t, len(storage.dense), 2)
    testing.expect_value(t, len(storage.entities), 2)
}

@(test)
test_storage_destroy_entity_allows_readd :: proc(t: ^testing.T) {
    storage := stor.init_storage(^Position, 4)
    defer stor.delete_storage(storage)

    p := Position{x = 9}
    stor.add_component(storage, 3, &p)
    stor.destroy_entity(storage, 3)

    _, ok := stor.get_component(storage, 3)
    testing.expect(t, !ok)

    p2 := Position{x = 42}
    stor.add_component(storage, 3, &p2)

    got, ok2 := stor.get_component(storage, 3)
    testing.expect(t, ok2)
    testing.expect_value(t, got.x, f32(42))
}

@(test)
test_storage_remove_on_untracked_entity_is_noop :: proc(t: ^testing.T) {
    storage := stor.init_storage(^Position, 4)
    defer stor.delete_storage(storage)

    // must not panic/underflow on an entity id that was never added
    stor.remove_component(storage, 999)
    testing.expect_value(t, len(storage.dense), 0)
}
