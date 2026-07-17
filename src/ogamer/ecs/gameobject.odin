package ogamer_ecs;


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
    entity := get_new_entity(ecs)
    add_component(ecs, entity, NewTransform())
    

    transform := get_component(ecs, entity, Transform)
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
