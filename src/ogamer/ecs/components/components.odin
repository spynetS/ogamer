package ogamer_ecs_components;

Vector2 :: [2]f32

Component :: struct {
    
}

Camera2D :: struct {
    using component: Component,
    offset:   Vector2,            // Camera offset (displacement from target)
	  target:   Vector2,            // Camera target (rotation and zoom origin)
	  rotation: f32,                // Camera rotation in degrees
	  zoom:     f32,                // Camera zoom (scaling), should be 1.0f by default
}


Transform :: struct {
    pos: Vector2,
    size: Vector2
}

NewTransform :: proc (
    pos: Vector2 = {0,0},
    size: Vector2 = {0,0}
) -> Transform { return Transform({pos,size})}
