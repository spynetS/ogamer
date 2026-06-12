package ecs;

import stor "./storage"
import core "./ecs_core"


// Holds storages for 
Storages :: struct {
    storages: map[typeid]rawptr, // rawptr -> ^ComponentStorage(T)
}

delete_storage :: proc(storages: ^Storages, $T: typeid) {
    storage, ok := get_storage(storages, T);
    if ok {
        stor.delete_storage(storage);
    }
}

add_storage :: proc(s: ^Storages, $T: typeid) {
    id := typeid_of(T)
    storage := stor.init_storage(T, 1024);
    s.storages[id] = cast(rawptr)storage
}

get_storage :: proc(s: ^Storages, $T: typeid) -> (^stor.ComponentStorage(T), bool) {
    id := typeid_of(T)
    ptr, ok := s.storages[id]

    return cast(^stor.ComponentStorage(T))ptr, ok
}


add_component :: proc(s: ^Storages, entity: core.Entity, component: $T) -> bool {
    storage, ok := get_storage(s,T);
    if !ok {
        return false
    }
    stor.add_component(storage, entity, component); 
    return true
}

get_component :: proc(s: ^Storages, entity: core.Entity, $T: typeid) -> ^T {
    storage, ok := get_storage(s,T);
    return stor.get_component(storage, entity);
}

