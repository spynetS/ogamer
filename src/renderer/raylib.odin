package renderer;
import rl "vendor:raylib";
import "core:fmt";
import "core:math";
import "core:strings";
import es "../event-system";
import "../types";

RENDER :: true

texture_cache: map[^types.Image]rl.Texture2D
camera := rl.Camera2D({{1240/2,720/2},{0,0},0,1});

width :: 1240
height :: 720

target : rl.RenderTexture

init_renderer :: proc() {
    if !RENDER do return
    rl.InitWindow(width,height,"Hello World");
    rl.SetWindowState({.WINDOW_RESIZABLE})
    target = rl.LoadRenderTexture(width, height);
    rl.SetTextureFilter(target.texture, rl.TextureFilter.POINT);
}

deinit_renderer :: proc() {
    rl.UnloadTexture(target.texture);
}

execute :: proc(renderer: ^Renderer) {

    key := types.KeyboardKey(rl.GetKeyPressed());
    if key != types.KeyboardKey.KEY_NULL {
        es.emit(types.Event_Key_Pressed({key}));
        append(&types.keys, key);
    }

    for i := len(types.keys) - 1; i >= 0; i -= 1 {
        if rl.IsKeyReleased(rl.KeyboardKey(types.keys[i])) {
            unordered_remove(&types.keys, i)
        }
    }    

    if rl.IsWindowReady() && rl.WindowShouldClose() do es.emit(types.Event_Should_Close_Window({}));


    window_w := f32(rl.GetScreenWidth())
		window_h := f32(rl.GetScreenHeight())
    scale := math.min(window_w / width, window_h / height)

    if RENDER {

        for command in renderer.commands {
            switch v in command {
            case InitWindow:
                rl.SetTargetFPS(144)
            case BeginDraw:
                rl.BeginTextureMode(target);
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
                rl.DrawText(fmt.ctprintf("%d", rl.GetFPS()),0,-200,32, rl.GRAY);
            case EndDraw:
                rl.EndMode2D();
                rl.EndTextureMode();
                // now render the texture
                rl.BeginDrawing();
                rl.ClearBackground(rl.BLACK) // Draws the black bars

			          // Source rect mapping from texture coordinates. 
			          // Note the negative height flips the Y-axis properly for OpenGL
			          source_rec := rl.Rectangle{0, 0, f32(target.texture.width), -f32(target.texture.height)}
			          
			          // Destination rect centered on the monitor screen window
			          dest_rec := rl.Rectangle{
				            (window_w - (width * scale)) * 0.5,
				            (window_h - (height * scale)) * 0.5,
				            width * scale,
				            height * scale,
			          }

			          rl.DrawTexturePro(target.texture, source_rec, dest_rec, {0, 0}, 0.0, rl.WHITE)
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
                if !v.lines {
                    rl.DrawRectanglePro(
                        rec,
                        origin,
                        v.rot,
                        rl.Color(v.color)
                    );
                }
                else {
                    rec.x -= rec.width/2
                    rec.y -= rec.height/2
                    rl.DrawRectangleLinesEx(
                        rec,
                        1,
                        rl.Color(v.color)
                    );
                }
            case Sprite:
                // tecture cacheing
                // TODO load this before rendering (make a sperate function to load tectures)
                if v.image == nil do continue
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
                
                
                source : rl.Rectangle = {0,0, cast(f32)(v.inverted ? -sprite.width :sprite.width ), cast(f32)sprite.height}
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
