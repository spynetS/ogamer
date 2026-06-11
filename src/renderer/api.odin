package renderer;

import rl "vendor:raylib"


start_draw :: proc() {
    rl.BeginDrawing();
}

end_draw :: proc() {
    rl.EndDrawing();
}

get_color :: proc(c:u32) -> [4]u8 {
    return [4]u8{
        u8((c >> 24) & 0xFF),
        u8((c >> 16) & 0xFF),
        u8((c >> 8) & 0xFF),
        u8(c & 0xFF),
    }
}

draw_rectangle :: proc(renderer: ^Renderer, pos, size: [2]f32, color: [4]u8) {
    
    cmd : RenderCommand={}
    cmd.type = RenderCommandType.CMD_TRIANGLE
    cmd.clear = color
    cmd.triangle = {pos,{pos.x,pos.y+size.y},pos+size}
    append(&renderer.commands, cmd);

    cmd.type = RenderCommandType.CMD_TRIANGLE
    cmd.clear = color
    cmd.triangle = {{pos.x+size.x, pos.y},pos,pos+size}
    append(&renderer.commands, cmd);
}



