package ogamer_ecs;

import rn "../renderer/"
import "../io/"
import "../events/"
import "../physics/"


SYSTEM_UPDATE_FUNCTION    :: proc(data: SystemData, dt: f32)
ON_CREATE_COMPONENT       :: proc(ecs: ^EntityComponentSystem, entity: Entity, component: rawptr) // cast to your comp hehe
DESTROY_COMPONENT_STORAGE :: proc(raw: rawptr)

NO_ENTITY :: -1

SystemData :: struct {
    ecs            : ^EntityComponentSystem,
    renderer       : ^rn.Renderer,
    assets_manager : ^io.AssetsManager,
    eventQueue     : ^events.EventQueue
}

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
    on_create      : ON_CREATE_COMPONENT,       // Will be called when a new component is added to an entity
    before_destroy : DESTROY_COMPONENT_STORAGE  // Will be run before destroying the storage
}

EntityComponentSystem :: struct {
    storages          : map[typeid]StorageHolder,
    entity_counter    : Entity,
    world             : ^physics.PhysicsWorld
}

