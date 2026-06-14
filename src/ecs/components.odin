package ecs;


Entity :: u32;
Vector2 :: [2]f32;

Transform :: struct {
    pos        : Vector2,
    local_pos  : Vector2,
    size       : Vector2,
    local_size : Vector2,
    rot        : Vector2
}

Parent :: struct {
    entity: Entity
}

RectangleRenderable :: struct {
    color : [4]u8
}


PhysicsBody :: struct {
    vel  : Vector2,
    acc  : Vector2
}

SpriteRenderable :: struct {
    file_path : string
}
