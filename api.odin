package ogamer;

import "./ecs"
import "./input"
import b2 "vendor:box2d"
import rn "./renderer"
import "./physics"

Entity  :: u32
Vector2 :: [2]f32

current_game : ^Game

/*
this is a binding for the user so they don't have to
keep track which package contains what and to make it
easier for them to code
*/

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
apply_force :: proc (entity: Entity, force: Vector2) {
    b2.Body_ApplyForceToCenter(current_game.ecs.world.bodies[entity], force * physics.PIXELS_PER_METER, true)
}
