package renderer;
import rl "vendor:raylib";
import "core:fmt";
import "core:strings";
import es "../event-system";
import "../ecs/types";

RENDER :: true

texture_cache: map[^types.Image]rl.Texture2D
camera := rl.Camera2D({{1240/2,720/2},{0,0},0,1});

width :: 1240
height :: 720


execute :: proc(renderer: ^Renderer) {
    key := types.KeyboardKey(rl.GetKeyPressed());
    if key != types.KeyboardKey.KEY_NULL {
        es.emit(es.Event_Key_Pressed({key}));
        append(&types.keys, key);
    }

    for i := len(types.keys) - 1; i >= 0; i -= 1 {
        if rl.IsKeyReleased(rl.KeyboardKey(types.keys[i])) {
            unordered_remove(&types.keys, i)
        }
    }    


    if RENDER {

        for command in renderer.commands {
            switch v in command {
            case InitWindow:
                rl.SetTargetFPS(144)
                rl.InitWindow(width,height,"Hello World");
            case BeginDraw:
                rl.BeginDrawing();
                camera : rl.Camera2D;
                if renderer.active_camera != nil {
                    camera = rl.Camera2D({
                        renderer.active_camera.offset,
                        renderer.active_camera.target,
                        renderer.active_camera.rotation,
                        renderer.active_camera.zoom
                    })
                }
                camera.offset = {width/2, height/2}
                rl.BeginMode2D(camera);
            case EndDraw:
                rl.EndMode2D();
                rl.EndDrawing();
            case Clear:
                rl.ClearBackground(rl.Color(v.color));
            case Text:
                rl.DrawText(fmt.ctprintf("%s", v.text),
                            i32(v.pos.x),
                            i32(v.pos.y),
                            v.font_size,
                            rl.BLACK)
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
                // TODO load this before rendering (make a sperate function to load tectures)
                sprite, got := texture_cache[v.image]
                if !got {
                    fmt.println("INFO: load texture")
                    image : rl.Image = {
                        raw_data(v.image.data),
                        v.image.width,
                        v.image.height,
                        v.image.mipmaps,
                        rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
                    }
                    sprite = rl.LoadTextureFromImage(image);
                    texture_cache[v.image] = sprite
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
