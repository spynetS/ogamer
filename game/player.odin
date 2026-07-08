package main;
import b2 "vendor:box2d"
import "../src/types"
import sc "../src/scripting"
import "../src/io"
import "core:fmt"
import "../src/ecs"
import "../src/ecs/systems"
import rn "../src/renderer"
import "core:math/linalg"
import "core:math"

IDLE    :: 0
RUNNING :: 1
ATTACK  :: 2
ARROW   :: 4
PLAYER_SPEED :: 400


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
    health_bar    : types.GameObject,
}

ArrowData :: struct {
    explode : bool
}

create_ui :: proc(ecs: ^types.ECS, playerData: ^PlayerData) {
       // TODO add uisprite
    health_bar,_ := sc.new_gameobject(&game.ecs)
    health_bar.transform.size = {150,100}*2
    health_bar.transform.pos = {150,-100}
    health_bar_image,_ := io.load("./game/assets/Live Bar.png")
    sc.add_component(health_bar, types.UiSprite({image=health_bar_image})) 
    
    heart1,_ := sc.new_gameobject(&game.ecs)
    heart1.transform.local_size = {-75,-70}
    heart1.transform.local_pos = {-20,0}
    heart1_image := io.crop("./game/assets/Big Heart Idle (18x14).png", 0, 0, 18,14)
    sc.add_component(heart1, types.UiSprite({image=heart1_image})) 
    sc.add_child(health_bar,heart1)

    heart2,_ := sc.new_gameobject(&game.ecs)
    heart2.transform.local_size = {-75,-70}
    heart2.transform.local_pos = {-2,0}
    heart2_image := io.crop("./game/assets/Big Heart Idle (18x14).png", 0, 0, 18,14)
    sc.add_component(heart2, types.UiSprite({image=heart2_image})) 
    sc.add_child(health_bar,heart2)

    heart3,_ := sc.new_gameobject(&game.ecs)
    heart3.transform.local_size = {-75,-70}
    heart3.transform.local_pos = {15,0}
    heart3_image := io.crop("./game/assets/Big Heart Idle (18x14).png", 0, 0, 18,14)
    sc.add_component(heart3, types.UiSprite({image=heart3_image})) 
    sc.add_child(health_bar,heart3)

    playerData.health_bar = health_bar^;
}


create_arrow :: proc(e: ^types.ECS, pos, dir: types.Vector2, exploding:bool=false) {

    arrow, _ := sc.new_gameobject(e);
    arrow.transform.pos = pos
    arrow.transform.size = {70,70}
    arrow.transform.tag = "weapon"

    radians := math.atan2(dir.y, dir.x)
    degrees := radians * math.DEG_PER_RAD  // or: math.to_degrees(radians)
    arrow.transform.rot = degrees
    image,_ := io.load("./game/assets/sprites/Arrow(Projectile)/Arrow01(32x32).png")
    sc.add_component(arrow, types.SpriteRenderable({image=image}))
    rigid,_ := sc.add_component(arrow, types.RigidBody({type=types.BodyType.dynamicBody}))
    rigid.velocity = dir*1000
    sc.add_component(arrow, types.SquareCollider({trigger=true, size={0,-50}}))
    fmt.println("CREATED ARROW", arrow.entity)

    arrow_data := new(ArrowData)
    arrow_data.explode = exploding

    sc.add_component(arrow, types.Script({
        data = arrow_data,
        on_destroy = proc(go: types.GameObject, data:rawptr) {
            data := cast(^ArrowData)data;
            free(data)
        },
        on_trigger_entered = proc(me, other : types.GameObject, data:rawptr, event:types.Event_Collision_Entered) {
            data := cast(^ArrowData)data
            if data.explode == true {
                dir := linalg.normalize0(other.transform.pos-me.transform.pos)
                explotion,_ := sc.new_gameobject(&game.ecs)
                explotion.transform.pos = me.transform.pos+dir*50
                explotion.transform.size = {200,200}
                //tilesheet := io.new_tilesheet("./game/assets/explosion pack 1/Explosions pack/explosion-1-c/spritesheet.png", {1280/10,80})
                tilesheet := io.new_tilesheet("./game/assets/explosion pack 1/Explosions pack/explosion-1-g/spritesheet.png", {336/7,48})
                animator,_ := sc.add_component(explotion, types.SpriteAnimator({
                    sprites=tilesheet.images,
                    time=0.04
                }))
                fmt.println("CREATED EXPLOTION", explotion.entity)
                sc.add_component(explotion, types.Script({
                    data = animator,
                    on_event = proc(go: types.GameObject, data: rawptr, event: types.Event) {
                        animator := cast(^types.SpriteAnimator)data;
                        #partial switch v in event {
                            case types.Event_SpriteAnimator_End:
                            fmt.println("EVENT END", animator.active_animation, go.entity)
                            if v.animator == animator do ecs.destroy_entity(go.ecs, go.entity)
                        }
                    }
                }))

                sc.apply_force(event.rb, {700,700}*dir)
            }
           ecs.destroy_entity(me.ecs, me.entity)
        },
        
    }))

}


