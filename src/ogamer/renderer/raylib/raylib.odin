package ogamer_renderer_renderer;

import rl "vendor:raylib";
import "core:fmt";
import "core:slice";
import "core:math";
import "core:strings";
import es "../../events";
import "../../io";
import "../../input";
import rn "../";



RENDER := true
DEBUG  :: false

assets :^io.AssetsManager = nil

texture_cache: map[^io.Image]rl.Texture2D
camera := rl.Camera2D({{1240/2,720/2},{0,0},0,1});

width :: 1920/1.2
height :: 1080/1.2

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

load_sprite :: proc(sprite: io.Sprite, inverted: bool) -> (rl.Texture2D,rl.Rectangle, bool) {

    if assets == nil || sprite.texture == "" do return rl.Texture2D({}), rl.Rectangle({}), false
    sprite := sprite;
    texture := assets.textures[sprite.texture]
    rl_texture, found := texture_cache[texture]; 
    // if its not cached we add it to cache
    if !found {
        fmt.println("INFO: load texture")
        image : rl.Image = {
            raw_data(texture.data),
            texture.width,
            texture.height,
            texture.mipmaps,
            rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
        }
        rl_texture = rl.LoadTextureFromImage(image);
        texture_cache[texture] = rl_texture
    }

    tw := cast(f32)texture.width
    th := cast(f32)texture.height
    
    source: rl.Rectangle = {
        cast(f32)(sprite.uv[0].x * tw),
        cast(f32)(sprite.uv[0].y * th),
        cast(f32)((sprite.uv[1].x - sprite.uv[0].x) * tw) * cast(f32) (inverted ? -1 : 1),
        cast(f32)((sprite.uv[1].y - sprite.uv[0].y) * th),
    }
    return rl_texture, source, true
}

execute_command :: proc(renderer : ^rn.Renderer ,command: rn.RenderCommand) {
    #partial switch v in command {
        case rn.InitWindow:
        init_renderer()
        rl.SetTargetFPS(renderer.settings.target_fps > 0 ? renderer.settings.target_fps : 60)
        case rn.DeinitWindow:
        deinit_renderer()
        case rn.BeginDraw:
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
        
        case rn.EndDraw:
        rl.EndMode2D();
        rl.EndTextureMode();
        case rn.Clear:
        rl.ClearBackground(rl.Color(v.color));
        case rn.Text:
        rl.DrawText(fmt.ctprintf("%s", v.text),
                    i32(v.pos.x),
                    i32(-v.pos.y), // Y-up
                    v.font_size,
                    rl.BLACK)

        case rn.Rectangle:
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
        case rn.Sprite:
        rl_texture, source, ok := load_sprite(v.sprite, v.inverted)
        if !ok do break

        if v.repeated_x {
            tile_width := cast(f32)v.size.x // whatever your spacing is

            screenWidth :f32= cast(f32)rl.GetScreenWidth()
            left  := camera.target.x - (screenWidth) / camera.zoom
            right := camera.target.x + (screenWidth) / camera.zoom
            // still subtract the sprite offset, exactly like before
            start := cast(i32)math.floor((left  - v.offset.x) / tile_width) - 1
            end   := cast(i32)math.ceil ((right - v.offset.x) / tile_width) + 1

            for i := start; i <= end; i += 1 {
                x := cast(f32)i * tile_width + v.offset.x
                dest: rl.Rectangle = {
                    x,
                    -v.pos.y-v.offset.y,
                    v.size.x,
                    v.size.y,
                }

                rl.DrawTexturePro(
                    rl_texture,
                    source,
                    dest,
                    {v.size.x/2, v.size.y/2},
                    -v.rot,
                    rl.WHITE,
                )
            }
        }
        else{
            dest: rl.Rectangle = {
                v.pos.x + v.offset.x,
                -v.pos.y - v.offset.y,
                v.size.x,
                v.size.y,
            }

            rl.DrawTexturePro(
                rl_texture,
                source,
                dest,
                {v.size.x/2, v.size.y/2},
                -v.rot,
                rl.WHITE,
            )
        }

    }

}
// TODO
handle_input :: proc() {
    // key := input.KeyboardKey(rl.GetKeyPressed());
    // if key != input.KeyboardKey.KEY_NULL {
    //     es.emit(event.Event_Key_Pressed({key}));
    //     append(&input.keys, key);
    // }

    // for i := len(types.keys) - 1; i >= 0; i -= 1 {
    //     if rl.IsKeyReleased(rl.KeyboardKey(types.keys[i])) {
    //         unordered_remove(&types.keys, i)
    //     }
    // }
    
    // for rl_btn in rl.MouseButton {
    //     btn := types.MouseButton(rl_btn)
    //     if rl.IsMouseButtonPressed(rl_btn) {
    //         es.emit(types.Event_MouseButton_Pressed({btn}))
    //         append(&types.mouse_buttons, btn)
    //     }
    // }
    // for i := len(types.mouse_buttons) - 1; i >= 0; i -= 1 {
    //     if rl.IsMouseButtonReleased(rl.MouseButton(types.mouse_buttons[i])) {
    //         unordered_remove(&types.mouse_buttons, i)
    //     }
    // }

}

