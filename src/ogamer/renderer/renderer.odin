package ogamer_renderer;

/*
This procedure executes the commands of the renderer
the renderer implementation should set this hook 
execute = RENDER_IMPLEMETNATION.execute
*/
execute : proc (renderer: ^Renderer)


/*
This procedure is used to add render commands to the renderer
It will sort the different commands in the right render command arrays
*/
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

destroy_renderer :: proc (renderer: ^Renderer) {
    delete(renderer.init_commands)
    delete(renderer.draw_commands)
    delete(renderer.deinit_commands)
    delete(renderer.debug_commands)
    free(renderer)
}

get_color :: proc(c:u32) -> [4]u8 {
    return [4]u8{
        u8((c >> 24) & 0xFF),
        u8((c >> 16) & 0xFF),
        u8((c >> 8) & 0xFF),
        u8(c & 0xFF),
    }
}
