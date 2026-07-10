package renderer;
import rl "vendor:raylib";
import "core:fmt";
import "core:slice";
import "core:math";
import "core:strings";
import es "../event-system";
import "../types";

RENDER :: true
DEBUG  :: true


texture_cache: map[^types.Image]rl.Texture2D
camera := rl.Camera2D({{1240/2,720/2},{0,0},0,1});

width :: 1920
height :: 1080

target : rl.RenderTexture
uitarget : rl.RenderTexture

init_renderer :: proc() {
    if !RENDER do return
    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(width,height,"Hello World");
    target = rl.LoadRenderTexture(width, height);
    uitarget = rl.LoadRenderTexture(width, height);
    rl.SetTextureFilter(target.texture, rl.TextureFilter.POINT);
    rl.SetTextureFilter(uitarget.texture, rl.TextureFilter.POINT);


}

deinit_renderer :: proc() {
    rl.UnloadTexture(target.texture);
}

execute_command :: proc(renderer : ^Renderer ,command: RenderCommand) {
    #partial switch v in command {
        case InitWindow:
        rl.SetTargetFPS(144)
        case BeginDraw:
        rl.BeginTextureMode(target);
        // if there is no camera we create it
        if renderer.active_camera != nil {
            camera = rl.Camera2D({
                renderer.active_camera.offset,
                renderer.active_camera.target,
                renderer.active_camera.rotation,
                renderer.active_camera.zoom
            })
            camera.target.y = -camera.target.y // Y-up: flip camera target into raylib space
        }
        // make it in the center of the screen
        camera.offset = {width/2, height/2}
        rl.BeginMode2D(camera);
        
        case EndDraw:
        rl.EndMode2D();
        rl.EndTextureMode();
        case Clear:
        rl.ClearBackground(rl.Color(v.color));
        case Text:
        rl.DrawText(fmt.ctprintf("%s", v.text),
                    i32(v.pos.x),
                    i32(-v.pos.y), // Y-up
                    v.font_size,
                    rl.BLACK)

        case Rectangle:
        rec : rl.Rectangle = {v.pos.x,-v.pos.y, v.size.x, v.size.y} // Y-up
        origin : rl.Vector2 = {
            v.size.x / 2,
            v.size.y / 2
        };
        if !v.lines {
            rl.DrawRectanglePro(
                rec,
                origin,
                -v.rot, // Y-up: CCW-positive rotation
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
        if v.image == nil do break
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
        dest : rl.Rectangle = {v.pos.x,-v.pos.y, v.size.x, v.size.y} // Y-up

        origin : rl.Vector2 = {
            v.size.x / 2,
            v.size.y / 2
        };

        rl.DrawTexturePro(
            sprite,
            source,
            dest,
            origin,
            -v.rot, // Y-up: CCW-positive rotation
            rl.Color(get_color(0xffffffff))
        )
    }

}

handle_input :: proc() {
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
    
    for rl_btn in rl.MouseButton {
        btn := types.MouseButton(rl_btn)
        if rl.IsMouseButtonPressed(rl_btn) {
            es.emit(types.Event_MouseButton_Pressed({btn}))
            append(&types.mouse_buttons, btn)
        }
    }
    for i := len(types.mouse_buttons) - 1; i >= 0; i -= 1 {
        if rl.IsMouseButtonReleased(rl.MouseButton(types.mouse_buttons[i])) {
            unordered_remove(&types.mouse_buttons, i)
        }
    }

}

layer_of :: proc(command: RenderCommand) -> int {
    #partial switch v in command {
        case Rectangle: return v.layer
        case Sprite: return v.layer
        case Text: return v.layer
        case UIText: return v.layer
        case UISprite: return v.layer
    }
    return -1;
}

