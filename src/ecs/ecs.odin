package ecs;

import stor "./storage"
import "../types"
import "core:fmt"


delete_storage :: proc(storages: ^types.ECS, $T: typeid) {
    storage, ok := get_storage(storages, T)
    if ok {
        stor.delete_storage(storage);
    }
}

add_storage :: proc(s: ^types.ECS, $T: typeid) {
    id := typeid_of(T)
    storage := stor.init_storage(T, 1024);
    s.storages[id] = cast(rawptr)storage
}

get_storage :: proc(s: ^types.ECS, $T: typeid) -> (^stor.ComponentStorage(T), bool) {
    id := typeid_of(T)
    ptr, ok := s.storages[id]

    return cast(^stor.ComponentStorage(T))ptr, ok
}

/**
It will copy the memory and allocate new for the component!
*/
add_component :: proc(s: ^types.ECS, entity: u32, component: $T) -> (^T, bool) {
    
    storage, ok := get_storage(s,^T);
    if !ok {
        return nil, false
    }
    component := component; // do this so we can pass the adress
    return stor.add_component(storage, entity, &component), true; 
}

has_component :: proc(s: ^types.ECS, entity: u32, $T: typeid) -> (int, bool) {
    storage, ok := get_storage(s,^T);
    if !ok do return 0, false
    return stor.has_component(storage, entity);
}

get_component :: proc(s: ^types.ECS, entity: u32, $T: typeid) -> (^T, bool) {
    storage, ok := get_storage(s,^T);
    if !ok do return nil, false
    comp, ok2 := stor.get_component(storage, entity);
    if !ok2 do return nil, false
    return comp, true
}

get_gameobject :: proc(ecs_: ^types.ECS, entity: types.Entity) -> (^types.GameObject, bool) {
    game_object := new(types.GameObject)

    trans, ok := get_component(ecs_, entity, types.Transform);
    if !ok {
        trans, _ = add_component(ecs_, entity, types.Transform {size={100,100}});
    }

    parent, got_parent := get_component(ecs_, entity, types.Parent);
    if got_parent {
        if parent.entity == entity do return nil, false
        game_object.parent, _ = get_gameobject(ecs_, parent.entity);
    }
 
    game_object.transform = trans;
    game_object.entity = entity;
    game_object.ecs = ecs_;

    
    return game_object, true
}


