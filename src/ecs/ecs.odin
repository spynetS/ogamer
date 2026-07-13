package ecs;

import stor "./storage"
import "../types"
import "core:fmt"
import es "../event-system/"

// Hooks invoked with the component pointer right before that component's memory
// is freed, so lower layers (e.g. the physics system) can release native
// resources keyed by the pointer. Set by the owning system at init; nil = no-op.
// Needed because `systems` imports `ecs`, so `ecs` can't call into it directly.
on_rigidbody_removed : proc(rigid: ^types.RigidBody)
on_collider_removed  : proc(collider: ^types.SquareCollider)
MAX_HIERARCHY_DEPTH :: 50

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

get_new_entity :: proc(ecs: ^types.ECS) -> types.Entity {
    ecs.entities += 1
    return ecs.entities
}

/**
It will copy the memory and allocate new for the component!
*/
add_component :: proc(s: ^types.ECS, entity: u32, component: $T) -> (^T, bool) {
    
    storage, ok := get_storage(s,^T);
    if !ok {
        fmt.println("WARNING: no storage for", component)
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

// An entity survives clearing if it, or any ancestor in its parent chain,
// carries a Persistent marker. Walking the whole chain (not just the direct
// parent) keeps grandchildren and deeper subtrees intact when their root is
// marked persistent.
is_persistent :: proc(ecs: ^types.ECS, entity: u32) -> bool {
    e := entity
    hops := 0
    for {
        if _, has := has_component(ecs, e, types.Persistent); has do return true
        parent, has_parent := get_component(ecs, e, types.Parent)
        if !has_parent do return false
        if parent.entity == e do return false // guard against self-parenting cycle
        e = parent.entity
        if hops > MAX_HIERARCHY_DEPTH do return false // or log/assert
    }
}

clear_all_entities :: proc(ecs: ^types.ECS) {
    t_storage, exists := get_storage(ecs, ^types.Transform)
    if !exists do return
    i := 0
    for i < len(t_storage.dense) {
        entity := t_storage.entities[i]
        if is_persistent(ecs, entity) {
            fmt.println("SKIPED", entity)
            i += 1                 // skip persistent entities, advance
            continue
        }
        destroy_entity(ecs, entity)   // swap-remove: don't advance i
    }
}

remove_component :: proc(ecs: ^types.ECS, entity: u32, $T: typeid) {
    storage, storage_ok := get_storage(ecs, ^T)
    if !storage_ok do return
    stor.remove_component(storage, entity);
}

destroy_entity :: proc(ecs: ^types.ECS, entity: u32) {
    script, script_ok := get_storage(ecs, ^types.Script)
    if script_ok {
        go, ok := get_gameobject(ecs, entity)
        if !ok {
            fmt.println("ABOW");
        }
        script_comp, got_component := stor.get_component(script, entity)
        if got_component {
            if script_comp.on_destroy != nil do script_comp.on_destroy(go^, script_comp.data)
        }
        else do fmt.println("WARNING: could not fetch script component on destroy") 

        stor.destroy_entity(script, entity)
    }

    transform, transform_ok := get_storage(ecs, ^types.Transform)
    if transform_ok do stor.destroy_entity(transform, entity)

    // Release the box2d body/shape before the component memory is freed,
    // otherwise the physics maps keyed by this pointer would dangle.
    rigid_body, rigid_body_ok := get_storage(ecs, ^types.RigidBody)
    if rigid_body_ok {
        if comp, ok := stor.get_component(rigid_body, entity); ok && on_rigidbody_removed != nil {
            on_rigidbody_removed(comp)
        }
        stor.destroy_entity(rigid_body, entity)
    }

    square_collider, square_collider_ok := get_storage(ecs, ^types.SquareCollider)
    if square_collider_ok {
        if comp, ok := stor.get_component(square_collider, entity); ok && on_collider_removed != nil {
            on_collider_removed(comp)
        }
        stor.destroy_entity(square_collider, entity)
    }

    rect_renderable, rect_renderable_ok := get_storage(ecs, ^types.RectangleRenderable)
    if rect_renderable_ok do stor.destroy_entity(rect_renderable, entity)

    sprite_renderable, sprite_renderable_ok := get_storage(ecs, ^types.SpriteRenderable)
    if sprite_renderable_ok do stor.destroy_entity(sprite_renderable, entity)

    parent, parent_ok := get_storage(ecs, ^types.Parent)
    if parent_ok do stor.destroy_entity(parent, entity)


    camera, camera_ok := get_storage(ecs, ^types.Camera2D)
    if camera_ok do stor.destroy_entity(camera, entity)

    sprite_animator, sprite_animator_ok := get_storage(ecs, ^types.SpriteAnimator)
    if sprite_animator_ok do stor.destroy_entity(sprite_animator, entity)

    // Tilemaps and text were missing from teardown; without this a destroyed
    // floor/HUD entity keeps its component in storage and stays on screen.
    tilemap, tilemap_ok := get_storage(ecs, ^types.TileMap)
    if tilemap_ok do stor.destroy_entity(tilemap, entity)

    text, text_ok := get_storage(ecs, ^types.TextElement)
    if text_ok do stor.destroy_entity(text, entity)

    uisprite, uisprite_ok := get_storage(ecs, ^types.UiSprite)
    if uisprite_ok do stor.destroy_entity(uisprite, entity)
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
        if parent.entity == entity {
            free(game_object)
            return nil, false
        }
        game_object.parent, _ = get_gameobject(ecs_, parent.entity);
    }
 
    game_object.transform = trans;
    game_object.entity = entity;
    game_object.ecs = ecs_;


    return game_object, true
}

/**
Frees a GameObject obtained from get_gameobject, including the parent
chain it allocates. Do NOT use this on GameObjects whose parent was set
via add_child (those parent pointers are shared, not owned).
*/
free_gameobject :: proc(game_object: ^types.GameObject) {
    if game_object == nil do return
    free_gameobject(game_object.parent)
    free(game_object)
}


