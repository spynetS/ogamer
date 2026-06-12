package storage;

import core  "../ecs_core"

ComponentStorage :: struct($T: typeid) {
    sparse: map[core.Entity]int,
    dense:  [dynamic]T,
    entities: [dynamic]core.Entity,
}

init_storage :: proc($T: typeid, capacity: int) -> ^ComponentStorage(T) {
    storage := new(ComponentStorage(T))
    return storage
}

add_component :: proc(storage: ^ComponentStorage($T), e:core. Entity, value: T) {
    storage.sparse[e] = len(storage.dense)
    append(&storage.dense, value)
    append(&storage.entities, e)
}

get_component :: proc(storage : ^ComponentStorage($T), e:core. Entity) -> (^T, bool) { 
    index, ok := storage.sparse[e]
    if !ok {
        return nil, false
    }
    return &storage.dense[index], true
}


delete_storage :: proc(storage : ^ComponentStorage($T)) {
    delete(storage.dense);
    delete(storage.entities);
    delete(storage.sparse);
    free(storage);
}
