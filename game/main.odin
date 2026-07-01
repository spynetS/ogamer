package main;

import "core:fmt"
import b2 "vendor:box2d"
import "../src/core"
import "../src/ecs"
import "../src/types"
import sc "../src/scripting"

import "../src/io"
import es "../src/event-system"
import sys "../src/ecs/systems"

PlayerData :: struct {
    collider : ^types.SquareCollider,
    rigid    : ^types.RigidBody
}
EnemyData :: struct {
    health : int
}


create_player :: proc (e: ^types.ECS) {
    player, _ := sc.new_gameobject(e);
    defer free(player)
    
    idle := io.new_tilesheet("./game/assets/Idle (78x58).png", {64,58}, {14, 0});
    run := io.new_tilesheet("./game/assets/Run (78x58).png", {64,58}, {14, 0});
    io.merge_tilesheet(idle,run)
    sc.add_component(player, types.SquareCollider({}))
    rigid, _ := sc.add_component(player, types.RigidBody({type=types.BodyType.dynamicBody}))

    tool, _ := sc.new_gameobject(e);
    defer free(tool);
    tool.transform.local_pos = {100,0}
    tool.transform.local_size = {-50,-50}
    collider, _ := sc.add_component(tool, types.SquareCollider({trigger=true}))

    sc.add_child(player, tool);

    data := new(PlayerData)
    data.collider=collider
    data.rigid=rigid

    sc.add_component(player, types.Script({
        data=data,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32) {
            pd := cast(^PlayerData)data
            collider := pd.collider
            rigid := pd.rigid

            if sc.is_key_down(types.KeyboardKey.D) do sc.apply_force(rigid, {100,0})
            if sc.is_key_down(types.KeyboardKey.A) do sc.apply_force(rigid, {-100,0})
            collider.disabled = true;
            if sc.is_key_down(types.KeyboardKey.SPACE) {
                collider.disabled = false;
            }
        },
        on_destroy = proc(go: types.GameObject, data:rawptr){
            pd := cast(^PlayerData)data
            free(pd)
        }
        
    }))


    sprite,_ := sc.add_component(player, types.SpriteRenderable({}))
    sc.add_component(player, types.SpriteAnimator({
        sprite_comp=sprite,
        sprites=idle.images,
        active_animation=2,
        time=0.1
    }))
}

create_enemy :: proc(e: ^types.ECS) {

    enemy, _ := sc.new_gameobject(e);
    defer free(enemy)
    enemy.transform.pos = {200,0}
    idle : ^types.TileSheet = io.new_tilesheet("./game/assets/Pig Idle (34x28).png", {28,28}, {34-28,0})

    
    sc.add_component(enemy, types.RigidBody({type=types.BodyType.dynamicBody}))

    ed: ^EnemyData = new(EnemyData)
    ed.health = 5
    fmt.println("EnemyData created at:", ed)  // <-- note this address
    
    sc.add_component(enemy, types.Script({
        data=ed,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32 ) {
            ed := cast(^EnemyData)data
            for event in es.event_queue_poll(){
                #partial switch v in event  {
                    case es.Event_Trigger_Entered:
                    ed.health = ed.health - 1
                    if ed.health <= 0 do ecs.destroy_entity(go.ecs, go.entity)
                }
            }
        },
        on_destroy = proc(go: types.GameObject, data: rawptr) {
            free(data)
        }
    }))

    
    sc.add_component(enemy, types.SquareCollider({}))
    sc.add_component(enemy, types.SpriteAnimator({
        sprites=idle.images,
        time=0.1
    }))

}
game : ^core.Game;

main :: proc() {

    game = core.init_game();
    defer core.free_game(game);

    camera, _ := sc.new_gameobject(&game.ecs);
    defer free(camera)
    sc.add_component(camera, types.Camera2D({zoom=1}));
    
    create_player(&game.ecs);
    create_enemy(&game.ecs);

    floor,_ := sc.new_renderobject(&game.ecs);
    floor.transform.pos = {0,200}
    floor.transform.size = {500,50}
    sc.add_component(floor, types.RigidBody({}))
    sc.add_component(floor, types.SquareCollider({}))
    


    core.main_loop(game);
}

