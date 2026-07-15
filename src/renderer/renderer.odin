package renderer;

import "../types"

// Renderer works by having a bunch of rendering commands that
// the underlaying graphics arcitecture implements by having 
// an execute function that executes all the commands

RenderCommand :: union {
    InitWindow,
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
Clear      :: struct { color: [4]u8 }

Rectangle  :: struct { pos, size: [2]f32, rot: f32, color: [4]u8, lines: bool, layer: int}
Sprite     :: struct { pos, offset, size: [2]f32, rot: f32, inverted: bool, sprite: types.Sprite ,layer: int, repeated_x: bool, repeated_y: bool}
UISprite   :: struct { pos, size: [2]f32, rot: f32, inverted: bool, sprite: types.Sprite ,layer: int}
Text       :: struct { pos: [2]f32, font_size: i32, rot: f32, text: string, color: [4]u8, layer: int}
UIText     :: struct { pos: [2]f32, font_size: i32, rot: f32, text: string, color: [4]u8, layer: int}

BeginDraw  :: struct {}
EndDraw    :: struct {}

Renderer :: struct {
    init_commands  : [dynamic]RenderCommand,
    draw_commands  : [dynamic]RenderCommand,
    deinit_commands  : [dynamic]RenderCommand,
    debug_commands : [dynamic]RenderCommand,
    active_camera  : ^types.Camera2D
}

add_command :: proc (renderer: ^Renderer, command: RenderCommand) {
    #partial switch v in command {
        case InitWindow, BeginDraw, Clear:
        append(&renderer.init_commands, command)
        case EndDraw:
        append(&renderer.deinit_commands, command)
        case:
        append(&renderer.draw_commands, command)
    }
}
