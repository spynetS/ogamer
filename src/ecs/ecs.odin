package ecs;

import stor "./storage"
import "core:fmt"

Event_Type :: enum {
    RigidBody,
    Collider,
}

ECS :: struct {
    storages: map[typeid]rawptr, // rawptr -> ^ComponentStorage(T)
}

// TODO change this to more
Script :: struct {
    on_update: proc(ecs: ^ECS, entity: u32, dt: f32),
}

delete_storage :: proc(storages: ^ECS, $T: typeid) {
    storage, ok := get_storage(storages, T)
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

/**
It will copy the memory and allocate new for the component!
*/
add_component :: proc(s: ^ECS, entity: u32, component: $T) -> (^T, bool) {
    
    storage, ok := get_storage(s,^T);
    if !ok {
        return nil, false
    }
    component := component; // do this so we can pass the adress
    return stor.add_component(storage, entity, &component), true; 
}

has_component :: proc(s: ^ECS, entity: u32, $T: typeid) -> (int, bool) {
    storage, ok := get_storage(s,^T);
    if !ok do return 0, false
    return stor.has_component(storage, entity);
}

get_component :: proc(s: ^ECS, entity: u32, $T: typeid) -> (^T, bool) {
    storage, ok := get_storage(s,^T);
    if !ok do return nil, false
    comp, ok2 := stor.get_component(storage, entity);
    if !ok2 do return nil, false
    return comp, true
}

