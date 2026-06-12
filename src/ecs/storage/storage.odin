package storage;

import core  "../ecs_core"

ComponentStorage :: struct($T: typeid) {
    sparse: [dynamic]int,
    dense:  [dynamic]T,
    entities: [dynamic]core.Entity,
}

NO_ENTITY :: -1

init_storage :: proc($T: typeid, capacity: int) -> ^ComponentStorage(T) {
    storage := new(ComponentStorage(T))
    return storage
}

add_component :: proc(storage: ^ComponentStorage($T), e:core. Entity, component: T) {
    id := int(e)
    for id >= len(storage.sparse) {
        append(&storage.sparse, NO_ENTITY)
    }
    storage.sparse[id] = len(storage.dense)
    append(&storage.dense, component)
    append(&storage.entities, e)
}

get_component :: proc(storage : ^ComponentStorage($T), e:core. Entity) -> (^T, bool) { 
    id := int(e)
    if id >= len(storage.sparse) || storage.sparse[id] == NO_ENTITY do return nil, false
    return &storage.dense[storage.sparse[id]], true
}

has_component :: proc(s: ^ComponentStorage($T), entity: core.Entity) -> (int, bool) {
    id := int(entity)
    return s.sparse[id], id < len(s.sparse) && s.sparse[id] != NO_ENTITY
}

delete_storage :: proc(storage : ^ComponentStorage($T)) {
    delete(storage.dense);
    delete(storage.entities);
    delete(storage.sparse);
    free(storage);
}
