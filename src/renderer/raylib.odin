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
                rl.InitWindow(1240,720,"Hello World");
            case BeginDraw:
                rl.BeginDrawing();
                rl.DrawText(fmt.ctprintf("FPS: %d", rl.GetFPS()), 10, 10, 20, rl.BLACK)
            case EndDraw:
                rl.EndDrawing();
            case Clear:
                rl.ClearBackground(rl.RAYWHITE);
            case Rectangle:
                rec : rl.Rectangle = {v.pos.x,v.pos.y, v.size.x, v.size.y}
                origin : rl.Vector2 = {
                    v.size.x / 2,
                    v.size.y / 2
                };
                rl.DrawRectanglePro(
                    rec,
                    origin,
                    v.rot,
                    rl.Color(v.color)
                );
            case Sprite:
                // tecture cacheing
                sprite, got := texture_cache[v.file_path]
                if !got {
                    file_path := strings.clone_to_cstring(v.file_path)
                    defer delete(file_path)
                    sprite = rl.LoadTexture(file_path);
                    texture_cache[v.file_path] = sprite
                }
                
                
                source : rl.Rectangle = {0,0, cast(f32)sprite.width, cast(f32)sprite.height}
                dest : rl.Rectangle = {v.pos.x,v.pos.y, v.size.x, v.size.y}

                origin : rl.Vector2 = {
                    v.size.x / 2,
                    v.size.y / 2
                };

                rl.DrawTexturePro(
                    sprite,
                    source,
                    dest,
                    origin,
                    v.rot,
                    rl.Color(get_color(0xffffffff))
                )
            }
        }
    }        
    clear(&renderer.commands) // TODO maybe make clearing the commands a seperate function?
}
