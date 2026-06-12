package renderer;
import rl "vendor:raylib";
import "core:fmt";


execute :: proc(renderer: ^Renderer) {
    
    for command in renderer.commands {
        fmt.println(command);
        switch v in command {
        case InitWindow:
            rl.SetTargetFPS(60)
            rl.InitWindow(800,400,"Hello World");
        case BeginDraw:
            rl.BeginDrawing();
        case EndDraw:
            rl.EndDrawing();
        case Clear:
            rl.ClearBackground(rl.RAYWHITE);
        case Triangle :

            rl.DrawTriangle(v.v1,
                            v.v2,
                            v.v3,
                            rl.Color(v.color));
        }

    }
    fmt.print("\n");
    clear(&renderer.commands) // TODO maybe make clearing the commands a seperate function?
}
