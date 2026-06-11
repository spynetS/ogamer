package main;

import "core:fmt"
import "../src/core"

import rl "vendor:raylib"



main :: proc() {
    fmt.println("Hello World!");
    core.init_window();


    for !rl.WindowShouldClose() {
        rl.BeginDrawing();
        rl.EndDrawing();
    }
}
