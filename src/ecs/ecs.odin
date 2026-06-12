package ecs;

import stor "./storage"
import core "./ecs_core"


// Holds storages for 
Storages :: struct {
    storages: map[typeid]rawptr, // rawptr -> ^ComponentStorage(T)
}

delete_storages :: proc(storages: ^Storages) {
    //delete_storage(storages.transform_storage);
}

add_storage :: proc(s: ^Storages, $T: typeid) {
    id := typeid_of(T)
    storage := stor.init_storage(T, 1024);
    s.storages[id] = storage
}

get_storage :: proc(s: ^Storages, $T: typeid) -> ^stor.ComponentStorage(T) {
    id := typeid_of(T)
    ptr, ok := s.storages[id]
    if !ok {
        return stor.init_storage(T, 1024);
    }
    return cast(^stor.ComponentStorage(T))ptr
}


add_component :: proc(s: ^Storages, entity: core.Entity, component: $T) -> T {
    storage := get_storage(s,T);
    stor.add_component(storage, entity, component);
    return component
}

get_component :: proc(s: ^Storages, entity: core.Entity, $T: typeid) -> ^T {
    storage := get_storage(s,T);
    return stor.get_component(storage, entity);
}

