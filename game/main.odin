package main;
import "../src/ogamer"
import "../src/ogamer/io"
import "../src/ogamer/ecs/components"


main :: proc() {
    game := ogamer.init_game();
    
    sprite := io.load(game.assetsManager, "../../Pictures/balin.png")
    
    ogamer.add_component(game.ecs, 0, components.NewTransform())
    ogamer.add_component(game.ecs, 0, components.NewSpriteRenderer(sprite=sprite))
    ogamer.start_game(game);
}


