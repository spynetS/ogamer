package ogamer_renderer;
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

RendererSettings :: struct {
    target_fps: i32
}
Camera2D :: struct {
    offset:   [2]f32,  // Camera offset (displacement from target)
	  target:   [2]f32,  // Camera target (rotation and zoom origin)
	  rotation: f32,     // Camera rotation in degrees
	  zoom:     f32,     // Camera zoom (scaling), should be 1.0f by default
}


Renderer :: struct {
    settings        : RendererSettings,
    init_commands   : [dynamic]RenderCommand,
    draw_commands   : [dynamic]RenderCommand,
    deinit_commands : [dynamic]RenderCommand,
    debug_commands  : [dynamic]RenderCommand,
    active_camera   : ^Camera2D
}
