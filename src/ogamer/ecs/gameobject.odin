package ogamer_ecs;

import "core:fmt"


GameObject :: struct {
    entity: Entity,
    transform: ^Transform,
    ecs: ^EntityComponentSystem,
}

gameobject_add_component :: proc(go: GameObject, component: $T) {
    add_component(go.ecs, go.entity, component)
}
gameobject_get_component :: proc(go: GameObject, component: $T) -> ^T {
    return get_component(go.ecs, go.entity, component)
}


new_gameobject :: proc(ecs: ^EntityComponentSystem) -> GameObject {
    entity    := get_new_entity(ecs)
    transform := add_component(ecs, entity, NewTransform())

    fmt.println("INFO: new gameobject @", entity)

    return GameObject({
        entity=entity,
        ecs = ecs,
        transform = transform
    })
}


get_gameobject :: proc(ecs: ^EntityComponentSystem, entity: Entity) -> GameObject {
    transform := get_component(ecs, entity, Transform)
    return GameObject({
        entity=entity,
        ecs = ecs,
        transform = transform
    })
}

add_child :: proc(parent, child: GameObject){
    gameobject_add_component(child, NewParent(parent.entity))
}
