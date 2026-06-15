package renderer;

import io "../io/"
import "../ecs"
import "../ecs/types"

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
}

InitWindow :: struct { width, height: int, title: string }
Clear      :: struct { color: [4]u8 }
Rectangle  :: struct { pos, size: [2]f32, rot: f32, color: [4]u8 }
Sprite  :: struct { pos, size: [2]f32,rot: f32, file_path: string }
BeginDraw  :: struct {}
EndDraw    :: struct {}


Renderer :: struct {
    commands: [dynamic]RenderCommand,
    active_camera: ^types.Camera2D
}
