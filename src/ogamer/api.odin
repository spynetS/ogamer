package ogamer;

import "./ecs"
import "./ecs/components/"


/*
this is a binding for the user so they don't have to
keep track which package contains what and to make it
easier for them to code
*/

GameObject :: struct {
    entity: ecs.Entity,
    transform: ^components.Transform, // ecs should handle the transform memory
    parent: ^GameObject,
    ecs: ^ecs.EntityComponentSystem,
}

add_component    :: ecs.add_component
get_component    :: ecs.get_component

NewTransform     :: components.NewTransform
Transform        :: components.Transform
NewShapeRenderer :: components.NewShapeRenderer
ShapeRenderer    :: components.ShapeRenderer
