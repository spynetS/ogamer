package renderer;

// TODO make better command that is more generic i guess?
// TODO add more commands
RenderCommandType :: enum {
    CMD_CLEAR,
    CMD_TRIANGLE,

};

Triangle :: struct { v1,v2,v3: [2]f32 };

RenderCommand :: struct {
    type: RenderCommandType,
    clear : [4]u8,
    triangle: Triangle
}

Renderer :: struct {
    commands: [dynamic]RenderCommand,
}


create_cmd :: proc(type: RenderCommandType, clear: [4]u8, triangle: Triangle) -> ^RenderCommand {
    cmd := new(RenderCommand);
    cmd.type = type;
    cmd.clear = clear;
    cmd.triangle = triangle;
    return cmd;
}
