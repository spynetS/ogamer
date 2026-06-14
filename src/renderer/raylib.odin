package renderer;
import rl "vendor:raylib";
import "core:fmt";
import "core:strings";

RENDER :: true

texture_cache: map[string]rl.Texture2D

load :: proc() {

}

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
            case Rectangle:
                rl.DrawRectangle(i32(v.pos.x),
                                 i32(v.pos.y),
                                 i32(v.size.x),
                                 i32(v.size.y),
                                 rl.Color(v.color));
            case Sprite:

                sprite, got := texture_cache[v.file_path]
                if !got {
                    file_path := strings.clone_to_cstring(v.file_path)
                    defer delete(file_path)
                    sprite = rl.LoadTexture(file_path);
                    texture_cache[v.file_path] = sprite
                }
                
                
                source : rl.Rectangle = {0,0, cast(f32)sprite.width, cast(f32)sprite.height}
                dest : rl.Rectangle = {v.pos.x,v.pos.y, v.size.x, v.size.y}
                origin : rl.Vector2 = {0,0};
                rl.DrawTexturePro(
                    sprite,
                    source,
                    dest,
                    origin,
                    0,
                    rl.Color(get_color(0xffffffff))
                )
            }
        }
    }        
    clear(&renderer.commands) // TODO maybe make clearing the commands a seperate function?
}
