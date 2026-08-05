package ogamer_events;


Entity :: u32


EventQueue :: struct {
    next_events    : [dynamic]Event,
    current_events : [dynamic]Event
}

MouseButton_Pressed :: struct {
    button: i32,
}
MouseButton_Released :: struct {
    button: i32,
}
Key_Pressed :: struct {
    key: i32,
}
Key_Released :: struct { // TODO add so it gets emited
    key: i32,
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
MouseEnteredEntity :: struct {
    entity: Entity
}
MouseLeftEntity :: struct {
    entity: Entity
}
// Then an entity has been hit by a raycast
// this event will be triggered
RaycastHit :: struct {
    entity: Entity
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

    MouseEnteredEntity,
    MouseLeftEntity,
    
    RaycastHit,

    AnimationFinished,
    Should_Close_Window,
}
