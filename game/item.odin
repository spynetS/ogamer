package main;
import og "../src/ogamer"
import "../src/ogamer/io"
import "../src/ogamer/ecs"



Item :: struct {
    sprite: io.Sprite
}


create_item :: proc (game: ^og.Game, pos: [2]f32, item: Item) {
    item_obj := og.new_gameobject(game.ecs);
    item_obj.transform.pos = pos
//    item_obj.transform.size = {75,75}

    og.add_component(item_obj, ecs.NewSpriteRenderer(sprite=item.sprite))
    og.add_component(item_obj, ecs.NewRigidbody(disabled_gravity=true, type=ecs.BodyType.kinematicBody))
    
}
