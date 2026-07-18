package ogamer;

import "./ecs"


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
