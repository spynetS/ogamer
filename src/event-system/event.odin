package event;
import "core:fmt"
import "../ecs/types"

Event_Key_Pressed :: struct {
    key: types.KeyboardKey,
}
Event_Key_Released :: struct { // TODO add so it gets emited
    key: types.KeyboardKey,
}
Event_Collision_Entered :: struct {
    ra: ^types.RigidBody,
    rb: ^types.RigidBody,
    ca: ^types.SquareCollider,
    cb: ^types.SquareCollider,
    ea: u32,
    eb: u32,
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
    animator: ^types.SpriteAnimator
}
Event_Should_Close_Window :: struct {

}

// The union of all possible events
Event :: union {
    Event_Key_Pressed,
    Event_Key_Released,

    Event_Collision_Entered,
    Event_Collision_Left,
    Event_Collision_Hit,

    Event_Trigger_Entered,
    Event_Trigger_Left,
    Event_Trigger_Hit,
    

    Event_SpriteAnimator_End,
    Event_Should_Close_Window,
}

next_events    : [dynamic]Event
current_events : [dynamic]Event


event_queue_init :: proc() {
    next_events    = make([dynamic]Event, 0, 64)
    current_events = make([dynamic]Event, 0, 64)
}

event_queue_destroy :: proc() {
    delete(next_events)
    delete(current_events)
}

emit :: proc(e: Event) {
    fmt.println("INFO: New Event", e)
    append(&next_events, e)
}

event_queue_clear :: proc() {
    current_events, next_events = next_events, current_events
    clear(&next_events)
}

event_queue_poll :: proc() -> [dynamic]Event {
    return current_events
}