layer_of :: proc(command: rn.RenderCommand) -> int {
    #partial switch v in command {
        case rn.Rectangle: return v.layer
        case rn.Sprite: return v.layer
        case rn.Text: return v.layer
        case rn.UIText: return v.layer
        case rn.UISprite: return v.layer
    }
    return -1;
}

execute :: proc(renderer: ^rn.Renderer, eventQueue: ^es.EventQueue) {

    handle_input()

    if rl.IsWindowReady() && rl.WindowShouldClose() do es.emit(eventQueue, es.Should_Close_Window({}));
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
        slice.sort_by(renderer.draw_commands[:], proc(a, b: rn.RenderCommand) -> bool {
            return layer_of(a) < layer_of(b)
        })
        for command in renderer.draw_commands {
            execute_command(renderer, command)
        }

        for command in renderer.deinit_commands {
            execute_command(renderer, command)
        }
        rl.BeginTextureMode(uitarget);
        rl.ClearBackground(rl.Color(rn.get_color(0))) // clear the ui texture

        // TODO make them also scale with monitor
        // TODO flip the y coordninate
        // DRAW UI ELEMENTS
        slice.sort_by(renderer.draw_commands[:], proc(a, b: rn.RenderCommand) -> bool {
            return layer_of(a) < layer_of(b)
        })
        for command in renderer.draw_commands {
            #partial switch v in command {
                case rn.UIText:
                // FIXME memory leak?
                rl.DrawText(fmt.ctprintf("%s", v.text),
                            i32(v.pos.x),
                            i32(v.pos.y),
                            v.font_size,
                            rl.Color(v.color))
                case rn.UISprite:
                // tecture cacheing
                // TODO load this before rendering (make a sperate function to load tectures)
                rl_texture, source, ok := load_sprite(v.sprite, v.inverted)
                if !ok do break
                dest : rl.Rectangle = {v.pos.x,-v.pos.y, v.size.x, v.size.y} // Y-up

                origin : rl.Vector2 = {
                    v.size.x / 2,
                    v.size.y / 2
                };

                rl.DrawTexturePro(
                    rl_texture,
                    source,
                    dest,
                    origin,
                    -v.rot, // Y-up: CCW-positive rotation
                    rl.Color(rn.get_color(0xffffffff))
                )
            }
        }
        rl.DrawText(fmt.ctprintf("%d", rl.GetFPS()),
                    100,
                    100,
                    24,
                    rl.Color(0x000000ff))

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

get_mouse_position :: proc() -> [2]f32 {
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

get_world_mouse_position :: proc() -> [2]f32 {
    pos := (get_mouse_position() - camera.offset) / camera.zoom + camera.target
    pos.y = -pos.y
    return pos
}

