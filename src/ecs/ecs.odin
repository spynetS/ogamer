package ecs;

import stor "./storage"
import core "./ecs_core"



ECS :: struct {
    storages: map[typeid]rawptr, // rawptr -> ^ComponentStorage(T)
}

// TODO change this to more
Script :: struct {
    on_update: proc(ecs: ^ECS, entity: core.Entity, dt: f32),
}


delete_storage :: proc(storages: ^ECS, $T: typeid) {
    storage, ok := get_storage(storages, T);
    if ok {
        stor.delete_storage(storage);
    }
}

add_storage :: proc(s: ^ECS, $T: typeid) {
    id := typeid_of(T)
    storage := stor.init_storage(T, 1024);
    s.storages[id] = cast(rawptr)storage
}

get_storage :: proc(s: ^ECS, $T: typeid) -> (^stor.ComponentStorage(T), bool) {
    id := typeid_of(T)
    ptr, ok := s.storages[id]

    return cast(^stor.ComponentStorage(T))ptr, ok
}


add_component :: proc(s: ^ECS, entity: core.Entity, component: $T) -> bool {
    
    storage, ok := get_storage(s,T);
    if !ok {
        return false
    }
    stor.add_component(storage, entity, component); 
    return true
}

has_component :: proc(s: ^ECS, entity: core.Entity, $T: typeid) -> (int, bool) {
    storage, ok := get_storage(s,T);
    if !ok do return nil, false
    return stor.has_component(storage, entity);
}

get_component :: proc(s: ^ECS, entity: core.Entity, $T: typeid) -> (^T, bool) {
    storage, ok := get_storage(s,T);
    if !ok do return nil, false
    return stor.get_component(storage, entity);
}

