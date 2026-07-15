package ogamer_ecs;

import "./components/"
import "core:fmt"

// It is here we add new components to the whole ecs system
add_systems :: proc(ECS : ^EntityComponentSystem) {
    add_storage(ECS, components.Transform, transform_system)
}


// TODO add error code
add_component :: proc(ECS : ^EntityComponentSystem, entity: Entity, component: $T) {
    storage, ok := get_storage(ECS, T)
    if !ok do return 
    dense_index := len(storage.dense)

    append(&storage.dense, component)
    append(&storage.entities, entity)

    if int(entity) >= len(storage.sparse) {
        resize(&storage.sparse, entity + 1)
    }

    storage.sparse[entity] = dense_index
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

has_component :: proc(storage: ^ComponentStorage($T), entity: Entity) -> bool {
    return entity < len(storage.sparse) &&
        storage.sparse[entity] != -1
}

@(private)
get_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid) -> (^ComponentStorage(T), bool) {
    holder, ok := ecs.storages[typeid_of(T)]
    if !ok do return nil, false
    return cast(^ComponentStorage(T))holder.storage, true
}

@(private)
add_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid, update: SYSTEM_UPDATE_FUNCTION) {
    storage := new(ComponentStorage(T))
    ecs.storages[T] = StorageHolder({
        storage=storage,
        update=update,
        destroy = proc(raw: rawptr) {
            s := cast(^ComponentStorage(T))raw
            delete(s.sparse)
            delete(s.dense)
            delete(s.entities)
            free(s)
        }})
}


update_systems :: proc(ecs: ^EntityComponentSystem) {
    for type, holder in ecs.storages {
        holder.update(ecs, 0.16)
    }
}

get_new_entity :: proc(ecs: ^EntityComponentSystem) -> Entity {
    ecs.entity_counter += 1
    return ecs.entity_counter
}

free_ecs :: proc (ecs: ^EntityComponentSystem) {
    for type, holder in ecs.storages {
        holder.destroy(holder.storage)
    }
    delete(ecs.storages)
    free(ecs)
}
