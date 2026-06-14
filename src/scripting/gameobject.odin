package scripting;

import ec "../ecs/ecs_core/"
import "../ecs"

GameObject :: struct {
    entity: ec.Entity,
    transform: ^ec.Transform, // ecs should handle the transform memory
    ecs: ^ecs.ECS,
}

get_gameobject :: proc(ecs_: ^ecs.ECS, entity: ec.Entity) -> (^GameObject, bool) {
    game_object := new(GameObject)

    trans, ok := ecs.get_component(ecs_, entity, ec.Transform);
    if !ok {
        trans = &ec.Transform {{100,100}, {100,100}, {0,0}}
        ecs.add_component(ecs_, entity, trans^);
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
// TODO free theise entites
free_gameobject :: proc(game_object: ^GameObject) {
    free(game_object);
}
