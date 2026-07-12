package main;
import "../src/types"
import "../src/ecs"
import sc "../src/scripting"
import "../src/io"
import "../src/ecs/systems"

import "core:fmt"
import "core:math/linalg"
import b2 "vendor:box2d"


BossState :: enum {
    IDLE,
    ATTACK,
    JUMPATTACK,
    JUMP,
    JUMPING,
    FALLING,
    HIT,
    HIT2,
    HIT3,
    HIT_GROUND,
}


BossData :: struct {
    player: types.GameObject,
    state: BossState,
    animator: ^types.SpriteAnimator,
    rigidbody: ^types.RigidBody,
    swing_attack: ^types.SquareCollider
}

get_attack :: proc(boss, player: types.GameObject) -> BossState {
    distance := linalg.distance(player.transform.pos, boss.transform.pos)
    fmt.println("DISTANCE IS ", distance)
    if distance > 200 do return .JUMPATTACK
    return .ATTACK
}

boss_sprite_animator_end ::  proc(go: types.GameObject, data: rawptr, event:types.Event_SpriteAnimator_End) {
    bd := cast(^BossData)data
    #partial switch bd.state {
    case .ATTACK: bd.state = BossState.IDLE
    case .HIT: bd.state = .HIT2
    case .HIT2: bd.state = .HIT3
    case .HIT3: bd.state = get_attack(go, bd.player)
    case .HIT_GROUND: bd.state = .IDLE

    }
}

boss_on_collision_entered ::  proc(go, other: types.GameObject, data: rawptr, event:types.Event_Collision_Entered) {
    bd := cast(^BossData)data
    fmt.println("ENTERED COLLITION")
    #partial switch bd.state {
        case .FALLING: bd.state = .HIT_GROUND
      
    }
}

boss_on_trigger_entered ::  proc(go, other: types.GameObject, data: rawptr, event:types.Event_Collision_Entered) {
    bd := cast(^BossData)data
    game.should_run = true
    if other.transform.tag == "weapon" && bd.state == .IDLE{
        bd.state = .HIT
    }
}


boss_script :: proc (go: types.GameObject, data: rawptr, dt: f32) {
    bd := cast(^BossData)data;
    dir := linalg.normalize0(bd.player.transform.pos - go.transform.pos)
    sprite,_ := ecs.get_component(go.ecs, go.entity, types.SpriteRenderable)
    sprite.inverted = dir.x > 0
    
    bd.swing_attack.disabled = true
    #partial switch bd.state {
        case .HIT, .HIT2, .HIT3:
        bd.animator.active_animation = 4
        case .IDLE:
        bd.animator.active_animation = 0
        case .ATTACK:
        bd.animator.active_animation = 1
        bd.swing_attack.size = {-100,-100}
        bd.swing_attack.disabled = false
        case .JUMPATTACK:
        sc.apply_force(bd.rigidbody, {4000*dir.x,10000}*2)
        bd.animator.active_animation = 2
        bd.state = BossState.JUMPING

        case .JUMP:
        sc.apply_force(bd.rigidbody, {0,10000})
        bd.animator.active_animation = 2
        bd.state = BossState.JUMPING

        case .JUMPING:
        body_id := systems.body_id_by_rigidbody[bd.rigidbody]
        vel := b2.Body_GetLinearVelocity(body_id)
        if vel.y <= 0 {
            bd.state = .FALLING
        }
        case .HIT_GROUND:
        bd.swing_attack.disabled = false
        bd.swing_attack.size = {100,100}
        bd.animator.active_animation = 3

        case .FALLING:
        bd.animator.active_animation = 3
    }
}



create_boss :: proc(ecs: ^types.ECS) {
    tilesheet := io.new_tilesheet("./game/assets/02-King Pig/Idle (38x28).png", {38,28})
    io.merge_tilesheet(tilesheet, io.new_tilesheet("./game/assets/02-King Pig/Attack (38x28).png", {38,28}))
    io.merge_tilesheet(tilesheet, io.new_tilesheet("./game/assets/02-King Pig/Jump (38x28).png", {38,28}))
    io.merge_tilesheet(tilesheet, io.new_tilesheet("./game/assets/02-King Pig/Fall (38x28).png", {38,28}))
    io.merge_tilesheet(tilesheet, io.new_tilesheet("./game/assets/02-King Pig/Hit (38x28).png", {38,28}))
    io.merge_tilesheet(tilesheet, io.new_tilesheet("./game/assets/02-King Pig/Run (38x28).png", {38,28}))
    
    boss,_ := sc.new_gameobject(ecs);
    boss.transform.pos = {200,-200}
    boss.transform.size = {280,280}
    boss.transform.tag = "enemy"

    rigidbody,_ := sc.add_component(boss, types.RigidBody({type = types.BodyType.dynamicBody, disable_rotation=true}))
    sc.add_component(boss, types.SquareCollider({size={-200,-100}}))
    sc.add_component(boss, types.SpriteRenderable({offset={0,50}}))
    animator,_ := sc.add_component(boss, types.SpriteAnimator({
        sprites = tilesheet.images,
        time=0.1
    }))
    systems.create_body(ecs, boss.entity)
    body_id,_ := systems.body_id_by_rigidbody[rigidbody]
    mass_data := b2.MassData{
        mass = 10.0,
        center = {0, 0},
        rotationalInertia = 5.0, // Must be provided!
    }

    b2.Body_SetMassData(body_id, mass_data)

    swing_attack_obj,_ := sc.new_gameobject(ecs);
    swing_attack_obj.transform.local_size = {10,-30}
    swing_attack_obj.transform.tag = "attackobj"
    swing_col,_ := sc.add_component(swing_attack_obj, types.SquareCollider({trigger=true}))
    sc.add_child(boss,swing_attack_obj)
    
    
    data := new(BossData)
    data.animator = animator
    data.rigidbody = rigidbody
    data.state = BossState.IDLE
    data.swing_attack = swing_col
    if player,found := sc.get_gameobject(ecs, "player"); found do data.player = player^

    sc.add_component(boss, types.Script({
        data = data,
        on_update=boss_script,
        on_sprite_animator_end = boss_sprite_animator_end,
        on_collision_entered = boss_on_collision_entered,
        on_trigger_entered = boss_on_trigger_entered,
    }))
}
