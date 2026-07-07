package main;
import "../src/types"
import sc "../src/scripting"
import "../src/io"
import "core:fmt"
import "../src/ecs"
import rn "../src/renderer"
import "core:math/linalg"

PlayerData :: struct {
    collider      : ^types.SquareCollider,
    tool          : types.GameObject,
    feet_collider : ^types.SquareCollider,
    rigid         : ^types.RigidBody,
    animator      : ^types.SpriteAnimator,
    grounded      : bool,
    health        : int,
    health_text   : ^types.TextElement,
    tool_equiped  : int,
}

create_arrow :: proc(e: ^types.ECS, pos, dir: types.Vector2) {

    arrow, _ := sc.new_gameobject(e);
    arrow.transform.pos = pos
    arrow.transform.size = {70,70}
    arrow.transform.tag = "weapon"
    image,_ := io.load("./game/assets/sprites/Arrow(Projectile)/Arrow01(32x32).png")
    sc.add_component(arrow, types.SpriteRenderable({image=image}))
    rigid,_ := sc.add_component(arrow, types.RigidBody({type=types.BodyType.dynamicBody}))
    rigid.velocity = {1000,1000} * dir
    sc.add_component(arrow, types.SquareCollider({trigger=true}))
    sc.add_component(arrow, types.Script({
        on_trigger_entered = proc(me, other : types.GameObject, data:rawptr, event:types.Event) {
            ecs.destroy_entity(me.ecs, me.entity)
        },
    }))

}


create_player :: proc (e: ^types.ECS) {
    player, _ := sc.new_gameobject(e);
    defer free(player)
    player.transform.size = {100,100}

    sc.add_component(player, types.Camera2D({zoom=1}));

    idle := io.new_tilesheet("./game/assets/sprites/Characters(100x100 split)/Soldier/Soldier/Soldier.png", {100,100}, {0, 0});
    sprite_length := make([]int, 7)
    sprite_length[0] = 6
    sprite_length[1] = 8
    sprite_length[2] = 6
    sprite_length[3] = 6
    sprite_length[4] = 9
    sprite_length[5] = 4
    sprite_length[6] = 4

    sc.add_component(player,types.SpriteRenderable({size={300,300}, offset={0,-7}}))
    animator,_ := sc.add_component(player, types.SpriteAnimator({
        sprites=idle.images,
        sprites_length=sprite_length,
        active_animation=0,
        time=0.1
    }))


    sc.add_component(player, types.SquareCollider({size={-50,-30}}))
    rigid, _ := sc.add_component(player, types.RigidBody({type=types.BodyType.dynamicBody, disable_rotation=true}))

    tool, _ := sc.new_gameobject(e);
    defer free(tool);
    tool.transform.tag = "weapon"
    tool.transform.local_pos = {60,0}
    tool.transform.local_size = {-40,-40}
    collider, _ := sc.add_component(tool, types.SquareCollider({trigger=true}))

    sc.add_child(player, tool);

    text,_ := sc.new_gameobject(e);
    health_text,_ := sc.add_component(text, types.TextElement({text="COINS: 0"}))
    text.transform.pos = {100,100}

    feet, _ := sc.new_gameobject(e);
    defer free(feet);
    feet.transform.local_pos = {0,-40}
    feet.transform.local_size = {-80,-80}
    feet_collider,_ := sc.add_component(feet, types.SquareCollider({trigger=true}))

    sc.add_child(player, feet);

    data := new(PlayerData)
    data.health_text = health_text
    data.collider=collider
    data.tool=tool^
    data.feet_collider = feet_collider
    data.rigid=rigid
    data.animator=animator

    sc.add_component(player, types.Script({
        data=data,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32) {
            pd := cast(^PlayerData)data
            collider := pd.collider
            rigid := pd.rigid
            collider.disabled = true;
            pd.tool.transform.local_pos = {pd.animator.sprite_comp.inverted ? -60 : 60,0}
            if sc.is_key_down(types.KeyboardKey.D) && pd.animator.active_animation != 2 {
                sc.apply_force(rigid, {50,0})
                pd.animator.active_animation=1
                pd.animator.sprite_comp.inverted=false
            }
            else if sc.is_key_down(types.KeyboardKey.A) && pd.animator.active_animation != 2 {
                sc.apply_force(rigid, {-50,0})
                pd.animator.active_animation=1
                pd.animator.sprite_comp.inverted=true
            }
            else {
                pd.animator.sprite_comp.inverted=rn.get_world_mouse_position().x - go.transform.pos.x < 0
            }
            if sc.is_key_pressed(types.KeyboardKey.ENTER) && pd.animator.active_animation != 2 {
                pd.animator.time=0.05
                switch pd.tool_equiped{
                case 0:
                    pd.animator.active_animation=2
                    collider.disabled = false;
                case 1:
                    pd.animator.active_animation=4
                }
                
            }

            if sc.is_key_pressed(types.KeyboardKey.ONE) do pd.tool_equiped = 0
            if sc.is_key_pressed(types.KeyboardKey.TWO) do pd.tool_equiped = 1
            
            
            if sc.is_key_pressed(types.KeyboardKey.SPACE) && pd.grounded {
                sc.apply_force(pd.rigid, {0,2500});
            }
            if go.transform.pos.y < -300 {
                go.transform.pos = {0,0}
                game.should_run = false
            }
        },
        on_collision_entered = proc(me: types.GameObject, other: types.GameObject, data:rawptr, event: types.Event) {
            if other.transform.tag == "COIN" {
                fmt.println("ME", me.entity, "hit coin", other.entity)

                ecs.destroy_entity(other.ecs, other.entity);
                (cast(^PlayerData)data).health += 1
                (cast(^PlayerData)data).health_text.text = fmt.aprintf("COINS: %d", (cast(^PlayerData)data).health)
            }

        }, 
        on_event = proc(go: types.GameObject, data:rawptr, event: types.Event) {
            pd := cast(^PlayerData)data
            #partial switch v in event {
                case types.Event_SpriteAnimator_End:
                if v.animator == pd.animator {
                    if pd.animator.active_animation == 4 {
                        dir := linalg.normalize0(rn.get_world_mouse_position()-go.transform.pos)
                        create_arrow(go.ecs, go.transform.pos, dir);
                        
                    }
                    pd.animator.time=0.1
                    pd.animator.active_animation = 0
                }
                case types.Event_Trigger_Entered:

                if v.ca == pd.feet_collider {
                    pd.grounded = true;
                    pd.health_text.text = fmt.tprintf("Heath: %d, grounded %d", pd.health, pd.grounded ? 1 : 0);
                }

                case types.Event_Trigger_Left:
                if v.ca == pd.feet_collider {
                    pd.grounded = false;
                    pd.health_text.text = fmt.tprintf("Heath: %d, grounded %d", pd.health, pd.grounded ? 1 : 0);
                }
            }

        },
        on_destroy = proc(go: types.GameObject, data:rawptr){
            pd := cast(^PlayerData)data
            free(pd)
        }
    }))
}
