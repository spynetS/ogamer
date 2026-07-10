package main;

import "core:fmt"
import "../src/ecs"
import "../src/types"
import sc "../src/scripting"
import "../src/io"
import es "../src/event-system"


EnemyData :: struct {
    health   : int,
    animator : ^types.SpriteAnimator
}


create_coin :: proc(e: ^types.ECS, pos: types.Vector2) -> types.GameObject {
    coin, _ := sc.new_gameobject(e);
    defer sc.free_gameobject(coin) 
    coin.transform.pos = pos
    coin.transform.size = {30,30}
    coin.transform.tag = "COIN"
    
    sc.add_component(coin, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))
    sc.add_component(coin, types.SquareCollider({}))

    tilesheet := io.new_tilesheet("./game/assets/Big Diamond Idle (18x14).png", {18,14})
    sc.add_component(coin, types.SpriteAnimator({
        sprites=tilesheet.images,
        time=0.1
    }))
    return coin^;
}

create_enemy :: proc(e: ^types.ECS, pos: types.Vector2) {

    enemy, _ := sc.new_gameobject(e);
    defer free(enemy)
    enemy.transform.pos = pos
    enemy.transform.tag = "enemy"
    enemy.transform.size = {100,100}

    
    sc.add_component(enemy, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))
    sc.add_component(enemy, types.SquareCollider({size={-50,-30}}))
    ed: ^EnemyData = new(EnemyData)
    ed.health = 5

    fmt.println("EnemyData created at:", ed)  // <-- note this address


    idle   : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Idle.png", {100,100})
    attack : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Attack02.png", {100,100})
    hurt   : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Hurt.png", {100,100})
    death  : ^types.TileSheet = io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Orc/Orc with shadows/Orc_Death.png", {100,100})
    io.merge_tilesheet(idle,hurt)
    io.merge_tilesheet(idle,death)
    io.merge_tilesheet(idle,attack)


    sc.add_component(enemy,types.SpriteRenderable({size={300,300}, offset={0,-7}}))
    ed.animator, _ = sc.add_component(enemy, types.SpriteAnimator({
        sprites=idle.images,
        active_animation=0,
        time=0.1
    }))


    
    attack_obj,_ := sc.new_gameobject(e)
    attack_obj.transform.tag = "attackobj"
    sc.add_component(attack_obj, types.SquareCollider({size={50,-50}, trigger=true}))
    sc.add_child(enemy,attack_obj)

    sc.add_component(attack_obj, types.Script({
        data=ed.animator,
        on_trigger_entered = proc(me, other: types.GameObject, data: rawptr, event: types.Event_Collision_Entered) {
            if other.transform.tag == "player" {
                an := cast(^types.SpriteAnimator)data
                an.active_animation = 3

                dir := other.transform.pos.x - me.transform.pos.x;
                an.sprite_comp.inverted = dir < 0
                
            }
        },
        on_trigger_left = proc(me, other: types.GameObject, data: rawptr, event: types.Event_Collision_Entered) {
            if other.transform.tag == "player" {
                an := cast(^types.SpriteAnimator)data
                an.active_animation = 0

                dir := other.transform.pos.x - me.transform.pos.x;
                an.sprite_comp.inverted = dir < 0
                
            }
        },

    }))


    sc.add_component(enemy, types.Script({
        data=ed,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32 ) {
            ed := cast(^EnemyData)data
            for event in es.event_queue_poll(){
                #partial switch v in event  {
                    case types.Event_SpriteAnimator_End:
                    if v.animator == ed.animator && v.animator.active_animation == 1 {
                        ed.animator.time = 0.1
                        ed.animator.active_animation = 0
                    }
                    if v.animator == ed.animator && v.animator.active_animation == 2 {
                        coin := create_coin(go.ecs, go.transform.pos+{0,40})
                        rigid, _ := ecs.get_component(coin.ecs, coin.entity, types.RigidBody)
                        rigid.acceleration = {100,200}
                        ecs.destroy_entity(go.ecs, go.entity)
                    }

                    case types.Event_Trigger_Entered:
                    fmt.println("ENITY: ", v.ea, v.eb, go.entity)
                    trigger_go,_ := sc.get_gameobject(go.ecs, v.ea)
                    if v.eb == go.entity && trigger_go.transform.tag == "weapon" {
                        ed.animator.active_animation = 1
                        ed.animator.time = 0.05
                        ed.health = ed.health - 1
                        if ed.health <= 0 do ed.animator.active_animation = 2
                    }
                }
            }
        },
        on_destroy = proc(go: types.GameObject, data: rawptr) {
            free(data)
        }
    }))
}
