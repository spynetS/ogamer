package ecs;

import "core:fmt"


Entity :: u32;
Vector2 :: [2]f32;

ComponentStorage :: struct($T: typeid) {
    sparse: map[Entity]int,
    dense:  [dynamic]T,
    entities: [dynamic]Entity,
}

init_storage :: proc($T: typeid, capacity: int) -> ^ComponentStorage(T) {
    storage := new(ComponentStorage(T))
    storage^ = ComponentStorage(T){
        sparse   = make(map[Entity]int),
        // dense    = make([]T, 0),
        // entities = make([]Entity, 0),
    }
    return storage
}
add_component :: proc(storage: ^ComponentStorage($T), e: Entity, value: T) {
    fmt.println(value)
    storage.sparse[e] = len(storage.dense)
    append(&storage.dense, value)
    append(&storage.entities, e)
}

get_component :: proc(storage : ^ComponentStorage($T), e: Entity) -> ^T { 
    index, ok := storage.sparse[e]
    if !ok {
        return nil
    }
    return &storage.dense[index]
}


delete_storage :: proc(storage : ^ComponentStorage($T)) {
    delete(storage.dense);
    delete(storage.entities);
    delete(storage.sparse);
}
