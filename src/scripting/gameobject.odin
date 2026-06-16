package scripting;

import "core:fmt"

import stor "../ecs/storage/"
import "../ecs"
import "../ecs/types"

GameObject :: struct {
    entity: types.Entity,
    transform: ^types.Transform, // ecs should handle the transform memory
    parent: ^GameObject,
    ecs: ^ecs.ECS,
}

new_gameobject :: proc(ecs_: ^ecs.ECS) -> (^GameObject, bool) {
    game_object := new(GameObject)

    t_storage, ok := ecs.get_storage(ecs_, ^types.Transform)
    entity := types.Entity(len(t_storage.entities))
    append(&t_storage.entities, entity)

    game_object.entity = entity
    game_object.ecs = ecs_
    game_object.transform, _ = ecs.add_component(ecs_, entity, types.Transform {size={100,100}});
    return game_object, true
}

get_gameobject :: proc(ecs_: ^ecs.ECS, entity: types.Entity) -> (^GameObject, bool) {
    game_object := new(GameObject)

    trans, ok := ecs.get_component(ecs_, entity, types.Transform);
    if !ok {
        trans, _ = ecs.add_component(ecs_, entity, types.Transform {size={100,100}});
    }

    parent, got_parent := ecs.get_component(ecs_, entity, types.Parent);
    if got_parent {
        if parent.entity == entity do return nil, false
        game_object.parent, _ = get_gameobject(ecs_, parent.entity);
    }
 
    game_object.transform = trans;
    game_object.entity = entity;
    game_object.ecs = ecs_;

    
    return game_object, true
}

new_renderobject :: proc(e: ^ecs.ECS) -> (^GameObject, bool){
    go, created := new_gameobject(e);
    add_component(go, types.RectangleRenderable({color={24,24,24,255}}))
    return go, created
}

add_component :: proc(game_object: ^GameObject, component: $T) {
    ecs.add_component(game_object.ecs, game_object.entity, component);
}

/** this procedure does not free the components atteched to the entity */
free_gameobject :: proc(game_object: ^GameObject) {
    free(game_object);
}

add_child :: proc(game_object: ^GameObject, child: ^GameObject) {
    add_component(child, types.Parent({entity=game_object.entity}));
    child.parent = game_object
}
