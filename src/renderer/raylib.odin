package renderer;
import rl "vendor:raylib";
import "core:fmt";


execute :: proc(renderer: ^Renderer) {
    for command in renderer.commands {
        switch command.type {
        case .CMD_CLEAR:
            rl.ClearBackground(rl.RAYWHITE);
        case .CMD_TRIANGLE :
            fmt.println(command);
            rl.DrawTriangle(command.triangle.v1,
                            command.triangle.v2,
                            command.triangle.v3,
                            rl.Color(command.clear));
        }
    }
    fmt.println("");

}
