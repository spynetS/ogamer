package renderer;

// Renderer works by having a bunch of rendering commands that
// the underlaying graphics arcitecture implements by having 
// an execute function that executes all the commands

RenderCommand :: union {
    InitWindow,
    BeginDraw,
    EndDraw,
    Clear,
    Triangle,
    Rectangle,
}

InitWindow :: struct { width, height: int, title: string }
Clear      :: struct { color: [4]u8 }
Rectangle  :: struct { pos, size: [2]f32, color: [4]u8 }
Triangle   :: struct { v1, v2, v3: [2]f32, color: [4]u8 }
BeginDraw  :: struct {}
EndDraw    :: struct {}


Renderer :: struct {
    commands: [dynamic]RenderCommand,
}


