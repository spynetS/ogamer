package ogamer_ecs;

Entity :: distinct u32
SYSTEM_UPDATE_FUNCTION :: proc(e: ^EntityComponentSystem, dt: f32)
DESTROY_COMPONENT_STORAGE :: proc(raw: rawptr)


@(private)
ComponentStorage :: struct($T: typeid) {
    sparse         : [dynamic]int,
    dense          : [dynamic]T,
    entities       : [dynamic]Entity,
}

@(private)
StorageHolder :: struct {
    storage : rawptr,
    update  : SYSTEM_UPDATE_FUNCTION,
    destroy : DESTROY_COMPONENT_STORAGE
}



EntityComponentSystem :: struct {
    storages: map[typeid]StorageHolder,
    entity_counter: Entity
}

