package ogamer_ecs;

import rn "../renderer/"
import "core:fmt"

// It is here we add new components to the whole ecs system
add_systems :: proc(ECS : ^EntityComponentSystem) {
    add_storage(ECS, Camera2D, camera_system)
    add_storage(ECS, Transform, nil)
    add_storage(ECS, ShapeRenderer, shape_render_system)
    add_storage(ECS, SpriteRenderer, sprite_render_system)
    add_storage(ECS, SpriteAnimator, sprite_animator_system)
    add_storage(ECS, Parent, parent_system)
    add_storage(ECS, UIText, ui_system)
    add_storage(ECS, UISpriteRenderer, ui_system)
    add_storage(ECS, Text, text_system)
    add_storage(ECS, Tag, nil)
    add_storage(ECS, MouseOverComponent, mouse_over_system)
    add_storage(ECS, Rigidbody, physics_system)
    add_storage(ECS, Collider, collider_system)
    add_storage(ECS, DepthSort, depth_sort_system)
    add_storage(ECS, ScriptComponent,
                script_system,
                before_destroy = proc (raw: rawptr) {
                    stor := cast(^ComponentStorage(ScriptComponent))raw
                    for i in 0..<len(stor.dense) {
                        delete(stor.dense[i].scripts)
                    } 
                })
}


add_component :: proc(ECS : ^EntityComponentSystem, entity: Entity, component: $T) -> ^T {
    holder, ok := get_storage_holder(ECS, T)
    if !ok do return nil
    defer {
        //fmt.println("INFO: added component",component, "to", entity)
        comp := component
        if holder.on_create != nil do holder.on_create(ECS, entity, &comp)
    }
    storage := cast(^ComponentStorage(T))holder.storage
    dense_index := len(storage.dense)
    
    append(&storage.dense, component)
    append(&storage.entities, entity)
    old_len := len(storage.sparse)
    
    if int(entity) >= old_len {
        resize(&storage.sparse, entity + 1)
        
        for i in old_len..<len(storage.sparse) {
            storage.sparse[i] = NO_ENTITY
        }
    }

    storage.sparse[entity] = dense_index
    return &storage.dense[dense_index]
}

get_component :: proc(ecs: ^EntityComponentSystem, entity: Entity, $T: typeid) -> (^T, bool) #optional_ok {
    storage, ok := get_storage(ecs, T)
    
    if !ok {
        return nil, false
    }

    if int(entity) >= len(storage.sparse) {
        return nil, false
    }

    dense_index := storage.sparse[entity]
    
    if dense_index == NO_ENTITY {
        return nil, false
    }

    return &storage.dense[dense_index], true
}

has_component :: proc(storage: ^ComponentStorage($T), entity: Entity) -> (int, bool) {
    has := int(entity) < len(storage.sparse) &&
         storage.sparse[entity] != NO_ENTITY

    if has do return storage.sparse[int(entity)], has
    else   do return -1, false
}

@(private)
get_storage_holder :: proc(ecs: ^EntityComponentSystem, $T: typeid) -> (^StorageHolder, bool){
    holder, ok := &ecs.storages[typeid_of(T)]
    if !ok do return nil, false
    return holder, true
}

@(private)
get_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid) -> (^ComponentStorage(T), bool){
    holder, ok := ecs.storages[typeid_of(T)]
    if !ok do return nil, false
    return cast(^ComponentStorage(T))holder.storage, true
}

@(private)
add_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid, update: SYSTEM_UPDATE_FUNCTION, on_create: ON_CREATE_COMPONENT = nil, before_destroy : DESTROY_COMPONENT_STORAGE = nil) {
    storage := new(ComponentStorage(T))
    ecs.storages[T] = StorageHolder({
        storage=storage,
        update=update,
        on_create=on_create,
        before_destroy = before_destroy,
        destroy = proc(raw: rawptr) {
            s := cast(^ComponentStorage(T))raw
            delete(s.sparse)
            delete(s.dense)
            delete(s.entities)
            free(s)
        },
        // This is really remove component 
        destroy_entity = proc(storage: rawptr, entity:Entity) {
            s := cast(^ComponentStorage(T))storage

            id := int(entity)

            // bounds + existence check
            if id >= len(s.sparse) || s.sparse[id] == NO_ENTITY {
                return
            }

            index      := s.sparse[id]
            last_index := len(s.dense) - 1
            last_entity := s.entities[last_index]

            s.dense[index]    = s.dense[last_index]
            s.entities[index] = last_entity

            pop(&s.dense)
            pop(&s.entities)

            // point the moved entity's sparse entry at its new index
            s.sparse[int(last_entity)] = index
            s.sparse[id] = NO_ENTITY
        }

    })

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

destroy_entity :: proc(ecs: ^EntityComponentSystem, entity:Entity ) {
    for key, holder in ecs.storages {
        holder.destroy_entity(holder.storage, entity)
    }
}

free_ecs :: proc (ecs: ^EntityComponentSystem) {
    for type, holder in ecs.storages {
        if holder.before_destroy != nil do holder.before_destroy(holder.storage)
        holder.destroy(holder.storage)
    }
    delete(ecs.storages)
    free(ecs)
}
