package main
import og "../src/ogamer"
import "../src/ogamer/ecs"
import "../src/ogamer/input"
import "../src/ogamer/renderer"
import "../src/ogamer/io"
import "core:math"

SPEED :: 3

PlayerState :: enum {
    IDLE,
    WALKING_RIGHT,
    WALKING_LEFT,
    WALKING_UP,
    WALKING_DOWN,
}

PlayerData :: struct {
    state:PlayerState,
    animator: ^ecs.SpriteAnimator,
    
}


create_player :: proc (game: ^og.Game) {
    player := og.new_gameobject(game.ecs);
    player.transform.size = {150,150}

    // og.add_component(player, ecs.NewRigidbody(type=ecs.BodyType.kinematicBody))
    // og.add_component(player, ecs.NewCollider(trigger=true))
    


    pData := new(PlayerData)
    
    og.add_component(player, ecs.NewCamera(zoom=0.7))
    leng := make([]int,3)
    leng[0] = 2
    leng[1] = 8
    leng[2] = 8
    pData.animator =  og.add_component(player, ecs.NewSpriteAnimator(
        sprites_length=leng,
        sprites=io.new_tilesheet(game.assetsManager, "./game/assets/farm/characters/main character/walk and idle.png", {24,24}).sprites))

    og.add_component(player, ecs.NewScriptComponent(ecs.NewScript(
        data = pData,
        update=proc(data: ecs.ScriptData) {
            pdata := cast(^PlayerData)data.data
            hanlde_animation(pdata)
            // reset walking ilde
            if pdata.state == .WALKING_RIGHT ||
                pdata.state == .WALKING_LEFT ||
                pdata.state == .WALKING_UP ||
                pdata.state == .WALKING_DOWN
            {pdata.state = .IDLE}
            
            if og.is_key_down(input.KeyboardKey.A) {
                pdata.state = .WALKING_LEFT
                data.gameObject.transform.pos.x -= SPEED
            }
            if og.is_key_down(input.KeyboardKey.D) {
                pdata.state = .WALKING_RIGHT
                data.gameObject.transform.pos.x += SPEED
            }
            if og.is_key_down(input.KeyboardKey.W) {
                pdata.state = .WALKING_UP
                data.gameObject.transform.pos.y += SPEED
            }
            if og.is_key_down(input.KeyboardKey.S) {
                pdata.state = .WALKING_DOWN
                data.gameObject.transform.pos.y -= SPEED
            }
  
            gs :f32= 100
            wp := input.get_world_mouse_position()
            wp = {
                math.round_f32((wp.x - gs/2) / gs) * gs + gs / 2,
                math.round_f32((wp.y - gs/2) / gs) * gs + gs / 2
            }

            
            sprite := io.load(game.assetsManager, "./game/assets/tileselector.png")
            renderer.add_command(game.renderer, renderer.Sprite({
                pos= wp,
                size={100,100},
                rot=0,
                sprite=sprite
            }))

            if og.is_mouse_down(input.MouseButton.LEFT) {
                create_plant(game,wp)

            }
            if og.is_mouse_down(input.MouseButton.RIGHT) {
                create_field(game,wp)

            }

        })))
}

hanlde_animation :: proc(pData: ^PlayerData) {
    #partial switch (pData.state) {
        case .IDLE:
        pData.animator.active_animation = 0
        pData.animator.time = 0.2
        case .WALKING_RIGHT:
        pData.animator.active_animation = 1
        pData.animator.time = 0.1
        pData.animator.sprite_comp.inverted = true
        case .WALKING_LEFT:
        pData.animator.active_animation = 1
        pData.animator.time = 0.1
        pData.animator.sprite_comp.inverted = false
        case .WALKING_UP, .WALKING_DOWN:
        pData.animator.active_animation = 1
        pData.animator.time = 0.1

    }
    
}