execute :: proc(renderer: ^Renderer) {

    handle_input()

    if rl.IsWindowReady() && rl.WindowShouldClose() do es.emit(types.Event_Should_Close_Window({}));
    window_w := f32(rl.GetScreenWidth())
		window_h := f32(rl.GetScreenHeight())
    scale := math.min(window_w / width, window_h / height)

    // if we are in debug mode add debug render commands to render commands
    if DEBUG {
         for command in renderer.debug_commands{
             inject_at(&renderer.draw_commands, len(&renderer.draw_commands)-1, command);
         }

     }

    if RENDER {
        // Handle before draw commands
        for command in renderer.init_commands {
            execute_command(renderer, command)
        }
        slice.sort_by(renderer.draw_commands[:], proc(a, b: RenderCommand) -> bool {
            return layer_of(a) < layer_of(b)
        })
        for command in renderer.draw_commands {
            execute_command(renderer, command)
        }

        for command in renderer.deinit_commands {
            execute_command(renderer, command)
        }
        rl.BeginTextureMode(uitarget);
        rl.ClearBackground(rl.Color(get_color(0))) // clear the ui texture

        // TODO make them also scale with monitor
        // TODO flip the y coordninate
        // DRAW UI ELEMENTS
        slice.sort_by(renderer.draw_commands[:], proc(a, b: RenderCommand) -> bool {
            return layer_of(a) < layer_of(b)
        })
        for command in renderer.draw_commands {
            #partial switch v in command {
                case UIText:
                // FIXME memory leak?
                rl.DrawText(fmt.ctprintf("%s", v.text),
                            i32(v.pos.x),
                            i32(v.pos.y),
                            v.font_size,
                            rl.Color(v.color))
                case UISprite:
                // tecture cacheing
                // TODO load this before rendering (make a sperate function to load tectures)
                if v.image == nil do break
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
                dest : rl.Rectangle = {v.pos.x,-v.pos.y, v.size.x, v.size.y} // Y-up

                origin : rl.Vector2 = {
                    v.size.x / 2,
                    v.size.y / 2
                };

                rl.DrawTexturePro(
                    sprite,
                    source,
                    dest,
                    origin,
                    -v.rot, // Y-up: CCW-positive rotation
                    rl.Color(get_color(0xffffffff))
                )
            }
        }
        rl.EndTextureMode();
        
        // now render the texture
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK) // Draws the black bars
			  source_rec := rl.Rectangle{0, 0, f32(target.texture.width), -f32(target.texture.height)}
			  dest_rec := rl.Rectangle{
				    (window_w - (width * scale)) * 0.5,
				    (window_h - (height * scale)) * 0.5,
				    width * scale,
				    height * scale,
			  }
			  rl.DrawTexturePro(target.texture, source_rec, dest_rec, {0, 0}, 0.0, rl.WHITE)
        
			  ui_source_rec := rl.Rectangle{0, 0, f32(uitarget.texture.width), -f32(uitarget.texture.height)}
			  ui_dest_rec := rl.Rectangle{
				    (window_w - (width * scale)) * 0.5,
				    (window_h - (height * scale)) * 0.5,
				    width * scale,
				    height * scale,
			  }
			  rl.DrawTexturePro(uitarget.texture, ui_source_rec, ui_dest_rec, {0, 0}, 0.0, rl.WHITE)

        rl.EndDrawing();
    }        
    if DEBUG do clear(&renderer.debug_commands)
    clear(&renderer.init_commands)
    clear(&renderer.draw_commands)
    clear(&renderer.deinit_commands)
}

get_mouse_position :: proc() -> types.Vector2 {
    mouse := rl.GetMousePosition()
    window_w := f32(rl.GetScreenWidth())
    window_h := f32(rl.GetScreenHeight())
    scale := math.min(window_w / width, window_h / height)
    // reverse the letterbox: undo the centering offset and the scale
    return {
        (mouse.x - (window_w - (width * scale)) * 0.5) / scale,
        (mouse.y - (window_h - (height * scale)) * 0.5) / scale,
    }
}

get_world_mouse_position :: proc() -> types.Vector2 {
    pos := (get_mouse_position() - camera.offset) / camera.zoom + camera.target
    pos.y = -pos.y
    return pos
}

