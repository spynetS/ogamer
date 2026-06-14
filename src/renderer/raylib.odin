package renderer;
import rl "vendor:raylib";
import "core:fmt";

RENDER :: true

execute :: proc(renderer: ^Renderer) {

    if RENDER {

        for command in renderer.commands {
            switch v in command {
            case InitWindow:
                rl.SetTargetFPS(144)
                rl.InitWindow(800,400,"Hello World");
            case BeginDraw:
                rl.BeginDrawing();
                rl.DrawText(fmt.ctprintf("FPS: %d", rl.GetFPS()), 10, 10, 20, rl.BLACK)
            case EndDraw:
                rl.EndDrawing();
            case Clear:
                rl.ClearBackground(rl.RAYWHITE);
            case Triangle :
                rl.DrawTriangle(v.v1,
                                v.v2,
                                v.v3,
                                rl.Color(v.color));
            case Rectangle :
                rl.DrawRectangle(i32(v.pos.x),
                                 i32(v.pos.y),
                                 i32(v.size.x),
                                 i32(v.size.y),
                                 rl.Color(v.color));
            }
        }
    }        
    clear(&renderer.commands) // TODO maybe make clearing the commands a seperate function?
}
