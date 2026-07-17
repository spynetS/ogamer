package ogamer_ecs;

import rn "../renderer/"
import "core:fmt"

// It is here we add new components to the whole ecs system
add_systems :: proc(ECS : ^EntityComponentSystem) {
    add_storage(ECS, Transform, nil)
    add_storage(ECS, ShapeRenderer, shape_render_system)
    add_storage(ECS, SpriteRenderer, sprite_render_system)
    add_storage(ECS, SpriteAnimator, sprite_animator_system)
    add_storage(ECS, Parent, parent_system)
    add_storage(ECS, Camera2D, camera_system)
    add_storage(ECS, UIText, ui_system)
    add_storage(ECS, Text, text_system)
    add_storage(ECS, ScriptComponent, script_system, before_destroy = proc (raw: rawptr) {
        stor := cast(^ComponentStorage(ScriptComponent))raw
        for i in 0..<len(stor.dense) {
            delete(stor.dense[i].scripts)
        }
    })
}


add_component :: proc(ECS : ^EntityComponentSystem, entity: Entity, component: $T) -> ^T {
    storage, ok := get_storage(ECS, T)
    if !ok do return nil
    dense_index := len(storage.dense)

    append(&storage.dense, component)
    append(&storage.entities, entity)

    if int(entity) >= len(storage.sparse) {
        resize(&storage.sparse, entity + 1)
    }

    storage.sparse[entity] = dense_index
    return &storage.dense[dense_index]
}

get_component :: proc(ecs: ^EntityComponentSystem, entity: Entity, $T: typeid) -> ^T {
    storage, ok := get_storage(ecs, T)
    
    if !ok {
        return nil
    }

    if int(entity) >= len(storage.sparse) {
        return nil
    }

    dense_index := storage.sparse[entity]

    if dense_index == -1 {
        return nil
    }

    return &storage.dense[dense_index]
}

has_component :: proc(storage: ^ComponentStorage($T), entity: Entity) -> (int, bool) {
    has := int(entity) < len(storage.sparse) &&
        storage.sparse[entity] != -1
    
    if has do return storage.sparse[int(entity)], has
    else   do return -1, false
}

@(private)
get_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid) -> (^ComponentStorage(T), bool){
    holder, ok := ecs.storages[typeid_of(T)]
    if !ok do return nil, false
    return cast(^ComponentStorage(T))holder.storage, true
}

@(private)
add_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid, update: SYSTEM_UPDATE_FUNCTION, before_destroy : DESTROY_COMPONENT_STORAGE = nil) {
    storage := new(ComponentStorage(T))
    ecs.storages[T] = StorageHolder({
        storage=storage,
        update=update,
        before_destroy = before_destroy,
        destroy = proc(raw: rawptr) {
            s := cast(^ComponentStorage(T))raw
            delete(s.sparse)
            delete(s.dense)
            delete(s.entities)
            free(s)
        }})

}


update_systems :: proc(data: SystemData, dt: f32) {
    for type, holder in data.ecs.storages {
        if holder.update != nil do holder.update(data, dt)
    }
}

get_new_entity :: proc(ecs: ^EntityComponentSystem) -> Entity {
    ecs.entity_counter += 1
    return ecs.entity_counter
}

free_ecs :: proc (ecs: ^EntityComponentSystem) {
    for type, holder in ecs.storages {
        if holder.before_destroy != nil do holder.before_destroy(holder.storage)
        holder.destroy(holder.storage)
    }
    delete(ecs.storages)
    free(ecs)
}
