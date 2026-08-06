package ogamer;

import "./ecs"
import "./input"
import b2 "vendor:box2d"
import rn "./renderer"
import "./physics"
import "./events"

import "core:fmt"

Entity  :: u32
Vector2 :: [2]f32

current_game : ^Game

/*
this is a binding for the user so they don't have to
keep track which package contains what and to make it
easier for them to code
*/

RenderSettings :: rn.RendererSettings


GameObject :: ecs.GameObject

add_component    :: ecs.gameobject_add_component
get_component    :: ecs.gameobject_get_component
new_gameobject   :: ecs.new_gameobject
get_gameobject   :: ecs.get_gameobject
add_child        :: ecs.add_child


NewTransform     :: ecs.NewTransform
Transform        :: ecs.Transform
NewShapeRenderer :: ecs.NewShapeRenderer
ShapeRenderer    :: ecs.ShapeRenderer



// INPUT

is_key_down :: input.is_key_down
is_key_pressed :: proc (key: input.KeyboardKey) -> bool {
    if current_game == nil do return false;
    return input.is_key_pressed(current_game.eventQueue, key)
}
is_mouse_down :: input.is_mouse_down
is_mouse_pressed :: proc (btn: input.MouseButton) -> bool {
    if current_game == nil do return false;
    return input.is_mouse_pressed(current_game.eventQueue, btn)
}


// PHYSICS
apply_force :: proc (entity: Entity, force: Vector2) -> bool {
    if body, has := current_game.ecs.world.bodies[entity]; has {
        fmt.println("FORCE:", force)
        b2.Body_ApplyForceToCenter(body, force * physics.PIXELS_PER_METER, true)
        return true
    }
    else {
        return false
    }
}

raycast :: proc(start, direction: [2]f32) -> b2.RayResult {
    filter := b2.DefaultQueryFilter()
    PIXELS_PER_METER :: 50

    
    result := b2.World_CastRayClosest(current_game.ecs.world.world_id, start / PIXELS_PER_METER, (direction) / PIXELS_PER_METER,  filter)
    if result.hit {
        entity := current_game.ecs.world.entites_by_shape[result.shapeId]
        events.emit(current_game.eventQueue, events.RaycastHit({entity}))
    }
    return result
}
