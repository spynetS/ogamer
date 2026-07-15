package ogamer_ecs_components;

import "../../io"

Vector2 :: [2]f32
Entity :: u32

Component :: struct {
    disabled : bool
}

Camera2D :: struct {
    using component: Component,
    offset:   Vector2,            // Camera offset (displacement from target)
	  target:   Vector2,            // Camera target (rotation and zoom origin)
	  rotation: f32,                // Camera rotation in degrees
	  zoom:     f32,                // Camera zoom (scaling), should be 1.0f by default
}


Transform :: struct {
    using component: Component,
    pos: Vector2,
    size: Vector2
}

NewTransform :: proc (
    pos: Vector2 = {0,0},
    size: Vector2 = {100,100}
) -> Transform { return Transform({pos=pos,size=size})}


ShapeRenderer :: struct {
    using component: Component,
    color: [4]u8
}

NewShapeRenderer :: proc (
    color: [4]u8 = {255,255,255,255}
) -> ShapeRenderer { return ShapeRenderer({color=color})}

Parent :: struct {
    using component: Component,
    entity: Entity
}
NewParent :: proc (entity: Entity) -> Parent { return Parent({entity=entity}) }

SpriteRenderer :: struct {
    using component : Component,
    sprite          : io.Sprite,
    inverted        : bool,
    size            : Vector2,
    offset          : Vector2,
    parallax        : Vector2,
    layer           : int,
    repeated_x      : bool,
    repeated_y      : bool,
}
NewSpriteRenderer :: proc (
    sprite          : io.Sprite = io.Sprite({}),
    inverted        : bool = false,
    size            : Vector2 = {0,0},
    offset          : Vector2 = {0,0},
    parallax        : Vector2 = {1,1},
    layer           : int = 0,
    repeated_x      : bool = false,
    repeated_y      : bool = false,    
) -> SpriteRenderer { return SpriteRenderer({
    sprite     =     sprite,
    inverted   =     inverted,
    size       =     size,
    offset     =     offset,
    parallax   =     parallax,
    layer      =     layer,
    repeated_x =     repeated_x,
    repeated_y =     repeated_y}) }
