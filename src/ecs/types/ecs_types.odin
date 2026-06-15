package types;


Entity :: u32;
Vector2 :: [2]f32;

BodyType :: enum {
    staticBody = 0,
	  kinematicBody = 1,
	  dynamicBody = 2,
}


Camera2D :: struct {
    offset:   Vector2,            // Camera offset (displacement from target)
	  target:   Vector2,            // Camera target (rotation and zoom origin)
	  rotation: f32,                // Camera rotation in degrees
	  zoom:     f32,                // Camera zoom (scaling), should be 1.0f by default
}


Transform :: struct {
    pos        : Vector2,
    local_pos  : Vector2,
    size       : Vector2,
    local_size : Vector2,
    rot        : f32
}

Parent :: struct {
    entity: Entity
}

RectangleRenderable :: struct {
    color : [4]u8
}


RigidBody :: struct {
    vel  : Vector2,
    acc  : Vector2,
    type : BodyType
}

SquareCollider :: struct {
    size : Vector2
}

SpriteRenderable :: struct {
    file_path : string
}
