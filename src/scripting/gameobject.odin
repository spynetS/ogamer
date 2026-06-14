package scripting;

import "core:fmt"

import stor "../ecs/storage/"
import "../ecs"

GameObject :: struct {
    entity: ecs.Entity,
    transform: ^ecs.Transform, // ecs should handle the transform memory
    parent: ^GameObject,
    ecs: ^ecs.ECS,
}

new_gameobject :: proc(ecs_: ^ecs.ECS) -> (^GameObject, bool) {
    game_object := new(GameObject)

    t_storage, ok := ecs.get_storage(ecs_, ^ecs.Transform)
    entity := ecs.Entity(len(t_storage.entities))
    append(&t_storage.entities, entity)

    game_object.entity = entity
    game_object.ecs = ecs_
    game_object.transform, _ = ecs.add_component(ecs_, entity, ecs.Transform {{100,100}, {0,0}, {100,100}, {0,0}, 0});
    return game_object, true
}

get_gameobject :: proc(ecs_: ^ecs.ECS, entity: ecs.Entity) -> (^GameObject, bool) {
    game_object := new(GameObject)

    trans, ok := ecs.get_component(ecs_, entity, ecs.Transform);
    if !ok {
        trans, _ = ecs.add_component(ecs_, entity, ecs.Transform {{100,100}, {0,0}, {100,100}, {0,0}, 0});
    }

    parent, got_parent := ecs.get_component(ecs_, entity, ecs.Parent);
    if got_parent {
        if parent.entity == entity do return nil, false
        game_object.parent, _ = get_gameobject(ecs_, parent.entity);
    }
 
    game_object.transform = trans;
    game_object.entity = entity;
    game_object.ecs = ecs_;

    
    return game_object, true
}

add_component :: proc(game_object: ^GameObject, component: $T) {
    ecs.add_component(game_object.ecs, game_object.entity, component);
}

/** this procedure does not free the components atteched to the entity */
free_gameobject :: proc(game_object: ^GameObject) {
    free(game_object);
}

add_child :: proc(game_object: ^GameObject, child: ^GameObject) {
    add_component(child, ecs.Parent({game_object.entity}));
    child.parent = game_object
}
