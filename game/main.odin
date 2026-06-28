package main;

import "core:fmt"
import b2 "vendor:box2d"
import "../src/core"
import "../src/ecs"
import "../src/ecs/types"
import sc "../src/scripting"
import rn "../src/renderer"
import "../src/io"
import es "../src/event-system"
import sys "../src/ecs/systems"


create_player :: proc (e: ^ecs.ECS) {
    player, _ := sc.new_gameobject(e);
    defer free(player)
    
    idle := io.new_tilesheet("./game/assets/Idle (78x58).png", {64,58}, {14, 0});
    run := io.new_tilesheet("./game/assets/Run (78x58).png", {64,58}, {14, 0});
    io.merge_tilesheet(idle,run)

    sprite,_ := sc.add_component(player, types.SpriteRenderable({}))
    sc.add_component(player, types.SpriteAnimator({
        sprite_comp=sprite,
        sprites=idle.images,
        active_animation=2,
        time=0.1
    }))
}

create_enemy :: proc(e: ^ecs.ECS) {

    enemy, _ := sc.new_gameobject(e);
    defer free(enemy)
    enemy.transform.pos = {100,0}
    idle : ^types.TileSheet = io.new_tilesheet("./game/assets/Pig Idle (34x28).png", {28,28}, {34-28,0})

    sc.add_component(enemy, types.SquareCollider({}))
    sc.add_component(enemy, types.SpriteAnimator({
        sprites=idle.images,
        time=0.1
    }))

}

main :: proc() {

    game := core.init_game();
    defer core.free_game(game);

    camera, _ := sc.new_gameobject(&game.ecs);
    defer free(camera)
    sc.add_component(camera, types.Camera2D({zoom=1}));
    
    create_player(&game.ecs);
    create_enemy(&game.ecs);

    core.main_loop(game);
}

