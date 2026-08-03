package ogamer_ecs;

import rn "../renderer/"
import  "../physics/"
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
    add_storage(ECS, Rigidbody, physics_system,
                 before_destroy_entity = proc(raw: rawptr, data: SystemData, entity: Entity) {
                     physics.destroy_body(data.ecs.world, entity)
                 }
               )
    add_storage(ECS, Collider,
                collider_system,
                before_destroy_entity = proc(raw: rawptr, data: SystemData, entity: Entity) {
                    physics.destroy_shape(data.ecs.world, entity)
    })
    add_storage(ECS, DepthSort, depth_sort_system)
    add_storage(ECS, ScriptComponent,
                script_system,
                before_destroy_entity = proc(raw: rawptr, data: SystemData, entity: Entity) {
                    stor := cast(^ComponentStorage(ScriptComponent))raw
                    comp := stor.dense[stor.sparse[entity]]
                    for script in comp.scripts{
                        if script.on_destroy != nil do script.on_destroy(ScriptData({script.data, get_gameobject(data.ecs, entity), data.ecs, data.eventQueue, data.ecs.world, data.renderer,0}))
                    }

                },
                before_destroy = proc (raw: rawptr, ecs: ^EntityComponentSystem) {
                    stor := cast(^ComponentStorage(ScriptComponent))raw
                    for i in 0..<len(stor.dense) {
                        delete(stor.dense[i].scripts)
                    } 
                })
}


add_component :: proc(ECS : ^EntityComponentSystem, entity: Entity, component: $T) -> ^T {
    holder, ok := get_storage_holder(ECS, T)
    if !ok do return nil
    if holder.storage == nil do return nil
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
add_storage :: proc(ecs: ^EntityComponentSystem, $T: typeid, update: SYSTEM_UPDATE_FUNCTION, before_destroy_entity : proc(raw: rawptr, data: SystemData, entity: Entity) = nil, before_destroy : DESTROY_COMPONENT_STORAGE = nil) {
    storage := new(ComponentStorage(T))
    ecs.storages[T] = StorageHolder({
        storage=storage,
        update=update,
        before_destroy = before_destroy,
        before_destroy_entity = before_destroy_entity,
        destroy = proc(raw: rawptr, ecs: ^EntityComponentSystem) {
            if raw == nil do return
            s := cast(^ComponentStorage(T))raw
            delete(s.sparse)
            delete(s.dense)
            delete(s.entities)
            free(s)
        },
        // This is really remove component 
        destroy_entity = proc(storage: rawptr, entity:Entity) {
            if storage == nil do return
            s := cast(^ComponentStorage(T))storage
            remove_component_storage(s, entity);
        }

    })

}
remove_component_storage :: proc (storage: ^ComponentStorage($T), entity: Entity) {
    id := int(entity)

    // bounds + existence check
    if id >= len(storage.sparse) || storage.sparse[id] == NO_ENTITY {
        return
    }

    index      := storage.sparse[id]
    last_index := len(storage.dense) - 1
    last_entity := storage.entities[last_index]

    // swap-remove: move last element into the removed slot
    storage.dense[index]    = storage.dense[last_index]
    storage.entities[index] = last_entity

    pop(&storage.dense)
    pop(&storage.entities)

    // point the moved entity's sparse entry at its new index
    storage.sparse[int(last_entity)] = index
    storage.sparse[id] = NO_ENTITY

}
remove_component_ecs :: proc (ecs: ^EntityComponentSystem, entity: Entity, $T: typeid) {

    storage, ok := get_storage(ecs, T);
    if !ok do return

    remove_component_storage(storage, entity);
}

update_systems :: proc(data: SystemData, dt: f32) {
    for type, &holder in data.ecs.storages {
        for destroy_entity in holder.destroy_queue {
            assert(holder.destroy_entity != nil)
            if holder.before_destroy_entity != nil do holder.before_destroy_entity(holder.storage, data, destroy_entity)
            holder.destroy_entity(holder.storage, destroy_entity)
        }
        clear(&holder.destroy_queue)
        
        if holder.update != nil do holder.update(data, dt)
    }
}

get_new_entity :: proc(ecs: ^EntityComponentSystem) -> Entity {
    ecs.entity_counter += 1
    return ecs.entity_counter
}

destroy_entity :: proc(ecs: ^EntityComponentSystem, entity:Entity ) {
    for key, &holder in ecs.storages {
        append(&holder.destroy_queue, entity)
    }
}

free_ecs :: proc (ecs: ^EntityComponentSystem) {
    for type, holder in ecs.storages {
        if holder.before_destroy != nil do holder.before_destroy(holder.storage, ecs)
        if holder.destroy        != nil do holder.destroy(holder.storage, ecs)
    }
    delete(ecs.storages)
    free(ecs)
}
