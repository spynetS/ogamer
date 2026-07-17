package ogamer_events;

import "../input/"

Entity :: u32


EventQueue :: struct {
    next_events    : [dynamic]Event,
    current_events : [dynamic]Event
}

MouseButton_Pressed :: struct {
    button: input.MouseButton,
}
MouseButton_Released :: struct {
    button: input.MouseButton,
}
Key_Pressed :: struct {
    key: input.KeyboardKey,
}
Key_Released :: struct { // TODO add so it gets emited
    key: input.KeyboardKey,
}
Collision_Entered :: struct {
    // ra: ^RigidBody,
    // rb: ^RigidBody,
    // ca: ^SquareCollider,
    // cb: ^SquareCollider,
    ea: u32,
    eb: u32,
}
Collision_Left :: struct {
    using Collision_Entered,
}
Collision_Hit :: struct {
    using Collision_Entered
}
Trigger_Entered :: struct {
    using Collision_Entered,
}
Trigger_Left :: struct {
    using Collision_Entered,
}
Trigger_Hit :: struct {
    using Collision_Entered,
}
AnimationFinished :: struct {
    entity: Entity
}
Should_Close_Window :: struct {

}

// The union of all possible events
Event :: union {
    Key_Pressed,
    Key_Released,

    MouseButton_Pressed,
    MouseButton_Released,

    Collision_Entered,
    Collision_Left,
    Collision_Hit,

    Trigger_Entered,
    Trigger_Left,
    Trigger_Hit,
    

    AnimationFinished,
    Should_Close_Window,
}
