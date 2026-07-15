package ogamer_events;

import "../input/"


Event_MouseButton_Pressed :: struct {
    button: input.MouseButton,
}
Event_MouseButton_Released :: struct {
    button: input.MouseButton,
}
Event_Key_Pressed :: struct {
    key: input.KeyboardKey,
}
Event_Key_Released :: struct { // TODO add so it gets emited
    key: input.KeyboardKey,
}
Event_Collision_Entered :: struct {
    // ra: ^RigidBody,
    // rb: ^RigidBody,
    // ca: ^SquareCollider,
    // cb: ^SquareCollider,
    // ea: u32,
    // eb: u32,
}
Event_Collision_Left :: struct {
    using Event_Collision_Entered,
}
Event_Collision_Hit :: struct {
    using Event_Collision_Entered
}
Event_Trigger_Entered :: struct {
    using Event_Collision_Entered,
}
Event_Trigger_Left :: struct {
    using Event_Collision_Entered,
}
Event_Trigger_Hit :: struct {
    using Event_Collision_Entered,
}
Event_SpriteAnimator_End :: struct {
//    animator: ^SpriteAnimator
}
Event_Should_Close_Window :: struct {

}

// The union of all possible events
Event :: union {
    Event_Key_Pressed,
    Event_Key_Released,

    Event_MouseButton_Pressed,
    Event_MouseButton_Released,


    Event_Collision_Entered,
    Event_Collision_Left,
    Event_Collision_Hit,

    Event_Trigger_Entered,
    Event_Trigger_Left,
    Event_Trigger_Hit,
    

    Event_SpriteAnimator_End,
    Event_Should_Close_Window,
}
