package ogamer_ecs;

import "core:fmt"


GameObject :: struct {
    entity: Entity,
    transform: ^Transform,
    ecs: ^EntityComponentSystem,
}

gameobject_add_component :: proc(go: GameObject, component: $T)  -> ^T {
    return add_component(go.ecs, go.entity, component)
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
    fmt.println("INFO: adding", child.entity, "as child to", parent.entity)
    gameobject_add_component(child, NewParent(parent.entity))
    parent, has_parent := get_component(parent.ecs, child.entity, Parent);
    fmt.println(parent)

}


get_gameobjects_tag :: proc(ecs: ^EntityComponentSystem, tag: string) -> [dynamic]GameObject{
    tag_storage, ok := get_storage(ecs, Tag)

    gameobjects : [dynamic]GameObject

    for i in 0..<len(tag_storage.dense) {
        tag_comp := tag_storage.dense[i]
        if tag_comp.tag != tag do continue
        
        entity := tag_storage.entities[i]
        gb := get_gameobject(ecs, entity)

        append(&gameobjects, gb)
    }
    return gameobjects
}
