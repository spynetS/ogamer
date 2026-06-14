package storage;

import "core:mem"
import "core:fmt"

Entity :: u32;

/*
ComponentStorage HANDLES MEMORY BY IT SELF for each component
The user should pass a pointer to a component but theft
component storage will copy that memory!
*/


ComponentStorage :: struct($T: typeid) {
    sparse: [dynamic]int,
    dense:  [dynamic]T,
    entities: [dynamic]Entity,
}

NO_ENTITY :: -1

init_storage :: proc($T: typeid, capacity: int) -> ^ComponentStorage(T) {
    storage := new(ComponentStorage(T))
    return storage
}

add_component :: proc(storage: ^ComponentStorage($T), e:Entity, component: T) -> T{
    id := int(e)
    for id >= len(storage.sparse) {
        append(&storage.sparse, NO_ENTITY)
    }
    storage.sparse[id] = len(storage.dense)
 
    copy_component := new_clone(component^)
    
    append(&storage.dense, copy_component)
    append(&storage.entities, e)
    return copy_component;
}

get_component :: proc(storage : ^ComponentStorage($T), e: Entity) -> (T, bool) { 
    id := int(e)
    if id >= len(storage.sparse) || storage.sparse[id] == NO_ENTITY do return nil, false
    //fmt.println(storage.sparse[id])
    return storage.dense[storage.sparse[id]], true
}

has_component :: proc(s: ^ComponentStorage($T), entity: Entity) -> (int, bool) {
    id := int(entity)
    return s.sparse[id], id < len(s.sparse) && s.sparse[id] != NO_ENTITY
}

delete_storage :: proc(storage : ^ComponentStorage($T)) {
    for comp in storage.dense {
        free(comp)
    }
    delete(storage.dense);
    delete(storage.entities);
    delete(storage.sparse);
    free(storage);
}
