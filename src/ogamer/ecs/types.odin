package ogamer_ecs;

import rn "../renderer/"


SYSTEM_UPDATE_FUNCTION :: proc(e: ^EntityComponentSystem, renderer: ^rn.Renderer, dt: f32)
DESTROY_COMPONENT_STORAGE :: proc(raw: rawptr)


@(private)
ComponentStorage :: struct($T: typeid) {
    sparse         : [dynamic]int,
    dense          : [dynamic]T,
    entities       : [dynamic]Entity,
}

@(private)
StorageHolder :: struct {
    storage        : rawptr,
    update         : SYSTEM_UPDATE_FUNCTION,
    destroy        : DESTROY_COMPONENT_STORAGE, // Will free the storage arrays and storage
    before_destroy : DESTROY_COMPONENT_STORAGE  // Will be run before destroying the storage
}

EntityComponentSystem :: struct {
    storages: map[typeid]StorageHolder,
    entity_counter: Entity
}