create_player :: proc (e: ^types.ECS) {
    player, _ := sc.new_gameobject(e);
    defer free(player)
    player.transform.size = {100,100}
    player.transform.tag = "player"

    camera,_ := sc.new_gameobject(e);
    camera.transform.local_pos = {0,150}
    sc.add_component(camera, types.Camera2D({zoom=1}));
    sc.add_child(player,camera)

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

    feet, _ := sc.new_gameobject(e);
    defer free(feet);
    feet.transform.local_pos = {0,-40}
    feet.transform.local_size = {-80,-80}
    feet_collider,_ := sc.add_component(feet, types.SquareCollider({trigger=true}))

    sc.add_child(player, feet);

    data := new(PlayerData)
    data.collider=collider
    data.health=2
    data.tool=tool^
    data.feet_collider = feet_collider
    data.rigid=rigid
    data.animator=animator

    create_ui(e, data);

    sc.add_component(player, types.Script({
        data=data,
        on_update = proc(go: types.GameObject, data: rawptr, dt: f32) {
            pd := cast(^PlayerData)data
            collider := pd.collider
            rigid := pd.rigid
            collider.disabled = true;
            pd.tool.transform.local_pos = {pd.animator.sprite_comp.inverted ? -60 : 60,0}
            if sc.is_key_down(types.KeyboardKey.D) && (pd.animator.active_animation != ATTACK && pd.animator.active_animation != ARROW) {
                if rigid.velocity.x < PLAYER_SPEED do sc.apply_force(rigid, {50,0})
                pd.animator.active_animation=RUNNING
                pd.animator.sprite_comp.inverted=false
            }
            else if sc.is_key_down(types.KeyboardKey.A) && (pd.animator.active_animation != ATTACK &&  pd.animator.active_animation != ARROW ){
                if rigid.velocity.x > -PLAYER_SPEED do sc.apply_force(rigid, {-50,0})
                pd.animator.active_animation=RUNNING
                pd.animator.sprite_comp.inverted=true
            }
            else {
                pd.animator.sprite_comp.inverted=rn.get_world_mouse_position().x - go.transform.pos.x < 0
            }
            if pd.animator.active_animation==ARROW && !sc.is_mouse_down(types.MouseButton.LEFT) {
                pd.animator.active_animation=IDLE
                
            }
            if sc.is_mouse_pressed(types.MouseButton.LEFT)  {
                pd.animator.time=0.05
                switch pd.tool_equiped{
                case 0:
                    pd.animator.active_animation=ATTACK
                    collider.disabled = false;
                case 1,2:
                    pd.animator.active_animation=ARROW
                }
                
            }

            if sc.is_key_pressed(types.KeyboardKey.ONE) do pd.tool_equiped = 0
            if sc.is_key_pressed(types.KeyboardKey.TWO) do pd.tool_equiped = 1
            if sc.is_key_pressed(types.KeyboardKey.THREE) do pd.tool_equiped = 2
            

            if sc.is_key_pressed(types.KeyboardKey.E) && pd.grounded {
                game.renderer.active_camera.zoom += 0.1
            }
            if sc.is_key_pressed(types.KeyboardKey.Q) && pd.grounded {
                game.renderer.active_camera.zoom -= 0.1
            }

            if sc.is_key_pressed(types.KeyboardKey.SPACE) && pd.grounded {
                sc.apply_force(pd.rigid, {0,2500});
            }
            if go.transform.pos.y < -300 {
                go.transform.pos = {0,0}
                game.should_run = false
            }
            // hearts := sc.get_child_components(&pd.health_bar, types.UiSprite)
            // for child in hearts {
            //     child.disabled = true
            // }
            // for i in 0..<math.min(pd.health,3) {
            //     hearts[i].disabled = false
            // }
        },
        on_collision_entered = proc(me: types.GameObject, other: types.GameObject, data:rawptr, event: types.Event_Collision_Entered) {
            if other.transform.tag == "COIN" {
                fmt.println("ME", me.entity, "hit coin", other.entity)

                ecs.destroy_entity(other.ecs, other.entity);
                (cast(^PlayerData)data).health += 1
            }

        }, 
        on_event = proc(go: types.GameObject, data:rawptr, event: types.Event) {
            pd := cast(^PlayerData)data
            #partial switch v in event {
                case types.Event_SpriteAnimator_End:
                if v.animator == pd.animator {
                    if pd.animator.active_animation == ARROW {
                        dir := linalg.normalize0(rn.get_world_mouse_position()-go.transform.pos)
                        create_arrow(go.ecs, go.transform.pos+dir*100, dir, pd.tool_equiped == 2);
                    }
                    pd.animator.time=0.1
                    pd.animator.active_animation = IDLE
                }
                case types.Event_Trigger_Entered:

                if v.ca == pd.feet_collider {
                    pd.grounded = true;
                }

                case types.Event_Trigger_Left:
                if v.ca == pd.feet_collider {
                    pd.grounded = false;

                }
            }

        },
        on_destroy = proc(go: types.GameObject, data:rawptr){
            pd := cast(^PlayerData)data
            free(pd)
        }
    }))
}
