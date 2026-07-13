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
    sparse         : [dynamic]int,
    dense          : [dynamic]T,
    entities       : [dynamic]Entity,
    entity_by_comp : map[T]Entity
}

NO_ENTITY :: -1

// TODO add delete entity!
destroy_entity :: proc(storage: ^ComponentStorage($T), entity:Entity) {
    id := int(entity)
    remove_component(storage, entity)
}

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

    storage.entity_by_comp[copy_component] = e
    append(&storage.dense, copy_component)
    append(&storage.entities, e)

    return copy_component;
}

remove_component :: proc(storage: ^ComponentStorage($T), entity: Entity) {
    id := int(entity)

    // bounds + existence check
    if id >= len(storage.sparse) || storage.sparse[id] == NO_ENTITY {
        return
    }

    index      := storage.sparse[id]
    last_index := len(storage.dense) - 1
    last_entity := storage.entities[last_index]

    // clean up the reverse lookup map and free the removed component's
    // backing memory before we overwrite dense[index]
    delete_key(&storage.entity_by_comp, storage.dense[index])
    free(storage.dense[index])

    // swap-remove: move last element into the removed slot
    storage.dense[index]    = storage.dense[last_index]
    storage.entities[index] = last_entity

    pop(&storage.dense)
    pop(&storage.entities)

    // point the moved entity's sparse entry at its new index
    storage.sparse[int(last_entity)] = index
    storage.sparse[id] = NO_ENTITY
}

get_component :: proc(storage : ^ComponentStorage($T), e: Entity) -> (T, bool) { 
    id := int(e)
    if id >= len(storage.sparse) || storage.sparse[id] == NO_ENTITY do return nil, false
    //fmt.println(storage.sparse[id])
    return storage.dense[storage.sparse[id]], true
}

has_component :: proc(s: ^ComponentStorage($T), entity: Entity) -> (int, bool) {
    id := int(entity)
    has := id < len(s.sparse) && s.sparse[id] != NO_ENTITY
    return has ? s.sparse[id] : -1, has
}

delete_storage :: proc(storage : ^ComponentStorage($T)) {
    for comp in storage.dense {
        free(comp)
    }
    delete(storage.dense);
    delete(storage.entities);
    delete(storage.sparse);
    delete(storage.entity_by_comp);
    free(storage);
}
