package ogamer_ecs;

import "../io"
import "../events"

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
NewCamera :: proc(
    offset:   Vector2 = {0,0},
	  target:   Vector2 = {0,0},
	  rotation: f32 = 0,
	  zoom:     f32 = 1  
) -> Camera2D { return Camera2D{offset=offset, target=target, rotation=0, zoom=zoom}}

Transform :: struct {
    using component: Component,
    pos: Vector2,
    size: Vector2,
    rot: f32,
    local_pos: Vector2,
    local_size: Vector2,
    local_rot: f32,
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
    parent_entity: Entity
}
NewParent :: proc (entity: Entity) -> Parent { return Parent({parent_entity=entity}) }

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

/*
This struct holds information that scripts would need
in their functions
It's a workaround to get object oriented behaviur
*/

ScriptData :: struct {
    data: rawptr,
    gameObject: GameObject,
    ecs: ^EntityComponentSystem,
    eventQueue: ^events.EventQueue,
    dt: f32
}
SCRIPT_UPDATE_FUNCTION :: proc (data: ScriptData)

Script :: struct {
    data: rawptr, // This is passed to the functions
    update : SCRIPT_UPDATE_FUNCTION,
}
NewScript :: proc (
    data: rawptr = nil,
    update : SCRIPT_UPDATE_FUNCTION = nil
) -> Script {return Script({data=data, update=update})}

ScriptComponent :: struct {
    scripts: [dynamic]Script
}

NewScriptComponent :: proc (
    script:Script=Script({})
) -> ScriptComponent {
    comp := ScriptComponent({})
    append(&comp.scripts,script)
    return comp
}

SpriteAnimator :: struct {
    using component   : Component,
    sprite_comp       : ^SpriteRenderer, // sprite component to be actived on
    sprites           : [][]io.Sprite,        // image matrix
    sprites_length    : []int,             // the "real" length of each animation
    active_animation  : int,               // the row in the sprites matrix
    _active_animation : int,               // internal row in the sprites matrix
    time              : f32,               // time for each frame
    _time_counter     : f32,               // internal counter
    _frame_counter    : int,               // internal counter
    _first_run        : bool,              // internal first_run holder
    active_index      : int                // active frame in animation
}

NewSpriteAnimator :: proc (
    sprite_comp       : ^SpriteRenderer = nil,
    sprites           : [][]io.Sprite = nil,
    sprites_length    : []int = nil,
    active_animation  : int = 0,
    time              : f32 = 0.1,
    active_index      : int = 0) -> SpriteAnimator {
    return SpriteAnimator({
        sprite_comp = sprite_comp,
        sprites = sprites,
        sprites_length = sprites_length,
        active_animation = active_animation,
        time = time,
        active_index = active_index,
    })
}

Text :: struct {
    using base: Component,
    text: string,
    font_size: i32,
    color: [4]u8,
    layer: int,
    offset: Vector2
}
NewText :: proc(
    text: string = "",
    font_size: i32 = 32,
    color: [4]u8 = {0x18,0x18,0x18,0xff},
    layer: int= 0,
    offset: Vector2 = {0,0}
) -> Text {return Text({
    text=text,
    font_size=font_size,
    color=color,
    layer=layer,
    offset=offset
})}


UIText :: struct {
    using text_base: Text,
}
NewUiText :: proc(
    text: string = "",
    font_size: i32 = 32,
    color: [4]u8 = {0x18,0x18,0x18,0xff},
    layer: int= 0,
    offset: Vector2 = {0,0}
) -> UIText {return UIText({
    text=text,
    font_size=font_size,
    color=color,
    layer=layer,
    offset=offset
})}

UISpriteRenderer :: struct {
    using sprite_base: SpriteRenderer
}

NewUISpriteRenderer :: proc (
    sprite          : io.Sprite = io.Sprite({}),
    inverted        : bool = false,
    size            : Vector2 = {0,0},
    offset          : Vector2 = {0,0},
    parallax        : Vector2 = {1,1},
    layer           : int = 0,
    repeated_x      : bool = false,
    repeated_y      : bool = false,    
) -> UISpriteRenderer { return UISpriteRenderer({
    sprite     =     sprite,
    inverted   =     inverted,
    size       =     size,
    offset     =     offset,
    parallax   =     parallax,
    layer      =     layer,
    repeated_x =     repeated_x,
    repeated_y =     repeated_y}) }

