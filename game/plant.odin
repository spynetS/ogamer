package main

import og "../src/ogamer/"
import "../src/ogamer/io"
import "../src/ogamer/ecs"

PlantData :: struct {
    current_age : f32,
    max_age     : f32,
    sprites     : []io.Sprite,
    sprite_comp : ^ecs.SpriteRenderer,
}

create_plant :: proc(game: ^og.Game, pos: [2]f32) {

    fields := ecs.get_gameobjects_tag(game.ecs, "field")
    found := false
    for field in fields {
        if field.transform.pos == pos do found =true
    }
    if !found do return
    
    plants := ecs.get_gameobjects_tag(game.ecs, "plant")
    found = false
    for plant in plants {
        if plant.transform.pos == pos do found =true
    }
    if found do return


    plant := og.new_gameobject(game.ecs)
    plant.transform.pos = pos

    tilesheet := io.new_tilesheet(game.assetsManager, "./game/assets/farm/objects&items/plants free.png", {16,16})

    pdata := new(PlantData)
    pdata.current_age = 0
    pdata.max_age = 4
    pdata.sprites=tilesheet.sprites[0]
    og.add_component(plant, ecs.Tag({tag="plant"}))


    pdata.sprite_comp = og.add_component(plant, ecs.NewSpriteRenderer(sprite=pdata.sprites[0]))
    og.add_component(plant, ecs.NewScriptComponent(ecs.NewScript(data=pdata, update=plant_script)))
}

kill_plant :: proc (data: ecs.ScriptData) {
    ecs.destroy_entity(data.gameObject.ecs, data.gameObject.entity)
}

plant_script :: proc (data: ecs.ScriptData) {
    pdata := cast(^PlantData)data.data
    if int(pdata.current_age) < len(pdata.sprites){
        pdata.sprite_comp.sprite = pdata.sprites[int(pdata.current_age)]
        pdata.current_age += data.dt
    }
    else {
        tilesheet := io.new_tilesheet(game.assetsManager, "./game/assets/farm/objects&items/items free.png", {16,16})
        create_item(game, data.gameObject.transform.pos, Item({sprite=tilesheet.sprites[0][0]}))
        kill_plant(data)

    }

}
