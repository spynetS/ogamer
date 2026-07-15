package game2;

import "../src/core"
import "../src/types"
import "../src/io"
import sc "../src/scripting"
import "../src/renderer"
import rl "vendor:raylib"
// sprites are inside ./assets
// https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites

game: ^core.Game

create_player :: proc(pos: types.Vector2) {
    
    idle := io.new_tilesheet(game.io_handler, "./game2/assets/Entities/Characters/Body_A/Animations/Idle_Base/Idle_Down-Sheet.png", {64,64})

    walk_side := io.new_tilesheet(game.io_handler, "./game2/assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Side-Sheet.png", {64,64})
    io.merge_tilesheet(game.io_handler, idle, walk_side)

    walk_up := io.new_tilesheet(game.io_handler, "./game2/assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Up-Sheet.png", {64,64})
    io.merge_tilesheet(game.io_handler, idle, walk_up)

    walk_down := io.new_tilesheet(game.io_handler, "./game2/assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Down-Sheet.png", {64,64})
    io.merge_tilesheet(game.io_handler, idle, walk_down)



    go := sc.new_gameobject(&game.ecs)
    sc.add_component(go, types.Camera2D({zoom=1.5}))
    sc.add_component(go, types.SpriteRenderable({
        layer=-2
    }))
    animator := sc.add_component(go, types.SpriteAnimator({
        sprites=idle.sprites,
        active_animation=0,
        time=0.1
    }))
    sc.add_component(go, types.Script({
        data = animator,
        on_update = proc(go: types.GameObject, data: rawptr, dt:f32) {
            animator := cast(^types.SpriteAnimator)data
            speed : f32 = 2.0
            animator.active_animation = 0
            animator.sprite_comp.inverted = false
            if sc.is_key_down(types.KeyboardKey.A) {
                animator.active_animation = 1
                go.transform.pos -= {1,0} * speed
                animator.sprite_comp.inverted = true
            }
            if sc.is_key_down(types.KeyboardKey.D) {
                animator.active_animation = 1
                go.transform.pos += {1,0} * speed
            }
            if sc.is_key_down(types.KeyboardKey.W) {
                animator.active_animation = 2
                go.transform.pos += {0,1} * speed
            }
            if sc.is_key_down(types.KeyboardKey.S) {
                animator.active_animation = 3
                go.transform.pos -= {0,1} * speed
            }

        }
    }))

}

main :: proc() {
    game = core.init_game();
    _map := core.load_map(game.io_handler, "./game2/map.tmj")

    defer core.destroy(_map)
    defer core.free_game(game);

    
    rl.HideCursor()
    
    mouse,_ := sc.new_gameobject(&game.ecs);
    mouse.transform.size = {30,30}
    cursor,_ := io.load(game.io_handler,"./game2/assets/Arrow2.png")
    sc.add_component(mouse, types.Persistent({}))
    sc.add_component(mouse, types.UiSprite({sprite=cursor, layer=10}))
    sc.add_component(mouse, types.Script({
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32){
            go.transform.pos = (renderer.get_mouse_position() + {10,10}) * {1,-1}
            if sc.is_mouse_pressed(types.MouseButton.LEFT) {
                tileset := io.new_tilesheet(game.io_handler,"./game2/assets/Environment/Props/Animated/Pan_01-Sheet.png", {32,32})
                new_go := sc.new_gameobject(go.ecs);
                new_go.transform.pos = renderer.get_world_mouse_position()
                sc.add_component(new_go, types.SpriteAnimator({
                    sprites=tileset.sprites,
                    time=0.1
                }))
            }
        }
    }))



    core.create_from_map(
        game,
        _map,
        {3,3},
        on_create = proc (obj: core.Object, transform: types.Transform){
            if obj.class == "player" do create_player(transform.pos)
        })


    core.main_loop(game)
}

