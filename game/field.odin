package main;
import og "../src/ogamer"
import "../src/ogamer/ecs"
import "../src/ogamer/io"

import "core:fmt"

Field :: struct {
    w, h: int // tile size
}

create_part :: proc(game: ^og.Game) {
    
}

create_field :: proc (game: ^og.Game, pos: [2]f32) {

    fields := ecs.get_gameobjects_tag(game.ecs, "field")
    found := false
    for field in fields {
        if field.transform.pos == pos do found = true
    }
    if found do return
    fmt.println("ADDED FIELD")

    field := og.new_gameobject(game.ecs);
    field.transform.pos = pos


    fdata := new(Field)
    fdata.w = 1
    fdata.h = 1

    tilesheet := io.new_tilesheet(game.assetsManager, "./game/assets/farm/tilemaps/spring farm tilemap.png", {16,16})

    og.add_component(field, ecs.Tag({tag="field"}))
    og.add_component(field, ecs.NewSpriteRenderer(sprite=tilesheet.sprites[12][6], layer=-1))


}

field_script :: proc(data: ecs.ScriptData) {
    fdata := cast(^Field)data.data
    
}
