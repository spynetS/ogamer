package ogamer_renderer;
import "../ecs/components/"
import "../io/"


RenderCommand :: union {
    InitWindow,
    DeinitWindow,
    BeginDraw,
    EndDraw,
    Clear,
    Rectangle,
    Sprite,
    Text,
    UIText,
    UISprite,
}

InitWindow :: struct { width, height: int, title: string }
DeinitWindow :: struct { }
Clear      :: struct { color: [4]u8 }

Rectangle  :: struct { pos, size: [2]f32, rot: f32, color: [4]u8, lines: bool, layer: int}
Sprite     :: struct { pos, offset, size: [2]f32, rot: f32, inverted: bool, sprite: io.Sprite ,layer: int, repeated_x: bool, repeated_y: bool}
UISprite   :: struct { using base: Sprite}
Text       :: struct { pos: [2]f32, font_size: i32, rot: f32, text: string, color: [4]u8, layer: int}
UIText     :: struct { pos: [2]f32, font_size: i32, rot: f32, text: string, color: [4]u8, layer: int}

BeginDraw  :: struct {}
EndDraw    :: struct {}

Renderer :: struct {
    init_commands   : [dynamic]RenderCommand,
    draw_commands   : [dynamic]RenderCommand,
    deinit_commands : [dynamic]RenderCommand,
    debug_commands  : [dynamic]RenderCommand,
    active_camera   : ^components.Camera2D
}
